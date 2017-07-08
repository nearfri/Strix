
import XCTest
@testable import Strix

class SequencesTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func test_tuple2_success() {
        let p1 = Parser { _ -> Reply<String> in
            return .success("1", [])
        }
        let p2 = Parser { _ -> Reply<Int> in
            return .success(2, [])
        }
        let p3 = Parser { _ -> Reply<String> in
            return .success("3", [])
        }
        let p4 = Parser { _ -> Reply<Int> in
            return .success(4, [])
        }
        let p5 = Parser { _ -> Reply<String> in
            return .success("5", [])
        }
        
        let reply2 = tuple(p1, p2).parse(CharacterStream(string: ""))
        if case let .success(v, _) = reply2, v == ("1", 2) {
            
        } else {
            XCTFail()
        }
        
        let reply3 = tuple(p1, p2, p3).parse(CharacterStream(string: ""))
        if case let .success(v, _) = reply3, v == ("1", 2, "3") {
            
        } else {
            XCTFail()
        }
        
        let reply4 = tuple(p1, p2, p3, p4).parse(CharacterStream(string: ""))
        if case let .success(v, _) = reply4, v == ("1", 2, "3", 4) {
            
        } else {
            XCTFail()
        }
        
        let reply5 = tuple(p1, p2, p3, p4, p5).parse(CharacterStream(string: ""))
        if case let .success(v, _) = reply5, v == ("1", 2, "3", 4, "5") {
            
        } else {
            XCTFail()
        }
    }
    
    func test_array_whenParserSuccessEnoughWithoutStateChange_returnSuccessWithAllErrors() {
        for maxCount in 0..<3 {
            let message = "when maxCount is \(maxCount)"
            var count = 0
            let p1 = Parser { _ -> Reply<Int> in
                count += 1
                return .success(count, [DummyError(rawValue: count)!])
            }
            let p: Parser<[Int]> = array(p1, count: maxCount)
            let reply = p.parse(CharacterStream(string: ""))
            if case let .success(v, e) = reply {
                let values = Array(1..<maxCount+1)
                let errors = values.map({ DummyError(rawValue: $0)! })
                XCTAssertEqual(v, values, message)
                XCTAssertEqual(e as! [DummyError], errors, message)
            } else {
                XCTFail()
            }
        }
    }
    
    func test_array_whenParserSuccessEnoughWithStateChange_returnSuccessWithLastError() {
        for maxCount in 0..<3 {
            let message = "when maxCount is \(maxCount)"
            var count = 0
            let p1 = Parser { stream -> Reply<Int> in
                count += 1
                stream.stateTag += 1
                return .success(count, [DummyError(rawValue: count)!])
            }
            let p: Parser<[Int]> = array(p1, count: maxCount)
            let reply = p.parse(CharacterStream(string: ""))
            if case let .success(v, e) = reply {
                let values = Array(1..<maxCount+1)
                let errors = Array(values.map({ DummyError(rawValue: $0)! }).suffix(1))
                XCTAssertEqual(v, values)
                XCTAssertEqual(e as! [DummyError], errors, message)
            } else {
                XCTFail()
            }
        }
    }
    
    func test_array_whenParserSuccessNotEnough_returnFailure() {
        for maxCount in 0..<3 {
            let message = "when maxCount is \(maxCount)"
            var count = 0
            let p1 = Parser { _ -> Reply<Int> in
                count += 1
                if count == maxCount {
                    return .failure([DummyError(rawValue: count)!])
                }
                return .success(count, [DummyError(rawValue: count)!])
            }
            let p: Parser<[Int]> = array(p1, count: maxCount)
            let reply = p.parse(CharacterStream(string: ""))
            if maxCount == 0 {
                if case let .success(v, e) = reply {
                    XCTAssertTrue(v.isEmpty, message)
                    XCTAssertTrue(e.isEmpty, message)
                }
            } else {
                if case let .failure(e) = reply {
                    let values = Array(1..<maxCount+1)
                    let errors = values.map({ DummyError(rawValue: $0)! })
                    XCTAssertEqual(e as! [DummyError], errors, message)
                } else {
                    XCTFail(message)
                }
            }
        }
    }
    
    func test_array_whenParserFailure_returnFailure() {
        let p1 = Parser { stream -> Reply<Int> in
            return .failure([DummyError.err0])
        }
        let p: Parser<[Int]> = array(p1, count: 3)
        let reply = p.parse(CharacterStream(string: ""))
        if case let .failure(e) = reply {
            XCTAssertEqual(e as! [DummyError], [DummyError.err0])
        } else {
            XCTFail()
        }
    }
    
    func test_array_whenParserFatalFailure_returnFatalFailure() {
        let p1 = Parser { stream -> Reply<Int> in
            return .fatalFailure([DummyError.err0])
        }
        let p: Parser<[Int]> = array(p1, count: 3)
        let reply = p.parse(CharacterStream(string: ""))
        if case let .fatalFailure(e) = reply {
            XCTAssertEqual(e as! [DummyError], [DummyError.err0])
        } else {
            XCTFail()
        }
    }
    
    func test_skipArray_whenParserSuccess_returnSuccess() {
        for maxCount in 0..<3 {
            let message = "when maxCount is \(maxCount)"
            var count = 0
            let p1 = Parser { _ -> Reply<Int> in
                count += 1
                return .success(count, [DummyError(rawValue: count)!])
            }
            let p: Parser<Void> = skipArray(p1, count: maxCount)
            let reply = p.parse(CharacterStream(string: ""))
            if case let .success(_, e) = reply {
                let errors = Array(1..<maxCount+1).map({ DummyError(rawValue: $0)! })
                XCTAssertEqual(e as! [DummyError], errors, message)
            } else {
                XCTFail()
            }
        }
    }
    
    func test_skipArray_whenParserFailure_returnFailure() {
        let p1 = Parser { stream -> Reply<Int> in
            return .failure([DummyError.err0])
        }
        let p: Parser<Void> = skipArray(p1, count: 3)
        let reply = p.parse(CharacterStream(string: ""))
        if case let .failure(e) = reply {
            XCTAssertEqual(e as! [DummyError], [DummyError.err0])
        } else {
            XCTFail()
        }
    }
}



