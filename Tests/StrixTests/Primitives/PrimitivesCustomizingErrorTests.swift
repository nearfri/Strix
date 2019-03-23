
import XCTest
@testable import Strix

class PrimitivesCustomizingErrorTests: XCTestCase {
    var defaultStream: CharacterStream = makeEmptyStream()
    var startStateTag: Int = 0
    let errLabel: String = "Int literal"
    
    override func setUp() {
        super.setUp()
        defaultStream = makeEmptyStream()
        startStateTag = defaultStream.stateTag
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func test_customLabel_parseWithoutStateChange_changeError() {
        let p1 = Parser<Int> { (stream) in
            return .success(1, [DummyError.err0])
        }
        let p: Parser<Int> = p1 <?> errLabel
        checkSuccess(p.parse(defaultStream), 1, [ParseError.Expected(errLabel)])
    }
    
    func test_customLabel_parseWithStateChange_notChangeError() {
        let p1 = Parser<Int> { (stream) in
            stream.stateTag += 10
            return .success(1, [DummyError.err0])
        }
        let p: Parser<Int> = p1 <?> errLabel
        checkSuccess(p.parse(defaultStream), 1, [DummyError.err0])
    }
    
    func test_customCompoundLabel_successWithoutStateChange_changeError() {
        let p1 = Parser<Int> { (stream) in
            return .success(1, [DummyError.err0])
        }
        let p: Parser<Int> = p1 <??> errLabel
        checkSuccess(p.parse(defaultStream), 1, [ParseError.Expected(errLabel)])
    }
    
    func test_customCompoundLabel_successWithStateChange_notChangeError() {
        let p1 = Parser<Int> { (stream) in
            stream.stateTag += 10
            return .success(1, [DummyError.err0])
        }
        let p: Parser<Int> = p1 <??> errLabel
        checkSuccess(p.parse(defaultStream), 1, [DummyError.err0])
    }
    
    func test_customCompoundLabel_failureNestedErrorWithoutStateChange_returnCompoundError() {
        let p1 = Parser<Int> { (stream) in
            let err = ParseError.Nested(position: stream.position,
                                        userInfo: stream.userInfo,
                                        errors: [])
            return .failure([err])
        }
        let p: Parser<Int> = p1 <??> errLabel
        if case let .failure(e) = p.parse(defaultStream),
            let err = e.first as? ParseError.Compound {
            
            XCTAssertEqual(err.label, errLabel)
        } else {
            shouldNotEnterHere()
        }
    }
    
    func test_customCompoundLabel_failureCompoundErrorWithoutStateChange_returnCompoundError() {
        let p1 = Parser<Int> { (stream) in
            let err = ParseError.Compound(label: "should not return this label",
                                          position: stream.position,
                                          userInfo: stream.userInfo,
                                          errors: [])
            return .failure([err])
        }
        let p: Parser<Int> = p1 <??> errLabel
        if case let .failure(e) = p.parse(defaultStream),
            let err = e.first as? ParseError.Compound {
            
            XCTAssertEqual(err.label, errLabel)
        } else {
            shouldNotEnterHere()
        }
    }
    
    func test_customCompoundLabel_failureNormalErrorWithoutStateChange_returnExpectedError() {
        let p1 = Parser<Int> { (stream) in
            return .failure([DummyError.err0])
        }
        let p: Parser<Int> = p1 <??> errLabel
        checkFailure(p.parse(defaultStream), [ParseError.Expected(errLabel)])
    }
    
    func test_customCompoundLabel_failureCompoundErrorWithStateChange_backtrackAndReturnCompoundError() {
        let p1 = Parser<Int> { (stream) in
            let err = ParseError.Compound(label: "should not return this label",
                                          position: stream.position,
                                          userInfo: stream.userInfo,
                                          errors: [])
            stream.stateTag += 10
            return .failure([err])
        }
        let p: Parser<Int> = p1 <??> errLabel
        let reply = p.parse(defaultStream)
        XCTAssertEqual(defaultStream.stateTag, startStateTag)
        if case let .failure(e) = reply, let err = e.first as? ParseError.Compound {
            XCTAssertEqual(err.label, errLabel)
        } else {
            shouldNotEnterHere()
        }
    }
    
    func test_customCompoundLabel_failureNormalErrorWithStateChange_backtrackAndReturnCompoundError() {
        let p1 = Parser<Int> { (stream) in
            stream.stateTag += 10
            return .failure([DummyError.err0])
        }
        let p: Parser<Int> = p1 <??> errLabel
        let reply = p.parse(defaultStream)
        XCTAssertEqual(defaultStream.stateTag, startStateTag)
        if case let .failure(e) = reply, let err = e.first as? ParseError.Compound {
            XCTAssertEqual(err.label, errLabel)
        } else {
            shouldNotEnterHere()
        }
    }
    
    func test_fail_returnFailure() {
        let p: Parser<Int> = fail(errLabel)
        checkFailure(p.parse(defaultStream), [ParseError.Generic(message: errLabel)])
    }
}



