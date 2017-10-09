
import XCTest
@testable import Strix

class ParserTests: XCTestCase {
    var defaultStream: CharacterStream = CharacterStream(string: "")
    
    override func setUp() {
        super.setUp()
        defaultStream = CharacterStream(string: "")
    }
    
    override func tearDown() {
        super.tearDown()
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
        checkSuccess(p.parse(defaultStream), 1, [DummyError.err0, DummyError.err1])
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
        checkSuccess(p.parse(defaultStream), 1, [DummyError.err1])
    }
    
    func test_flatMap_failure() {
        let alwaysFail = Parser { (stream) -> Reply<String> in
            return .failure([DummyError.err0])
        }
        let toInt = { (str: String) -> Parser<Int> in
            return Parser { (stream) -> Reply<Int> in
                shouldNotEnterHere()
                return .success(Int(str)!, [DummyError.err1])
            }
        }
        let p = alwaysFail.flatMap(toInt)
        checkFailure(p.parse(defaultStream), [DummyError.err0])
    }
    
    func test_flatMap_fatalFailure() {
        let alwaysFail = Parser { (stream) -> Reply<String> in
            return .fatalFailure([DummyError.err0])
        }
        let toInt = { (str: String) -> Parser<Int> in
            return Parser { (stream) -> Reply<Int> in
                shouldNotEnterHere()
                return .success(Int(str)!, [DummyError.err1])
            }
        }
        let p = alwaysFail.flatMap(toInt)
        checkFatalFailure(p.parse(defaultStream), [DummyError.err0])
    }
    
    func test_map_success() {
        let numberString = Parser { (stream) -> Reply<String> in
            return .success("1", [DummyError.err0])
        }
        let toInt = { (str: String) -> Int in
            return Int(str)!
        }
        let p = numberString.map(toInt)
        checkSuccess(p.parse(defaultStream), 1, [DummyError.err0])
    }
    
    func test_map_failure() {
        let alwaysFail = Parser { (stream) -> Reply<String> in
            return .failure([DummyError.err0])
        }
        let toInt = { (str: String) -> Int in
            shouldNotEnterHere()
            return Int(str)!
        }
        let p = alwaysFail.map(toInt)
        checkFailure(p.parse(defaultStream), [DummyError.err0])
    }
    
    func test_run_whenSuccess_returnSuccess() {
        let parser = Parser { (_) -> Reply<Int> in
            return .success(7, [])
        }
        checkSuccess(parser.run(""), 7)
    }
    
    func test_run_whenFailure_returnFailure() {
        let underlyingErrors = [DummyError.err0]
        let parser = Parser { (_) -> Reply<Int> in
            return .failure(underlyingErrors)
        }
        checkFailure(parser.run(""), underlyingErrors)
    }
    
    func test_run_whenFatalFailure_returnFailure() {
        let underlyingErrors = [DummyError.err0]
        let parser = Parser { (_) -> Reply<Int> in
            return .fatalFailure(underlyingErrors)
        }
        checkFailure(parser.run(""), underlyingErrors)
    }
}



