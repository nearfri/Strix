
import XCTest
@testable import Strix

private let dummyErrors: [DummyError] = [DummyError.err0]

class PrimitivesLookAheadTests: XCTestCase {
    var defaultStream: CharacterStream = CharacterStream(string: "")
    var startStateTag: Int = 0
    
    override func setUp() {
        super.setUp()
        defaultStream = CharacterStream(string: "")
        startStateTag = defaultStream.stateTag
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func test_NotEmpty_whenSuccessWithStateChange_returnSuccess() {
        let p1 = Parser<Int> { (stream) in
            stream.stateTag += 1
            return .success(1, dummyErrors)
        }
        let p: Parser<Int> = notEmpty(p1)
        checkSuccess(p.parse(defaultStream), 1, dummyErrors)
    }
    
    func test_NotEmpty_whenSuccessWithoutStateChange_returnFailure() {
        let p1 = Parser<Int> { (stream) in
            return .success(1, dummyErrors)
        }
        let p: Parser<Int> = notEmpty(p1)
        checkFailure(p.parse(defaultStream), dummyErrors)
    }
    
    func test_followed_whenSuccess_backtrackAndReturnSuccess() {
        let p1 = Parser<Int> { (stream) in
            stream.stateTag += 10
            return .success(1, dummyErrors)
        }
        let p: Parser<Void> = followed(by: p1, errorLabel: "one")
        checkSuccess(p.parse(defaultStream))
        XCTAssertEqual(defaultStream.stateTag, startStateTag)
    }
    
    func test_followed_whenFailureWithLabel_backtrackAndReturnFailure() {
        let p1 = Parser<Int> { (stream) in
            stream.stateTag += 10
            return .failure(dummyErrors)
        }
        let p: Parser<Void> = followed(by: p1, errorLabel: "one")
        checkFailure(p.parse(defaultStream), [ParseError.Expected("one")])
        XCTAssertEqual(defaultStream.stateTag, startStateTag)
    }
    
    func test_followed_whenFailureWithoutLabel_backtrackAndReturnFailure() {
        let p1 = Parser<Int> { (stream) in
            stream.stateTag += 10
            return .failure(dummyErrors)
        }
        let p: Parser<Void> = followed(by: p1)
        checkFailure(p.parse(defaultStream), [] as [DummyError])
        XCTAssertEqual(defaultStream.stateTag, startStateTag)
    }
    
    func test_notFollowed_whenSuccessWithLabel_backtrackAndReturnFailure() {
        let p1 = Parser<Int> { (stream) in
            stream.stateTag += 10
            return .success(1, dummyErrors)
        }
        let p: Parser<Void> = notFollowed(by: p1, errorLabel: "one")
        checkFailure(p.parse(defaultStream), [ParseError.Unexpected("one")])
        XCTAssertEqual(defaultStream.stateTag, startStateTag)
    }
    
    func test_notFollowed_whenSuccessWithoutLabel_backtrackAndReturnFailure() {
        let p1 = Parser<Int> { (stream) in
            stream.stateTag += 10
            return .success(1, dummyErrors)
        }
        let p: Parser<Void> = notFollowed(by: p1)
        checkFailure(p.parse(defaultStream), [] as [DummyError])
        XCTAssertEqual(defaultStream.stateTag, startStateTag)
    }
    
    func test_notFollowed_whenFailure_backtrackAndReturnSuccess() {
        let p1 = Parser<Int> { (stream) in
            stream.stateTag += 10
            return .failure(dummyErrors)
        }
        let p: Parser<Void> = notFollowed(by: p1, errorLabel: "one")
        checkSuccess(p.parse(defaultStream))
        XCTAssertEqual(defaultStream.stateTag, startStateTag)
    }
    
    func test_lookAhead_whenSuccess_backtrackAndReturnSuccess() {
        let p1 = Parser<Int> { (stream) in
            stream.stateTag += 10
            return .success(1, dummyErrors)
        }
        let p: Parser<Int> = lookAhead(p1)
        checkSuccess(p.parse(defaultStream), 1)
        XCTAssertEqual(defaultStream.stateTag, startStateTag)
    }
    
    func test_lookAhead_whenFailure_backtrackAndReturnFailure() {
        let p1 = Parser<Int> { (stream) in
            stream.stateTag += 10
            return .failure(dummyErrors)
        }
        let p: Parser<Int> = lookAhead(p1)
        let reply = p.parse(defaultStream)
        XCTAssertEqual(defaultStream.stateTag, startStateTag)
        if case let .failure(e) = reply {
            if let nestedError = e.first as? ParseError.Nested {
                XCTAssertEqual(nestedError.errors as! [DummyError], dummyErrors)
            } else {
                shouldNotEnterHere()
            }
        } else {
            shouldNotEnterHere()
        }
    }
    
    func test_lookAhead_whenFatalFailure_backtrackAndReturnFailure() {
        let p1 = Parser<Int> { (stream) in
            stream.stateTag += 10
            return .fatalFailure(dummyErrors)
        }
        let p: Parser<Int> = lookAhead(p1)
        let reply = p.parse(defaultStream)
        XCTAssertEqual(defaultStream.stateTag, startStateTag)
        if case let .failure(e) = reply, let nestedError = e.first as? ParseError.Nested {
            XCTAssertEqual(nestedError.errors as! [DummyError], dummyErrors)
        } else {
            shouldNotEnterHere()
        }
    }
    
    func test_lookAhead_whenFailureWithoutStateChange_returnFailureWithOriginalErrors() {
        let p1 = Parser<Int> { (stream) in
            return .failure(dummyErrors)
        }
        let p: Parser<Int> = lookAhead(p1)
        checkFailure(p.parse(defaultStream), dummyErrors)
        XCTAssertEqual(defaultStream.stateTag, startStateTag)
    }
}



