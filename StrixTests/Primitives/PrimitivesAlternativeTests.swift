
import XCTest
@testable import Strix

class PrimitivesAlternativeTests: XCTestCase {
    var defaultStream: CharacterStream = makeEmptyStream()
    
    override func setUp() {
        super.setUp()
        defaultStream = makeEmptyStream()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func test_alternative_whenLeftSuccess_returnLeft() {
        let p1 = Parser<Int> { _ in return .success(1, []) }
        let p2 = Parser<Int> { _ in
            shouldNotEnterHere()
            return .success(2, [])
        }
        let p = p1 <|> p2
        checkSuccess(p.parse(defaultStream), 1)
    }
    
    func test_alternative_whenLeftFailureRightSuccess_returnRight() {
        let p1 = Parser<Int> { _ in return .failure([DummyError.err0]) }
        let p2 = Parser { _ in return .success(2, [DummyError.err1]) }
        let p = p1 <|> p2
        checkSuccess(p.parse(defaultStream), 2, [DummyError.err0, DummyError.err1])
    }
    
    func test_alternative_whenBothFailure_returnBothError() {
        let p1 = Parser<Int> { _ in return .failure([DummyError.err0]) }
        let p2 = Parser<Int> { _ in return .failure([DummyError.err1]) }
        let p = p1 <|> p2
        checkFailure(p.parse(defaultStream), [DummyError.err0, DummyError.err1])
    }
    
    func test_alternative_whenBothFailureWithStateChange_returnOneError() {
        let p1 = Parser<Int> { _ in return .failure([DummyError.err0]) }
        let p2 = Parser<Int> { (stream) in
            stream.stateTag += 1
            return .failure([DummyError.err1])
        }
        let p = p1 <|> p2
        checkFailure(p.parse(defaultStream), [DummyError.err1])
    }
    
    func test_alternative_whenLeftFatalFailure_returnFatalFailure() {
        let p1 = Parser<Int> { _ in return .fatalFailure([DummyError.err0]) }
        let p2 = Parser<Int> { _ in
            shouldNotEnterHere()
            return .success(2, [DummyError.err1])
        }
        let p = p1 <|> p2
        checkFatalFailure(p.parse(defaultStream), [DummyError.err0])
    }
    
    func test_alternative_whenLeftFailureWithStateChange_returnFailure() {
        let p1 = Parser<Int> { (stream) in
            stream.stateTag += 1
            return .failure([DummyError.err0])
        }
        let p2 = Parser<Int> { _ in
            shouldNotEnterHere()
            return .success(2, [DummyError.err1])
        }
        let p = p1 <|> p2
        checkFailure(p.parse(defaultStream), [DummyError.err0])
    }
    
    func test_choice_success() {
        let p1 = Parser<Int> { _ in return .failure([DummyError.err0]) }
        let p2 = Parser<Int> { _ in return .failure([DummyError.err1]) }
        let p3 = Parser<Int> { _ in return .failure([DummyError.err2]) }
        let p4 = Parser<Int> { _ in return .success(4, []) }
        let p = choice([p1, p2, p3, p4])
        checkSuccess(p.parse(defaultStream), 4, [DummyError.err0, DummyError.err1, DummyError.err2])
    }
    
    func test_choice_whenFatalFailure_returnFatalFailure() {
        let p1 = Parser<Int> { _ in return .failure([DummyError.err0]) }
        let p2 = Parser<Int> { _ in return .fatalFailure([DummyError.err1]) }
        let p3 = Parser<Int> { _ in
            shouldNotEnterHere()
            return .failure([DummyError.err2])
        }
        let p4 = Parser<Int> { _ in
            shouldNotEnterHere()
            return .success(4, [])
        }
        let p = choice([p1, p2, p3, p4])
        checkFatalFailure(p.parse(defaultStream), [DummyError.err0, DummyError.err1])
    }
    
    func test_choice_whenFailureWithStateChange_returnFailure() {
        let p1 = Parser<Int> { _ in return .failure([DummyError.err0]) }
        let p2 = Parser<Int> { (stream) in
            stream.stateTag += 1
            return .failure([DummyError.err1])
        }
        let p3 = Parser<Int> { _ in
            shouldNotEnterHere()
            return .failure([DummyError.err2])
        }
        let p4 = Parser<Int> { _ in
            shouldNotEnterHere()
            return .success(4, [])
        }
        let p = choice([p1, p2, p3, p4])
        checkFailure(p.parse(defaultStream), [DummyError.err1])
    }
    
    func test_optional_success() {
        let p1 = Parser<Int> { _ in return .success(1, []) }
        let p: Parser<Int?> = optional(p1)
        checkSuccess(p.parse(defaultStream), 1)
    }
    
    func test_optional_whenFailureWithoutStateChange_returnSuccess() {
        let p1 = Parser<Int> { _ in return .failure([DummyError.err0]) }
        let p: Parser<Int?> = optional(p1)
        checkSuccess(p.parse(defaultStream), nil, [DummyError.err0])
    }
    
    func test_optional_whenFailureWithStateChange_returnFailure() {
        let p1 = Parser<Int> { (stream) in
            stream.stateTag += 1
            return .failure([DummyError.err0])
        }
        let p: Parser<Int?> = optional(p1)
        checkFailure(p.parse(defaultStream), [DummyError.err0])
    }
    
    func test_optional_whenFatalFailure_returnFatalFailure() {
        let p1 = Parser<Int> { _ in return .fatalFailure([DummyError.err0]) }
        let p: Parser<Int?> = optional(p1)
        checkFatalFailure(p.parse(defaultStream), [DummyError.err0])
    }
    
    func test_skipOptional_success() {
        let p1 = Parser<Int> { _ in return .success(1, []) }
        let p: Parser<Void> = skipOptional(p1)
        checkSuccess(p.parse(defaultStream))
    }
    
    func test_skipOptional_whenFailureWithoutStateChange_returnSuccess() {
        let p1 = Parser<Int> { _ in return .failure([DummyError.err0]) }
        let p: Parser<Void> = skipOptional(p1)
        checkSuccess(p.parse(defaultStream), [DummyError.err0])
    }
    
    func test_skipOptional_whenFailureWithStateChange_returnFailure() {
        let p1 = Parser<Int> { (stream) in
            stream.stateTag += 1
            return .failure([DummyError.err0])
        }
        let p: Parser<Void> = skipOptional(p1)
        checkFailure(p.parse(defaultStream), [DummyError.err0])
    }
    
    func test_skipOptional_whenFatalFailure_returnFatalFailure() {
        let p1 = Parser<Int> { _ in return .fatalFailure([DummyError.err0]) }
        let p: Parser<Void> = skipOptional(p1)
        checkFatalFailure(p.parse(defaultStream), [DummyError.err0])
    }
    
    func test_attempt_success() {
        let p1 = Parser<Int> { _ in return .success(1, []) }
        let p: Parser<Int> = attempt(p1)
        checkSuccess(p.parse(defaultStream), 1)
    }
    
    func test_attempt_whenFailureWithoutStateChange_returnFailure() {
        let p1 = Parser<Int> { (stream) in
            return .failure([DummyError.err0])
        }
        let p: Parser<Int> = attempt(p1)
        checkFailure(p.parse(defaultStream), [DummyError.err0])
    }
    
    func test_attempt_whenFailureWithStateChange_backtrackAndReturnFailure() {
        let p1 = Parser<Int> { (stream) in
            stream.stateTag += 10
            return .failure([DummyError.err0])
        }
        let p: Parser<Int> = attempt(p1)
        let stream = defaultStream
        let stateTag = stream.stateTag
        let reply = p.parse(stream)
        XCTAssertEqual(stream.stateTag, stateTag)
        if case let .failure(e) = reply {
            if let nestedError = e.first as? ParseError.Nested {
                XCTAssertEqual(nestedError.errors as! [DummyError], [DummyError.err0])
            }
        } else {
            shouldNotEnterHere()
        }
    }
    
    func test_attempt_whenFatalFailureWithoutStateChange_returnFailure() {
        let p1 = Parser<Int> { (stream) in
            return .fatalFailure([DummyError.err0])
        }
        let p: Parser<Int> = attempt(p1)
        checkFailure(p.parse(defaultStream), [DummyError.err0])
    }
    
    func test_attempt_whenFatalFailure_backtrackAndReturnFailure() {
        let p1 = Parser<Int> { (stream) in
            stream.stateTag += 10
            return .fatalFailure([DummyError.err0])
        }
        let p: Parser<Int> = attempt(p1)
        let stream = defaultStream
        let stateTag = stream.stateTag
        let reply = p.parse(stream)
        XCTAssertEqual(stream.stateTag, stateTag)
        if case let .failure(e) = reply, let nestedError = e.first as? ParseError.Nested {
            XCTAssertEqual(nestedError.errors as! [DummyError], [DummyError.err0])
        } else {
            shouldNotEnterHere()
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
        let stream = defaultStream
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
            shouldNotEnterHere()
        }
    }
}



