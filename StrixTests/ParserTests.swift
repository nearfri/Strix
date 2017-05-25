
import XCTest
@testable import Strix

class ParserTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func test_flatMap_success() {
        let numberString = Parser { (stream) -> Reply<String> in
            return .success("1", [DummyError.err0])
        }
        let toInt = { (str: String) -> Parser<Int> in
            return Parser { (stream) -> Reply<Int> in
                return .success(Int(str)!, [DummyError.err1])
            }
        }
        let p = numberString.flatMap(toInt)
        let stream = CharacterStream(string: "")
        let reply = p.parse(stream)
        XCTAssertEqual(reply.value, 1)
    }
    
    func test_flatMap_whenChangesStateTag_notPrependingErrors() {
        let numberString = Parser { (stream) -> Reply<String> in
            return .success("1", [DummyError.err0])
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
            return .success("1", [DummyError.err0])
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
        var passed = false
        if case let .failure(errors) = reply {
            XCTAssertEqual(errors as! [DummyError], [DummyError.err0])
            passed = true
        }
        XCTAssertTrue(passed)
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
        var passed = false
        if case let .fatalFailure(errors) = reply {
            XCTAssertEqual(errors as! [DummyError], [DummyError.err0])
            passed = true
        }
        XCTAssertTrue(passed)
    }
    
    func test_map_success() {
        let numberString = Parser { (stream) -> Reply<String> in
            return .success("1", [DummyError.err0])
        }
        let toInt = { (str: String) -> Int in
            return Int(str)!
        }
        let p = numberString.map(toInt)
        let stream = CharacterStream(string: "")
        let reply = p.parse(stream)
        XCTAssertEqual(reply.value, 1)
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
        var passed = false
        if case let .failure(errors) = reply {
            XCTAssertEqual(errors as! [DummyError], [DummyError.err0])
            passed = true
        }
        XCTAssertTrue(passed)
    }
    
    func test_run_whenSuccess_returnSuccess() {
        let parser = Parser { (_) -> Reply<Int> in
            return .success(7, [])
        }
        let result = parser.run("")
        var passed = false
        if case .success(let v) = result {
            XCTAssertEqual(v, 7)
            passed = true
        }
        XCTAssertTrue(passed)
    }
    
    func test_run_whenFailure_returnFailure() {
        let underlyingErrors: [DummyError] = [
            DummyError.err0
        ]
        
        let parser = Parser { (_) -> Reply<Int> in
            return .failure(underlyingErrors)
        }
        
        let result = parser.run("")
        var passed = false
        if case .failure(let e) = result {
            XCTAssertEqual(e.underlyingErrors as! [DummyError], underlyingErrors)
            passed = true
        }
        XCTAssertTrue(passed)
    }
    
    func test_run_whenFailure_returnFatalFailure() {
        let underlyingErrors: [DummyError] = [
            DummyError.err0
        ]
        
        let parser = Parser { (_) -> Reply<Int> in
            return .fatalFailure(underlyingErrors)
        }
        
        let result = parser.run("")
        var passed = false
        if case .failure(let e) = result {
            XCTAssertEqual(e.underlyingErrors as! [DummyError], underlyingErrors)
            passed = true
        }
        XCTAssertTrue(passed)
    }
}



