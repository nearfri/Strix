
import XCTest
@testable import Strix

private enum DummyError: Error {
    case err0
    case err1
    case err2
    case err3
}

class PrimitivesAlternativeTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func test_alternative_whenLeftSuccess_returnLeft() {
        let p1 = Parser { _ in return .success(1, []) }
        let p2 = Parser { _ in return .success(2, []) }
        let p = p1 <|> p2
        let reply = p.parse(CharacterStream(string: ""))
        XCTAssertEqual(reply.value, 1)
    }
    
    func test_alternative_whenLeftFailureRightSuccess_returnRight() {
        let p1 = Parser<Int> { _ in return .failure([DummyError.err0]) }
        let p2 = Parser { _ in return .success(2, [DummyError.err1]) }
        let p = p1 <|> p2
        let reply = p.parse(CharacterStream(string: ""))
        XCTAssertEqual(reply.value, 2)
        XCTAssertEqual(reply.errors as! [DummyError], [DummyError.err0, DummyError.err1])
    }
    
    func test_alternative_whenBothFailure_returnBothError() {
        let p1 = Parser<Int> { _ in return .failure([DummyError.err0]) }
        let p2 = Parser<Int> { _ in return .failure([DummyError.err1]) }
        let p = p1 <|> p2
        let reply = p.parse(CharacterStream(string: ""))
        var passed = false
        if case let .failure(e) = reply {
            XCTAssertEqual(e as! [DummyError], [DummyError.err0, DummyError.err1])
            passed = true
        }
        XCTAssertTrue(passed)
    }
    
    func test_alternative_whenBothFailureWithStateTagChange_returnOneError() {
        let p1 = Parser<Int> { _ in return .failure([DummyError.err0]) }
        let p2 = Parser<Int> { (stream) in
            stream.stateTag += 1
            return .failure([DummyError.err1])
        }
        let p = p1 <|> p2
        let reply = p.parse(CharacterStream(string: ""))
        var passed = false
        if case let .failure(e) = reply {
            XCTAssertEqual(e as! [DummyError], [DummyError.err1])
            passed = true
        }
        XCTAssertTrue(passed)
    }
    
    func test_alternative_whenLeftFatalFailure_returnFatalFailure() {
        let p1 = Parser<Int> { _ in return .fatalFailure([DummyError.err0]) }
        let p2 = Parser<Int> { _ in
            XCTFail()
            return .success(2, [DummyError.err1])
        }
        let p = p1 <|> p2
        let reply = p.parse(CharacterStream(string: ""))
        var passed = false
        if case let .fatalFailure(e) = reply {
            XCTAssertEqual(e as! [DummyError], [DummyError.err0])
            passed = true
        }
        XCTAssertTrue(passed)
    }
    
    func test_alternative_whenLeftFailureWithStateTagChange_returnFailure() {
        let p1 = Parser<Int> { (stream) in
            stream.stateTag += 1
            return .failure([DummyError.err0])
        }
        let p2 = Parser<Int> { _ in
            XCTFail()
            return .success(2, [DummyError.err1])
        }
        let p = p1 <|> p2
        let reply = p.parse(CharacterStream(string: ""))
        var passed = false
        if case let .failure(e) = reply {
            XCTAssertEqual(e as! [DummyError], [DummyError.err0])
            passed = true
        }
        XCTAssertTrue(passed)
    }
    
    func test_choice_success() {
        let p1 = Parser<Int> { _ in return .failure([DummyError.err0]) }
        let p2 = Parser<Int> { _ in return .failure([DummyError.err1]) }
        let p3 = Parser<Int> { _ in return .failure([DummyError.err2]) }
        let p4 = Parser<Int> { _ in return .success(4, []) }
        let p = choice([p1, p2, p3, p4])
        let reply = p.parse(CharacterStream(string: ""))
        XCTAssertEqual(reply.value, 4)
    }
    
    func test_choice_whenFatalFailure_returnFatalFailure() {
        let p1 = Parser<Int> { _ in return .failure([DummyError.err0]) }
        let p2 = Parser<Int> { _ in return .fatalFailure([DummyError.err1]) }
        let p3 = Parser<Int> { _ in return .failure([DummyError.err2]) }
        let p4 = Parser<Int> { _ in return .success(4, []) }
        let p = choice([p1, p2, p3, p4])
        let reply = p.parse(CharacterStream(string: ""))
        var passed = false
        if case let .fatalFailure(e) = reply {
            XCTAssertEqual(e as! [DummyError], [DummyError.err0, DummyError.err1])
            passed = true
        }
        XCTAssertTrue(passed)
    }
    
    func test_choice_whenFailureWithStateTagChange_returnFailure() {
        let p1 = Parser<Int> { _ in return .failure([DummyError.err0]) }
        let p2 = Parser<Int> { (stream) in
            stream.stateTag += 1
            return .failure([DummyError.err1])
        }
        let p3 = Parser<Int> { _ in return .failure([DummyError.err2]) }
        let p4 = Parser<Int> { _ in return .success(4, []) }
        let p = choice([p1, p2, p3, p4])
        let reply = p.parse(CharacterStream(string: ""))
        var passed = false
        if case let .failure(e) = reply {
            XCTAssertEqual(e as! [DummyError], [DummyError.err1])
            passed = true
        }
        XCTAssertTrue(passed)
    }
    
    func test_optional_success() {
        let p1 = Parser<Int> { _ in return .success(1, []) }
        let p = optional(p1)
        let reply = p.parse(CharacterStream(string: ""))
        var passed = false
        if case let .success(v, _) = reply {
            XCTAssertEqual(v, 1)
            passed = true
        }
        XCTAssertTrue(passed)
    }
    
    func test_optional_whenFailureWithoutStateTageChange_returnSuccess() {
        let p1 = Parser<Int> { _ in return .failure([DummyError.err0]) }
        let p = optional(p1)
        let reply = p.parse(CharacterStream(string: ""))
        var passed = false
        if case let .success(v, _) = reply {
            XCTAssertNil(v)
            passed = true
        }
        XCTAssertTrue(passed)
    }
    
    func test_optional_whenFailureWithStateTageChange_returnFailure() {
        let p1 = Parser<Int> { (stream) in
            stream.stateTag += 1
            return .failure([DummyError.err0])
        }
        let p = optional(p1)
        let reply = p.parse(CharacterStream(string: ""))
        var passed = false
        if case let .failure(e) = reply {
            XCTAssertEqual(e as! [DummyError], [DummyError.err0])
            passed = true
        }
        XCTAssertTrue(passed)
    }
    
    func test_optional_whenFatalFailure_returnFatalFailure() {
        let p1 = Parser<Int> { _ in return .fatalFailure([DummyError.err0]) }
        let p = optional(p1)
        let reply = p.parse(CharacterStream(string: ""))
        var passed = false
        if case let .fatalFailure(e) = reply {
            XCTAssertEqual(e as! [DummyError], [DummyError.err0])
            passed = true
        }
        XCTAssertTrue(passed)
    }
}



