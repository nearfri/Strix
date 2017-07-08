
import XCTest
@testable import Strix

class PrimitivesAlternativeTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func test_alternative_whenLeftSuccess_returnLeft() {
        let p1 = Parser<Int> { _ in return .success(1, []) }
        let p2 = Parser<Int> { _ in
            XCTFail()
            return .success(2, [])
        }
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
        if case let .failure(e) = reply {
            XCTAssertEqual(e as! [DummyError], [DummyError.err0, DummyError.err1])
        } else {
            XCTFail()
        }
    }
    
    func test_alternative_whenBothFailureWithStateChange_returnOneError() {
        let p1 = Parser<Int> { _ in return .failure([DummyError.err0]) }
        let p2 = Parser<Int> { (stream) in
            stream.stateTag += 1
            return .failure([DummyError.err1])
        }
        let p = p1 <|> p2
        let reply = p.parse(CharacterStream(string: ""))
        if case let .failure(e) = reply {
            XCTAssertEqual(e as! [DummyError], [DummyError.err1])
        } else {
            XCTFail()
        }
    }
    
    func test_alternative_whenLeftFatalFailure_returnFatalFailure() {
        let p1 = Parser<Int> { _ in return .fatalFailure([DummyError.err0]) }
        let p2 = Parser<Int> { _ in
            XCTFail()
            return .success(2, [DummyError.err1])
        }
        let p = p1 <|> p2
        let reply = p.parse(CharacterStream(string: ""))
        if case let .fatalFailure(e) = reply {
            XCTAssertEqual(e as! [DummyError], [DummyError.err0])
        } else {
            XCTFail()
        }
    }
    
    func test_alternative_whenLeftFailureWithStateChange_returnFailure() {
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
        if case let .failure(e) = reply {
            XCTAssertEqual(e as! [DummyError], [DummyError.err0])
        } else {
            XCTFail()
        }
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
        let p3 = Parser<Int> { _ in
            XCTFail()
            return .failure([DummyError.err2])
        }
        let p4 = Parser<Int> { _ in
            XCTFail()
            return .success(4, [])
        }
        let p = choice([p1, p2, p3, p4])
        let reply = p.parse(CharacterStream(string: ""))
        if case let .fatalFailure(e) = reply {
            XCTAssertEqual(e as! [DummyError], [DummyError.err0, DummyError.err1])
        } else {
            XCTFail()
        }
    }
    
    func test_choice_whenFailureWithStateChange_returnFailure() {
        let p1 = Parser<Int> { _ in return .failure([DummyError.err0]) }
        let p2 = Parser<Int> { (stream) in
            stream.stateTag += 1
            return .failure([DummyError.err1])
        }
        let p3 = Parser<Int> { _ in
            XCTFail()
            return .failure([DummyError.err2])
        }
        let p4 = Parser<Int> { _ in
            XCTFail()
            return .success(4, [])
        }
        let p = choice([p1, p2, p3, p4])
        let reply = p.parse(CharacterStream(string: ""))
        if case let .failure(e) = reply {
            XCTAssertEqual(e as! [DummyError], [DummyError.err1])
        } else {
            XCTFail()
        }
    }
    
    func test_optional_success() {
        let p1 = Parser<Int> { _ in return .success(1, []) }
        let p: Parser<Int?> = optional(p1)
        let reply = p.parse(CharacterStream(string: ""))
        if case let .success(v, _) = reply {
            XCTAssertEqual(v, 1)
        } else {
            XCTFail()
        }
    }
    
    func test_optional_whenFailureWithoutStateChange_returnSuccess() {
        let p1 = Parser<Int> { _ in return .failure([DummyError.err0]) }
        let p: Parser<Int?> = optional(p1)
        let reply = p.parse(CharacterStream(string: ""))
        if case let .success(v, _) = reply {
            XCTAssertNil(v)
        } else {
            XCTFail()
        }
    }
    
    func test_optional_whenFailureWithStateChange_returnFailure() {
        let p1 = Parser<Int> { (stream) in
            stream.stateTag += 1
            return .failure([DummyError.err0])
        }
        let p: Parser<Int?> = optional(p1)
        let reply = p.parse(CharacterStream(string: ""))
        if case let .failure(e) = reply {
            XCTAssertEqual(e as! [DummyError], [DummyError.err0])
        } else {
            XCTFail()
        }
    }
    
    func test_optional_whenFatalFailure_returnFatalFailure() {
        let p1 = Parser<Int> { _ in return .fatalFailure([DummyError.err0]) }
        let p: Parser<Int?> = optional(p1)
        let reply = p.parse(CharacterStream(string: ""))
        if case let .fatalFailure(e) = reply {
            XCTAssertEqual(e as! [DummyError], [DummyError.err0])
        } else {
            XCTFail()
        }
    }
    
    func test_skipOptional_success() {
        let p1 = Parser<Int> { _ in return .success(1, []) }
        let p: Parser<Void> = skipOptional(p1)
        let reply = p.parse(CharacterStream(string: ""))
        if case .success = reply {
            
        } else {
            XCTFail()
        }
    }
    
    func test_skipOptional_whenFailureWithoutStateChange_returnSuccess() {
        let p1 = Parser<Int> { _ in return .failure([DummyError.err0]) }
        let p: Parser<Void> = skipOptional(p1)
        let reply = p.parse(CharacterStream(string: ""))
        if case .success = reply {
            
        } else {
            XCTFail()
        }
    }
    
    func test_skipOptional_whenFailureWithStateChange_returnFailure() {
        let p1 = Parser<Int> { (stream) in
            stream.stateTag += 1
            return .failure([DummyError.err0])
        }
        let p: Parser<Void> = skipOptional(p1)
        let reply = p.parse(CharacterStream(string: ""))
        if case let .failure(e) = reply {
            XCTAssertEqual(e as! [DummyError], [DummyError.err0])
        } else {
            XCTFail()
        }
    }
    
    func test_skipOptional_whenFatalFailure_returnFatalFailure() {
        let p1 = Parser<Int> { _ in return .fatalFailure([DummyError.err0]) }
        let p: Parser<Void> = skipOptional(p1)
        let reply = p.parse(CharacterStream(string: ""))
        if case let .fatalFailure(e) = reply {
            XCTAssertEqual(e as! [DummyError], [DummyError.err0])
        } else {
            XCTFail()
        }
    }
    
    func test_attempt_success() {
        let p1 = Parser<Int> { _ in return .success(1, []) }
        let p: Parser<Int> = attempt(p1)
        let reply = p.parse(CharacterStream(string: ""))
        if case let .success(v, _) = reply {
            XCTAssertEqual(v, 1)
        } else {
            XCTFail()
        }
    }
    
    func test_attempt_whenFailureWithoutStateChange_returnFailure() {
        let p1 = Parser<Int> { (stream) in
            return .failure([DummyError.err0])
        }
        let p: Parser<Int> = attempt(p1)
        let stream = CharacterStream(string: "")
        let reply = p.parse(stream)
        if case let .failure(e) = reply {
            XCTAssertEqual(e as! [DummyError], [DummyError.err0])
        } else {
            XCTFail()
        }
    }
    
    func test_attempt_whenFailureWithStateChange_backtrackAndReturnFailure() {
        let p1 = Parser<Int> { (stream) in
            stream.stateTag += 10
            return .failure([DummyError.err0])
        }
        let p: Parser<Int> = attempt(p1)
        let stream = CharacterStream(string: "")
        let stateTag = stream.stateTag
        let reply = p.parse(stream)
        XCTAssertEqual(stream.stateTag, stateTag)
        if case let .failure(e) = reply {
            if let nestedError = e.first as? ParseError.Nested {
                XCTAssertEqual(nestedError.errors as! [DummyError], [DummyError.err0])
            }
        } else {
            XCTFail()
        }
    }
    
    func test_attempt_whenFatalFailureWithoutStateChange_returnFailure() {
        let p1 = Parser<Int> { (stream) in
            return .fatalFailure([DummyError.err0])
        }
        let p: Parser<Int> = attempt(p1)
        let stream = CharacterStream(string: "")
        let reply = p.parse(stream)
        if case let .failure(e) = reply {
            XCTAssertEqual(e as! [DummyError], [DummyError.err0])
        } else {
            XCTFail()
        }
    }
    
    func test_attempt_whenFatalFailure_backtrackAndReturnFailure() {
        let p1 = Parser<Int> { (stream) in
            stream.stateTag += 10
            return .fatalFailure([DummyError.err0])
        }
        let p: Parser<Int> = attempt(p1)
        let stream = CharacterStream(string: "")
        let stateTag = stream.stateTag
        let reply = p.parse(stream)
        XCTAssertEqual(stream.stateTag, stateTag)
        if case let .failure(e) = reply {
            if let nestedError = e.first as? ParseError.Nested {
                XCTAssertEqual(nestedError.errors as! [DummyError], [DummyError.err0])
            }
        } else {
            XCTFail()
        }
    }
    
    func test_attempt_whenNestedError_passthroughNestedError() {
        let p1 = Parser<Int> { (stream) in
            stream.stateTag += 10
            return .failure([ParseError.Nested(position: stream.position,
                                               userInfo: stream.userInfo,
                                               errors: [DummyError.err0])])
        }
        let p: Parser<Int> = attempt(p1)
        let stream = CharacterStream(string: "")
        stream.skip()
        let position = stream.position
        let stateTag = stream.stateTag
        let reply = p.parse(stream)
        XCTAssertEqual(stream.stateTag, stateTag)
        if case let .failure(e) = reply {
            if let nestedError = e.first as? ParseError.Nested {
                XCTAssertEqual(nestedError.position, position)
                XCTAssertEqual(nestedError.errors as! [DummyError], [DummyError.err0])
            }
        } else {
            XCTFail()
        }
    }
}



