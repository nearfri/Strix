
import XCTest
@testable import Strix

class PrimitivesLookAheadTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func test_NotEmpty_whenSuccessWithStateChange_returnSuccess() {
        let p1 = Parser<Int> { (stream) in
            stream.stateTag += 1
            return .success(1, [DummyError.err0])
        }
        let p: Parser<Int> = notEmpty(p1)
        let reply = p.parse(CharacterStream(string: ""))
        var passed = false
        if case let .success(v, e) = reply {
            XCTAssertEqual(v, 1)
            XCTAssertEqual(e as! [DummyError], [DummyError.err0])
            passed = true
        }
        XCTAssertTrue(passed)
    }
    
    func test_NotEmpty_whenSuccessWithoutStateChange_returnFailure() {
        let p1 = Parser<Int> { (stream) in
            return .success(1, [DummyError.err0])
        }
        let p: Parser<Int> = notEmpty(p1)
        let reply = p.parse(CharacterStream(string: ""))
        var passed = false
        if case let .failure(e) = reply {
            XCTAssertEqual(e as! [DummyError], [DummyError.err0])
            passed = true
        }
        XCTAssertTrue(passed)
    }
    
    func test_followed_whenSuccess_backtrackAndReturnSuccess() {
        let p1 = Parser<Int> { (stream) in
            stream.stateTag += 10
            return .success(1, [DummyError.err0])
        }
        let p: Parser<Void> = followed(by: p1, errorLabel: "one")
        let stream = CharacterStream(string: "")
        let stateTag = stream.stateTag
        let reply = p.parse(stream)
        XCTAssertEqual(stream.stateTag, stateTag)
        var passed = false
        if case let .success(_, e) = reply {
            XCTAssertTrue(e.isEmpty)
            passed = true
        }
        XCTAssertTrue(passed)
    }
    
    func test_followed_whenFailureWithLabel_backtrackAndReturnFailure() {
        let p1 = Parser<Int> { (stream) in
            stream.stateTag += 10
            return .failure([DummyError.err0])
        }
        let p: Parser<Void> = followed(by: p1, errorLabel: "one")
        let stream = CharacterStream(string: "")
        let stateTag = stream.stateTag
        let reply = p.parse(stream)
        XCTAssertEqual(stream.stateTag, stateTag)
        var passed = false
        if case let .failure(e) = reply {
            XCTAssertEqual(e as! [ParseError.Expected], [ParseError.Expected("one")])
            passed = true
        }
        XCTAssertTrue(passed)
    }
    
    func test_followed_whenFailureWithoutLabel_backtrackAndReturnFailure() {
        let p1 = Parser<Int> { (stream) in
            stream.stateTag += 10
            return .failure([DummyError.err0])
        }
        let p: Parser<Void> = followed(by: p1)
        let stream = CharacterStream(string: "")
        let stateTag = stream.stateTag
        let reply = p.parse(stream)
        XCTAssertEqual(stream.stateTag, stateTag)
        var passed = false
        if case let .failure(e) = reply {
            XCTAssertTrue(e.isEmpty)
            passed = true
        }
        XCTAssertTrue(passed)
    }
    
    func test_notFollowed_whenSuccessWithLabel_backtrackAndReturnFailure() {
        let p1 = Parser<Int> { (stream) in
            stream.stateTag += 10
            return .success(1, [DummyError.err0])
        }
        let p: Parser<Void> = notFollowed(by: p1, errorLabel: "one")
        let stream = CharacterStream(string: "")
        let stateTag = stream.stateTag
        let reply = p.parse(stream)
        XCTAssertEqual(stream.stateTag, stateTag)
        var passed = false
        if case let .failure(e) = reply {
            XCTAssertEqual(e as! [ParseError.Unexpected], [ParseError.Unexpected("one")])
            passed = true
        }
        XCTAssertTrue(passed)
    }
    
    func test_notFollowed_whenSuccessWithoutLabel_backtrackAndReturnFailure() {
        let p1 = Parser<Int> { (stream) in
            stream.stateTag += 10
            return .success(1, [DummyError.err0])
        }
        let p: Parser<Void> = notFollowed(by: p1)
        let stream = CharacterStream(string: "")
        let stateTag = stream.stateTag
        let reply = p.parse(stream)
        XCTAssertEqual(stream.stateTag, stateTag)
        var passed = false
        if case let .failure(e) = reply {
            XCTAssertTrue(e.isEmpty)
            passed = true
        }
        XCTAssertTrue(passed)
    }
    
    func test_notFollowed_whenFailure_backtrackAndReturnSuccess() {
        let p1 = Parser<Int> { (stream) in
            stream.stateTag += 10
            return .failure([DummyError.err0])
        }
        let p: Parser<Void> = notFollowed(by: p1, errorLabel: "one")
        let stream = CharacterStream(string: "")
        let stateTag = stream.stateTag
        let reply = p.parse(stream)
        XCTAssertEqual(stream.stateTag, stateTag)
        var passed = false
        if case let .success(_, e) = reply {
            XCTAssertTrue(e.isEmpty)
            passed = true
        }
        XCTAssertTrue(passed)
    }
    
    func test_lookAhead_whenSuccess_backtrackAndReturnSuccess() {
        let p1 = Parser<Int> { (stream) in
            stream.stateTag += 10
            return .success(1, [DummyError.err0])
        }
        let p: Parser<Int> = lookAhead(p1)
        let stream = CharacterStream(string: "")
        let stateTag = stream.stateTag
        let reply = p.parse(stream)
        XCTAssertEqual(stream.stateTag, stateTag)
        var passed = false
        if case let .success(v, e) = reply {
            XCTAssertEqual(v, 1)
            XCTAssertTrue(e.isEmpty)
            passed = true
        }
        XCTAssertTrue(passed)
    }
    
    func test_lookAhead_whenFailure_backtrackAndReturnFailure() {
        let p1 = Parser<Int> { (stream) in
            stream.stateTag += 10
            return .failure([DummyError.err0])
        }
        let p: Parser<Int> = lookAhead(p1)
        let stream = CharacterStream(string: "")
        let stateTag = stream.stateTag
        let reply = p.parse(stream)
        XCTAssertEqual(stream.stateTag, stateTag)
        var passed = false
        if case let .failure(e) = reply {
            if let nestedError = e.first as? ParseError.Nested {
                XCTAssertEqual(nestedError.errors as! [DummyError], [DummyError.err0])
                passed = true
            }
        }
        XCTAssertTrue(passed)
    }
    
    func test_lookAhead_whenFatalFailure_backtrackAndReturnFailure() {
        let p1 = Parser<Int> { (stream) in
            stream.stateTag += 10
            return .fatalFailure([DummyError.err0])
        }
        let p: Parser<Int> = lookAhead(p1)
        let stream = CharacterStream(string: "")
        let stateTag = stream.stateTag
        let reply = p.parse(stream)
        XCTAssertEqual(stream.stateTag, stateTag)
        var passed = false
        if case let .failure(e) = reply {
            if let nestedError = e.first as? ParseError.Nested {
                XCTAssertEqual(nestedError.errors as! [DummyError], [DummyError.err0])
                passed = true
            }
        }
        XCTAssertTrue(passed)
    }
    
    func test_lookAhead_whenFailureWithoutStateChange_returnFailureWithOriginalErrors() {
        let p1 = Parser<Int> { (stream) in
            return .failure([DummyError.err0])
        }
        let p: Parser<Int> = lookAhead(p1)
        let stream = CharacterStream(string: "")
        let stateTag = stream.stateTag
        let reply = p.parse(stream)
        XCTAssertEqual(stream.stateTag, stateTag)
        var passed = false
        if case let .failure(e) = reply {
            XCTAssertEqual(e as! [DummyError], [DummyError.err0])
            passed = true
        }
        XCTAssertTrue(passed)
    }
}



