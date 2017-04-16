
import XCTest
@testable import Strix

class ReplyTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func test_value() {
        XCTAssertEqual(Reply.success(3, []).value, 3)
        XCTAssertEqual(Reply<Int>.failure([]).value, nil)
        XCTAssertEqual(Reply<Int>.fatalFailure([]).value, nil)
    }
    
    func test_getErrors() {
        let errors: [NSError] = [
            NSError(domain: "", code: 1, userInfo: nil),
            NSError(domain: "", code: 2, userInfo: nil),
            NSError(domain: "", code: 3, userInfo: nil)
        ]
        
        XCTAssertEqual(Reply.success(1, errors).errors as [NSError], errors)
        XCTAssertEqual(Reply<Void>.failure(errors).errors as [NSError], errors)
        XCTAssertEqual(Reply<Void>.fatalFailure(errors).errors as [NSError], errors)
    }
    
    func test_setErrors() {
        let errors: [NSError] = [
            NSError(domain: "", code: 1, userInfo: nil),
            NSError(domain: "", code: 2, userInfo: nil),
            NSError(domain: "", code: 3, userInfo: nil)
        ]
        
        var reply: Reply<Int> = .success(1, [])
        XCTAssertEqual(reply.errors as [NSError], [])
        reply.errors = errors
        XCTAssertEqual(reply.errors as [NSError], errors)
        if case let .success(v, _) = reply {
            XCTAssertEqual(v, 1)
        } else {
            XCTFail()
        }
        
        reply = .failure([])
        XCTAssertEqual(reply.errors as [NSError], [])
        reply.errors = errors
        XCTAssertEqual(reply.errors as [NSError], errors)
        
        reply = .fatalFailure([])
        XCTAssertEqual(reply.errors as [NSError], [])
        reply.errors = errors
        XCTAssertEqual(reply.errors as [NSError], errors)
    }
    
    func test_prependingErrors() {
        let errors1: [NSError] = [
            NSError(domain: "", code: 1, userInfo: nil),
            NSError(domain: "", code: 2, userInfo: nil)
        ]
        let errors2: [NSError] = [
            NSError(domain: "", code: 3, userInfo: nil),
            NSError(domain: "", code: 4, userInfo: nil)
        ]
        let allErrors = errors1 + errors2
        
        var reply: Reply<Int> = .success(1, errors2)
        reply = reply.prepending(errors1)
        XCTAssertEqual(reply.errors as [NSError], allErrors)
        
        reply = .failure(errors2)
        reply = reply.prepending(errors1)
        XCTAssertEqual(reply.errors as [NSError], allErrors)
        
        reply = .fatalFailure(errors2)
        reply = reply.prepending(errors1)
        XCTAssertEqual(reply.errors as [NSError], allErrors)
    }
    
    func test_prependErrors() {
        let errors1: [NSError] = [
            NSError(domain: "", code: 1, userInfo: nil),
            NSError(domain: "", code: 2, userInfo: nil)
        ]
        let errors2: [NSError] = [
            NSError(domain: "", code: 3, userInfo: nil),
            NSError(domain: "", code: 4, userInfo: nil)
        ]
        let allErrors = errors1 + errors2
        
        var reply: Reply<Int> = .success(1, errors2)
        reply.prepend(errors1)
        XCTAssertEqual(reply.errors as [NSError], allErrors)
        reply.prepend([])
        XCTAssertEqual(reply.errors as [NSError], allErrors)
        
        reply = .failure(errors2)
        reply.prepend(errors1)
        XCTAssertEqual(reply.errors as [NSError], allErrors)
        
        reply = .fatalFailure(errors2)
        reply.prepend(errors1)
        XCTAssertEqual(reply.errors as [NSError], allErrors)
    }
    
    func test_appendingErrors() {
        let errors1: [NSError] = [
            NSError(domain: "", code: 1, userInfo: nil),
            NSError(domain: "", code: 2, userInfo: nil)
        ]
        let errors2: [NSError] = [
            NSError(domain: "", code: 3, userInfo: nil),
            NSError(domain: "", code: 4, userInfo: nil)
        ]
        let allErrors = errors1 + errors2
        
        var reply: Reply<Int> = .success(1, errors1)
        reply = reply.appending(errors2)
        XCTAssertEqual(reply.errors as [NSError], allErrors)
        reply = reply.appending([])
        XCTAssertEqual(reply.errors as [NSError], allErrors)
        
        reply = .failure(errors1)
        reply = reply.appending(errors2)
        XCTAssertEqual(reply.errors as [NSError], allErrors)
        
        reply = .fatalFailure(errors1)
        reply = reply.appending(errors2)
        XCTAssertEqual(reply.errors as [NSError], allErrors)
    }
    
    func test_appendErrors() {
        let errors1: [NSError] = [
            NSError(domain: "", code: 1, userInfo: nil),
            NSError(domain: "", code: 2, userInfo: nil)
        ]
        let errors2: [NSError] = [
            NSError(domain: "", code: 3, userInfo: nil),
            NSError(domain: "", code: 4, userInfo: nil)
        ]
        let allErrors = errors1 + errors2
        
        var reply: Reply<Int> = .success(1, errors1)
        reply.append(errors2)
        XCTAssertEqual(reply.errors as [NSError], allErrors)
        
        reply = .failure(errors1)
        reply.append(errors2)
        XCTAssertEqual(reply.errors as [NSError], allErrors)
        
        reply = .fatalFailure(errors1)
        reply.append(errors2)
        XCTAssertEqual(reply.errors as [NSError], allErrors)
    }
    
    func test_map() {
        let errors: [NSError] = [
            NSError(domain: "", code: 1, userInfo: nil)
        ]
        
        var reply: Reply<Int> = .success(1, [])
        XCTAssertEqual(reply.map({ $0 == 1 ? "a" : "b" }).value, "a")
        
        reply = .failure(errors)
        XCTAssertEqual(reply.map({ _ in "a" }).value, nil)
        if case let .failure(e as [NSError]) = reply {
            XCTAssertEqual(e, errors)
        } else {
            XCTFail()
        }
        
        reply = .fatalFailure(errors)
        XCTAssertEqual(reply.map({ _ in "a" }).value, nil)
        if case let .fatalFailure(e as [NSError]) = reply {
            XCTAssertEqual(e, errors)
        } else {
            XCTFail()
        }
    }
    
    func test_flatMap_whenSuccess() {
        let errors1: [NSError] = [
            NSError(domain: "", code: 1, userInfo: nil),
            NSError(domain: "", code: 2, userInfo: nil)
        ]
        let errors2: [NSError] = [
            NSError(domain: "", code: 3, userInfo: nil),
            NSError(domain: "", code: 4, userInfo: nil)
        ]
        let allErrors = errors1 + errors2
        
        let reply: Reply<Int> = .success(1, errors1)
        var mappedReply: Reply<String> = reply.flatMap {
            return .success($0 == 1 ? "a" : "b", errors2)
        }
        if case let .success(v, e) = mappedReply {
            XCTAssertEqual(v, "a")
            XCTAssertEqual(e as [NSError], allErrors)
        } else {
            XCTFail()
        }
        
        mappedReply = reply.flatMap { _ in
            return .failure(errors2)
        }
        if case let .failure(e) = mappedReply {
            XCTAssertEqual(e as [NSError], allErrors)
        } else {
            XCTFail()
        }
        
        mappedReply = reply.flatMap { _ in
            return .fatalFailure(errors2)
        }
        if case let .fatalFailure(e) = mappedReply {
            XCTAssertEqual(e as [NSError], allErrors)
        } else {
            XCTFail()
        }
    }
    
    func test_flatMap_whenFailure() {
        let errors1: [NSError] = [
            NSError(domain: "", code: 1, userInfo: nil),
            NSError(domain: "", code: 2, userInfo: nil)
        ]
        let errors2: [NSError] = [
            NSError(domain: "", code: 3, userInfo: nil),
            NSError(domain: "", code: 4, userInfo: nil)
        ]
        
        let reply: Reply<Int> = .failure(errors1)
        let mappedReply: Reply<String> = reply.flatMap { _ in
            XCTFail()
            return .success("a", errors2)
        }
        if case let .failure(e) = mappedReply {
            XCTAssertEqual(e as [NSError], errors1)
        } else {
            XCTFail()
        }
    }
    
    func test_flatMap_whenFatalFailure() {
        let errors1: [NSError] = [
            NSError(domain: "", code: 1, userInfo: nil),
            NSError(domain: "", code: 2, userInfo: nil)
        ]
        let errors2: [NSError] = [
            NSError(domain: "", code: 3, userInfo: nil),
            NSError(domain: "", code: 4, userInfo: nil)
        ]
        
        let reply: Reply<Int> = .fatalFailure(errors1)
        let mappedReply: Reply<String> = reply.flatMap { _ in
            XCTFail()
            return .success("a", errors2)
        }
        if case let .fatalFailure(e) = mappedReply {
            XCTAssertEqual(e as [NSError], errors1)
        } else {
            XCTFail()
        }
    }
}



