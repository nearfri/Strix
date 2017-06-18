
import XCTest
@testable import Strix

class PrimitivesCustomizingErrorTests: XCTestCase {
    let errLabel: String = "Int literal"
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func test_customLabel_parseWithoutStateChange_changeError() {
        let p1 = Parser<Int> { (stream) in
            return .success(1, [DummyError.err0])
        }
        let p: Parser<Int> = p1 <?> errLabel
        let reply = p.parse(CharacterStream(string: ""))
        var passed = false
        if case let .success(v, e) = reply {
            XCTAssertEqual(v, 1)
            XCTAssertEqual(e as! [ParseError.Expected], [ParseError.Expected(errLabel)])
            passed = true
        }
        XCTAssertTrue(passed)
    }
    
    func test_customLabel_parseWithStateChange_notChangeError() {
        let p1 = Parser<Int> { (stream) in
            stream.stateTag += 10
            return .success(1, [DummyError.err0])
        }
        let p: Parser<Int> = p1 <?> errLabel
        let reply = p.parse(CharacterStream(string: ""))
        var passed = false
        if case let .success(v, e) = reply {
            XCTAssertEqual(v, 1)
            XCTAssertEqual(e as! [DummyError], [DummyError.err0])
            passed = true
        }
        XCTAssertTrue(passed)
    }
    
    func test_customCompoundLabel_successWithoutStateChange_changeError() {
        let p1 = Parser<Int> { (stream) in
            return .success(1, [DummyError.err0])
        }
        let p: Parser<Int> = p1 <??> errLabel
        let reply = p.parse(CharacterStream(string: ""))
        var passed = false
        if case let .success(v, e) = reply {
            XCTAssertEqual(v, 1)
            XCTAssertEqual(e as! [ParseError.Expected], [ParseError.Expected(errLabel)])
            passed = true
        }
        XCTAssertTrue(passed)
    }
    
    func test_customCompoundLabel_successWithStateChange_notChangeError() {
        let p1 = Parser<Int> { (stream) in
            stream.stateTag += 10
            return .success(1, [DummyError.err0])
        }
        let p: Parser<Int> = p1 <??> errLabel
        let reply = p.parse(CharacterStream(string: ""))
        var passed = false
        if case let .success(v, e) = reply {
            XCTAssertEqual(v, 1)
            XCTAssertEqual(e as! [DummyError], [DummyError.err0])
            passed = true
        }
        XCTAssertTrue(passed)
    }
    
    func test_customCompoundLabel_failureNestedErrorWithoutStateChange_returnCompoundError() {
        let p1 = Parser<Int> { (stream) in
            let err = ParseError.Nested(position: stream.position,
                                        userInfo: stream.userInfo,
                                        errors: [])
            return .failure([err])
        }
        let p: Parser<Int> = p1 <??> errLabel
        let reply = p.parse(CharacterStream(string: ""))
        var passed = false
        if case let .failure(e) = reply {
            if let err = e.first as? ParseError.Compound {
                XCTAssertEqual(err.label, errLabel)
                passed = true
            }
        }
        XCTAssertTrue(passed)
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
        let reply = p.parse(CharacterStream(string: ""))
        var passed = false
        if case let .failure(e) = reply {
            if let err = e.first as? ParseError.Compound {
                XCTAssertEqual(err.label, errLabel)
                passed = true
            }
        }
        XCTAssertTrue(passed)
    }
    
    func test_customCompoundLabel_failureNormalErrorWithoutStateChange_returnExpectedError() {
        let p1 = Parser<Int> { (stream) in
            return .failure([DummyError.err0])
        }
        let p: Parser<Int> = p1 <??> errLabel
        let reply = p.parse(CharacterStream(string: ""))
        var passed = false
        if case let .failure(e) = reply {
            XCTAssertEqual(e as! [ParseError.Expected], [ParseError.Expected(errLabel)])
            passed = true
        }
        XCTAssertTrue(passed)
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
        let stream = CharacterStream(string: "")
        let stateTag = stream.stateTag
        let reply = p.parse(stream)
        XCTAssertEqual(stream.stateTag, stateTag)
        var passed = false
        if case let .fatalFailure(e) = reply {
            if let err = e.first as? ParseError.Compound {
                XCTAssertEqual(err.label, errLabel)
                passed = true
            }
        }
        XCTAssertTrue(passed)
    }
    
    func test_customCompoundLabel_failureNormalErrorWithStateChange_backtrackAndReturnCompoundError() {
        let p1 = Parser<Int> { (stream) in
            stream.stateTag += 10
            return .failure([DummyError.err0])
        }
        let p: Parser<Int> = p1 <??> errLabel
        let stream = CharacterStream(string: "")
        let stateTag = stream.stateTag
        let reply = p.parse(stream)
        XCTAssertEqual(stream.stateTag, stateTag)
        var passed = false
        if case let .fatalFailure(e) = reply {
            if let err = e.first as? ParseError.Compound {
                XCTAssertEqual(err.label, errLabel)
                passed = true
            }
        }
        XCTAssertTrue(passed)
    }
    
    func test_fail_returnFailure() {
        let p: Parser<Int> = fail(errLabel)
        let reply = p.parse(CharacterStream(string: ""))
        var passed = false
        if case let .failure(e) = reply {
            if let err = e.first as? ParseError.Generic {
                XCTAssertEqual(err.message, errLabel)
                passed = true
            }
        }
        XCTAssertTrue(passed)
    }
    
    func test_fatalFailure_returnFatalFailure() {
        let p: Parser<Int> = failFatally(errLabel)
        let reply = p.parse(CharacterStream(string: ""))
        var passed = false
        if case let .fatalFailure(e) = reply {
            if let err = e.first as? ParseError.Generic {
                XCTAssertEqual(err.message, errLabel)
                passed = true
            }
        }
        XCTAssertTrue(passed)
    }
}



