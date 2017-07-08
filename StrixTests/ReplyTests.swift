
import XCTest
@testable import Strix

class ReplyTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func test_getValue() {
        XCTAssertEqual(Reply.success(3, []).value, 3)
        XCTAssertNil(Reply<Int>.failure([]).value)
        XCTAssertNil(Reply<Int>.fatalFailure([]).value)
    }
    
    func test_getErrors() {
        let errors: [DummyError] = [
            DummyError.err0,
            DummyError.err1,
            DummyError.err2
        ]
        
        XCTAssertEqual(Reply.success(1, errors).errors as! [DummyError], errors)
        XCTAssertEqual(Reply<Void>.failure(errors).errors as! [DummyError], errors)
        XCTAssertEqual(Reply<Void>.fatalFailure(errors).errors as! [DummyError], errors)
    }
    
    func test_setErrors() {
        let errors: [DummyError] = [
            DummyError.err0,
            DummyError.err1,
            DummyError.err2
        ]
        
        var reply: Reply<Int> = .success(1, [])
        XCTAssertEqual(reply.errors as! [DummyError], [])
        reply.errors = errors
        XCTAssertEqual(reply.errors as! [DummyError], errors)
        if case let .success(v, _) = reply {
            XCTAssertEqual(v, 1)
        } else {
            XCTFail()
        }
        
        reply = .failure([])
        XCTAssertEqual(reply.errors as! [DummyError], [])
        reply.errors = errors
        XCTAssertEqual(reply.errors as! [DummyError], errors)
        
        reply = .fatalFailure([])
        XCTAssertEqual(reply.errors as! [DummyError], [])
        reply.errors = errors
        XCTAssertEqual(reply.errors as! [DummyError], errors)
    }
    
    func test_prependingErrors() {
        let errors1: [DummyError] = [
            DummyError.err0,
            DummyError.err1
        ]
        let errors2: [DummyError] = [
            DummyError.err2,
            DummyError.err3
        ]
        let allErrors = errors1 + errors2
        
        var reply: Reply<Int> = .success(1, errors2)
        reply = reply.prepending(errors1)
        XCTAssertEqual(reply.errors as! [DummyError], allErrors)
        
        reply = .failure(errors2)
        reply = reply.prepending(errors1)
        XCTAssertEqual(reply.errors as! [DummyError], allErrors)
        
        reply = .fatalFailure(errors2)
        reply = reply.prepending(errors1)
        XCTAssertEqual(reply.errors as! [DummyError], allErrors)
    }
    
    func test_prependErrors() {
        let errors1: [DummyError] = [
            DummyError.err0,
            DummyError.err1
        ]
        let errors2: [DummyError] = [
            DummyError.err2,
            DummyError.err3
        ]
        let allErrors = errors1 + errors2
        
        var reply: Reply<Int> = .success(1, errors2)
        reply.prepend(errors1)
        XCTAssertEqual(reply.errors as! [DummyError], allErrors)
        reply.prepend([])
        XCTAssertEqual(reply.errors as! [DummyError], allErrors)
        
        reply = .failure(errors2)
        reply.prepend(errors1)
        XCTAssertEqual(reply.errors as! [DummyError], allErrors)
        
        reply = .fatalFailure(errors2)
        reply.prepend(errors1)
        XCTAssertEqual(reply.errors as! [DummyError], allErrors)
    }
    
    func test_appendingErrors() {
        let errors1: [DummyError] = [
            DummyError.err0,
            DummyError.err1
        ]
        let errors2: [DummyError] = [
            DummyError.err2,
            DummyError.err3
        ]
        let allErrors = errors1 + errors2
        
        var reply: Reply<Int> = .success(1, errors1)
        reply = reply.appending(errors2)
        XCTAssertEqual(reply.errors as! [DummyError], allErrors)
        reply = reply.appending([])
        XCTAssertEqual(reply.errors as! [DummyError], allErrors)
        
        reply = .failure(errors1)
        reply = reply.appending(errors2)
        XCTAssertEqual(reply.errors as! [DummyError], allErrors)
        
        reply = .fatalFailure(errors1)
        reply = reply.appending(errors2)
        XCTAssertEqual(reply.errors as! [DummyError], allErrors)
    }
    
    func test_appendErrors() {
        let errors1: [DummyError] = [
            DummyError.err0,
            DummyError.err1
        ]
        let errors2: [DummyError] = [
            DummyError.err2,
            DummyError.err3
        ]
        let allErrors = errors1 + errors2
        
        var reply: Reply<Int> = .success(1, errors1)
        reply.append(errors2)
        XCTAssertEqual(reply.errors as! [DummyError], allErrors)
        
        reply = .failure(errors1)
        reply.append(errors2)
        XCTAssertEqual(reply.errors as! [DummyError], allErrors)
        
        reply = .fatalFailure(errors1)
        reply.append(errors2)
        XCTAssertEqual(reply.errors as! [DummyError], allErrors)
    }
    
    func test_map() {
        let errors: [DummyError] = [
            DummyError.err0
        ]
        
        var reply: Reply<Int> = .success(1, [])
        XCTAssertEqual(reply.map({ $0 == 1 ? "a" : "b" }).value, "a")
        
        reply = .failure(errors)
        XCTAssertEqual(reply.map({ _ in "a" }).value, nil)
        if case let .failure(e) = reply {
            XCTAssertEqual(e as! [DummyError], errors)
        } else {
            XCTFail()
        }
        
        reply = .fatalFailure(errors)
        XCTAssertEqual(reply.map({ _ in "a" }).value, nil)
        if case let .fatalFailure(e) = reply {
            XCTAssertEqual(e as! [DummyError], errors)
        } else {
            XCTFail()
        }
    }
    
    func test_flatMap_whenSuccess() {
        let errors1: [DummyError] = [
            DummyError.err0,
            DummyError.err1
        ]
        let errors2: [DummyError] = [
            DummyError.err2,
            DummyError.err3
        ]
        let allErrors = errors1 + errors2
        
        let reply: Reply<Int> = .success(1, errors1)
        var mappedReply: Reply<String> = reply.flatMap {
            return .success($0 == 1 ? "a" : "b", errors2)
        }
        if case let .success(v, e) = mappedReply {
            XCTAssertEqual(v, "a")
            XCTAssertEqual(e as! [DummyError], allErrors)
        } else {
            XCTFail()
        }
        
        mappedReply = reply.flatMap { _ in
            return .failure(errors2)
        }
        if case let .failure(e) = mappedReply {
            XCTAssertEqual(e as! [DummyError], allErrors)
        } else {
            XCTFail()
        }
        
        mappedReply = reply.flatMap { _ in
            return .fatalFailure(errors2)
        }
        if case let .fatalFailure(e) = mappedReply {
            XCTAssertEqual(e as! [DummyError], allErrors)
        } else {
            XCTFail()
        }
    }
    
    func test_flatMap_whenFailure() {
        let errors1: [DummyError] = [
            DummyError.err0,
            DummyError.err1
        ]
        let errors2: [DummyError] = [
            DummyError.err2,
            DummyError.err3
        ]
        
        let reply: Reply<Int> = .failure(errors1)
        let mappedReply: Reply<String> = reply.flatMap { _ in
            XCTFail()
            return .success("a", errors2)
        }
        if case let .failure(e) = mappedReply {
            XCTAssertEqual(e as! [DummyError], errors1)
        } else {
            XCTFail()
        }
    }
    
    func test_flatMap_whenFatalFailure() {
        let errors1: [DummyError] = [
            DummyError.err0,
            DummyError.err1
        ]
        let errors2: [DummyError] = [
            DummyError.err2,
            DummyError.err3
        ]
        
        let reply: Reply<Int> = .fatalFailure(errors1)
        let mappedReply: Reply<String> = reply.flatMap { _ in
            XCTFail()
            return .success("a", errors2)
        }
        if case let .fatalFailure(e) = mappedReply {
            XCTAssertEqual(e as! [DummyError], errors1)
        } else {
            XCTFail()
        }
    }
}



