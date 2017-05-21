
import XCTest
@testable import Strix

private enum DummyError: Error {
    case err0
    case err1
}

class ParserTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func test_flatMap_success() {
        let numberString = Parser { (stream) -> Reply<String> in
            return .success("2", [DummyError.err0])
        }
        let toInt = { (str: String) -> Parser<Int> in
            return Parser { (stream) -> Reply<Int> in
                return .success(Int(str)!, [DummyError.err1])
            }
        }
        let p = numberString.flatMap(toInt)
        let stream = CharacterStream(string: "")
        let reply = p.parse(stream)
        XCTAssertEqual(reply.value, 2)
    }
    
    func test_flatMap_whenChangesStateTag_notPrependingErrors() {
        let numberString = Parser { (stream) -> Reply<String> in
            return .success("2", [DummyError.err0])
        }
        let toInt = { (str: String) -> Parser<Int> in
            return Parser { (stream) -> Reply<Int> in
                stream.stateTag += 1
                return .success(Int(str)!, [DummyError.err1])
            }
        }
        let p = numberString.flatMap(toInt)
        let stream = CharacterStream(string: "")
        let reply = p.parse(stream)
        XCTAssertEqual(reply.errors as! [DummyError], [DummyError.err1])
    }
    
    func test_flatMap_whenNotChangeStateTag_prependingErrors() {
        let numberString = Parser { (stream) -> Reply<String> in
            return .success("2", [DummyError.err0])
        }
        let toInt = { (str: String) -> Parser<Int> in
            return Parser { (stream) -> Reply<Int> in
                return .success(Int(str)!, [DummyError.err1])
            }
        }
        let p = numberString.flatMap(toInt)
        let stream = CharacterStream(string: "")
        let reply = p.parse(stream)
        XCTAssertEqual(reply.errors as! [DummyError], [DummyError.err0, DummyError.err1])
    }
    
    func test_flatMap_failure() {
        let alwaysFail = Parser { (stream) -> Reply<String> in
            return .failure([DummyError.err0])
        }
        let toInt = { (str: String) -> Parser<Int> in
            return Parser { (stream) -> Reply<Int> in
                XCTFail()
                return .success(Int(str)!, [DummyError.err1])
            }
        }
        let p = alwaysFail.flatMap(toInt)
        let stream = CharacterStream(string: "")
        let reply = p.parse(stream)
        if case let .failure(errors) = reply {
            XCTAssertEqual(errors as! [DummyError], [DummyError.err0])
        } else {
            XCTFail()
        }
    }
    
    func test_flatMap_fatalFailure() {
        let alwaysFail = Parser { (stream) -> Reply<String> in
            return .fatalFailure([DummyError.err0])
        }
        let toInt = { (str: String) -> Parser<Int> in
            return Parser { (stream) -> Reply<Int> in
                XCTFail()
                return .success(Int(str)!, [DummyError.err1])
            }
        }
        let p = alwaysFail.flatMap(toInt)
        let stream = CharacterStream(string: "")
        let reply = p.parse(stream)
        if case let .fatalFailure(errors) = reply {
            XCTAssertEqual(errors as! [DummyError], [DummyError.err0])
        } else {
            XCTFail()
        }
    }
    
    func test_map_success() {
        let numberString = Parser { (stream) -> Reply<String> in
            return .success("2", [DummyError.err0])
        }
        let toInt = { (str: String) -> Int in
            return Int(str)!
        }
        let p = numberString.map(toInt)
        let stream = CharacterStream(string: "")
        let reply = p.parse(stream)
        XCTAssertEqual(reply.value, 2)
    }
    
    func test_map_failure() {
        let alwaysFail = Parser { (stream) -> Reply<String> in
            return .failure([DummyError.err0])
        }
        let toInt = { (str: String) -> Int in
            XCTFail()
            return Int(str)!
        }
        let p = alwaysFail.map(toInt)
        let stream = CharacterStream(string: "")
        let reply = p.parse(stream)
        if case let .failure(errors) = reply {
            XCTAssertEqual(errors as! [DummyError], [DummyError.err0])
        } else {
            XCTFail()
        }
    }
    
    func test_run_whenSuccess_returnSuccess() {
        let parser = Parser { (_) -> Reply<Int> in
            return .success(7, [])
        }
        let result = parser.run("")
        if case .success(let v) = result {
            XCTAssertEqual(v, 7)
        } else {
            XCTFail()
        }
    }
    
    func test_run_whenFailure_returnFailure() {
        let underlyingErrors: [NSError] = [
            NSError(domain: "", code: 1, userInfo: nil)
        ]
        
        let parser = Parser { (_) -> Reply<Int> in
            return .failure(underlyingErrors)
        }
        
        let result = parser.run("")
        if case .failure(let e) = result {
            XCTAssertEqual(e.underlyingErrors as [NSError], underlyingErrors)
        } else {
            XCTFail()
        }
    }
    
    func test_run_whenFailure_returnFatalFailure() {
        let underlyingErrors: [NSError] = [
            NSError(domain: "", code: 1, userInfo: nil)
        ]
        
        let parser = Parser { (_) -> Reply<Int> in
            return .fatalFailure(underlyingErrors)
        }
        
        let result = parser.run("")
        if case .failure(let e) = result {
            XCTAssertEqual(e.underlyingErrors as [NSError], underlyingErrors)
        } else {
            XCTFail()
        }
    }
}



