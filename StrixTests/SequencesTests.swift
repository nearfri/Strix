
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
    
    func test_many_whenFailWithoutStateChange_returnSuccess() {
        let maxCount = 3
        var count = 0
        let p1 = Parser { stream -> Reply<Int> in
            count += 1
            if count < maxCount {
                stream.stateTag += 1
                return .success(count, [DummyError(rawValue: count)!])
            }
            return .failure([DummyError(rawValue: count)!])
        }
        let errors = Array(Array(1..<maxCount+1).map({ DummyError(rawValue: $0)! }).suffix(2))
        
        do {
            let p: Parser<[Int]> = many(p1)
            let reply = p.parse(CharacterStream(string: ""))
            if case let .success(v, e) = reply {
                let values = Array(1..<maxCount)
                XCTAssertEqual(v, values)
                XCTAssertEqual(e as! [DummyError], errors)
            } else {
                XCTFail()
            }
        }
        
        do {
            count = 0
            let p: Parser<Void> = skipMany(p1)
            let reply = p.parse(CharacterStream(string: ""))
            if case let .success(_, e) = reply {
                XCTAssertEqual(e as! [DummyError], errors)
            } else {
                XCTFail()
            }
        }
    }
    
    func test_many_whenFatalFailWithoutStateChange_returnFatalFailure() {
        let maxCount = 3
        var count = 0
        let p1 = Parser { stream -> Reply<Int> in
            count += 1
            if count < maxCount {
                stream.stateTag += 1
                return .success(count, [DummyError(rawValue: count)!])
            }
            return .fatalFailure([DummyError(rawValue: count)!])
        }
        let errors = Array(Array(1..<maxCount+1).map({ DummyError(rawValue: $0)! }).suffix(2))
        
        do {
            let p: Parser<[Int]> = many(p1)
            let reply = p.parse(CharacterStream(string: ""))
            if case let .fatalFailure(e) = reply {
                XCTAssertEqual(e as! [DummyError], errors)
            } else {
                XCTFail()
            }
        }
        
        do {
            count = 0
            let p: Parser<Void> = skipMany(p1)
            let reply = p.parse(CharacterStream(string: ""))
            if case let .fatalFailure(e) = reply {
                XCTAssertEqual(e as! [DummyError], errors)
            } else {
                XCTFail()
            }
        }
    }
    
    func test_many_whenFailWithStateChange_returnFailure() {
        let maxCount = 3
        var count = 0
        let p1 = Parser { stream -> Reply<Int> in
            count += 1
            stream.stateTag += 1
            if count < maxCount {
                return .success(count, [DummyError(rawValue: count)!])
            }
            return .failure([DummyError(rawValue: count)!])
        }
        let errors = [DummyError(rawValue: maxCount)!]
        
        do {
            let p: Parser<[Int]> = many(p1)
            let reply = p.parse(CharacterStream(string: ""))
            if case let .failure(e) = reply {
                XCTAssertEqual(e as! [DummyError], errors)
            } else {
                XCTFail()
            }
        }
        
        do {
            count = 0
            let p: Parser<Void> = skipMany(p1)
            let reply = p.parse(CharacterStream(string: ""))
            if case let .failure(e) = reply {
                XCTAssertEqual(e as! [DummyError], errors)
            } else {
                XCTFail()
            }
        }
    }
    
    func test_many_whenFatalFailWithStateChange_returnFatalFailure() {
        let maxCount = 3
        var count = 0
        let p1 = Parser { stream -> Reply<Int> in
            count += 1
            stream.stateTag += 1
            if count < maxCount {
                return .success(count, [DummyError(rawValue: count)!])
            }
            return .fatalFailure([DummyError(rawValue: count)!])
        }
        let errors = [DummyError(rawValue: maxCount)!]
        
        do {
            let p: Parser<[Int]> = many(p1)
            let reply = p.parse(CharacterStream(string: ""))
            if case let .fatalFailure(e) = reply {
                XCTAssertEqual(e as! [DummyError], errors)
            } else {
                XCTFail()
            }
        }
        
        do {
            count = 0
            let p: Parser<Void> = skipMany(p1)
            let reply = p.parse(CharacterStream(string: ""))
            if case let .fatalFailure(e) = reply {
                XCTAssertEqual(e as! [DummyError], errors)
            } else {
                XCTFail()
            }
        }
    }
    
    func test_many_whenNotRequireAtLeastOneAndFailAtFirst_returnSuccess() {
        let p1 = Parser { stream -> Reply<Int> in
            return .failure([DummyError.err0])
        }
        let errors = [DummyError.err0]
        
        do {
            let p: Parser<[Int]> = many(p1, atLeastOne: false)
            let reply = p.parse(CharacterStream(string: ""))
            if case let .success(v, e) = reply {
                XCTAssertTrue(v.isEmpty)
                XCTAssertEqual(e as! [DummyError], errors)
            } else {
                XCTFail()
            }
        }
        
        do {
            let p: Parser<Void> = skipMany(p1, atLeastOne: false)
            let reply = p.parse(CharacterStream(string: ""))
            if case let .success(_, e) = reply {
                XCTAssertEqual(e as! [DummyError], errors)
            } else {
                XCTFail()
            }
        }
    }
    
    func test_many_whenRequireAtLeastOneAndFailAtFirst_returnFailure() {
        let p1 = Parser { stream -> Reply<Int> in
            return .failure([DummyError.err0])
        }
        let errors = [DummyError.err0]
        
        do {
            let p: Parser<[Int]> = many(p1, atLeastOne: true)
            let reply = p.parse(CharacterStream(string: ""))
            if case let .failure(e) = reply {
                XCTAssertEqual(e as! [DummyError], errors)
            } else {
                XCTFail()
            }
        }
        
        do {
            let p: Parser<Void> = skipMany(p1, atLeastOne: true)
            let reply = p.parse(CharacterStream(string: ""))
            if case let .failure(e) = reply {
                XCTAssertEqual(e as! [DummyError], errors)
            } else {
                XCTFail()
            }
        }
    }
    
    // 현재로선 preconditionFailure를 catch하긴 번거로우므로 생략
    func _test_many_whenSuccessWithoutStateChange_preconditionFailure() {
        let maxCount = 3
        var count = 0
        let p1 = Parser { stream -> Reply<Int> in
            count += 1
            if count < maxCount {
                return .success(count, [DummyError(rawValue: count)!])
            }
            return .failure([DummyError(rawValue: count)!])
        }
        
        do {
            let p: Parser<[Int]> = many(p1)
            _ = p.parse(CharacterStream(string: ""))
            
            XCTFail("should not enter here")
            throw DummyError.err0
        } catch {
            
        }
    }
    
    func test_manyFirstRepeating_success() {
        let p1 = Parser { stream -> Reply<Int> in
            return .success(0, [DummyError.err0])
        }
        
        let maxCount = 3
        var count = 0
        let p2 = Parser { stream -> Reply<Int> in
            count += 1
            if count < maxCount {
                stream.stateTag += 1
                return .success(count, [DummyError(rawValue: count)!])
            }
            return .failure([DummyError(rawValue: count)!])
        }
        let errors = Array(Array(1..<maxCount+1).map({ DummyError(rawValue: $0)! }).suffix(2))
        
        let p: Parser<[Int]> = many(first: p1, repeating: p2)
        let reply = p.parse(CharacterStream(string: ""))
        if case let .success(v, e) = reply {
            let values = Array(0..<maxCount)
            XCTAssertEqual(v, values)
            XCTAssertEqual(e as! [DummyError], errors)
        } else {
            XCTFail()
        }
    }
    
    func test_manyFirstRepeating_failure() {
        let p1 = Parser { stream -> Reply<Int> in
            stream.stateTag += 1
            return .failure([DummyError.err0])
        }
        
        let maxCount = 3
        var count = 0
        let p2 = Parser { stream -> Reply<Int> in
            XCTFail("should not enter here")
            count += 1
            if count < maxCount {
                stream.stateTag += 1
                return .success(count, [DummyError(rawValue: count)!])
            }
            return .failure([DummyError(rawValue: count)!])
        }
        
        let p: Parser<[Int]> = many(first: p1, repeating: p2)
        let reply = p.parse(CharacterStream(string: ""))
        if case let .failure(e) = reply {
            XCTAssertEqual(e as! [DummyError], [DummyError.err0])
        } else {
            XCTFail()
        }
    }
    
    func test_manySeparator_whenSeparatorFailWithoutStateChange_returnSuccess() {
        let maxCount = 3
        var valueCount = 0
        var errorCount = 0
        let p1 = Parser { stream -> Reply<Int> in
            valueCount += 1
            errorCount += 1
            stream.stateTag += 1
            return .success(valueCount, [DummyError(rawValue: errorCount)!])
        }
        
        let p2 = Parser { stream -> Reply<String> in
            errorCount += 1
            if valueCount < maxCount - 1 {
                stream.stateTag += 1
                return .success(", ", [DummyError(rawValue: errorCount)!])
            }
            return .failure([DummyError(rawValue: errorCount)!])
        }
        
        let errors = Array(Array(1..<maxCount * 2 - 1).map({ DummyError(rawValue: $0)! }).suffix(2))
        
        do {
            let p: Parser<[Int]> = many(p1, separator: p2,
                                        atLeastOne: true, allowEndBySeparator: false)
            let reply = p.parse(CharacterStream(string: ""))
            if case let .success(v, e) = reply {
                let values = Array(1..<maxCount)
                XCTAssertEqual(v, values)
                XCTAssertEqual(e as! [DummyError], errors)
            } else {
                XCTFail()
            }
        }
        
        do {
            valueCount = 0
            errorCount = 0
            let p: Parser<Void> = skipMany(p1, separator: p2,
                                           atLeastOne: false, allowEndBySeparator: false)
            let reply = p.parse(CharacterStream(string: ""))
            if case let .success(_, e) = reply {
                XCTAssertEqual(e as! [DummyError], errors)
            } else {
                XCTFail()
            }
        }
    }
    
    func test_manySeparator_whenParserFailWithoutStateChange_returnSuccess() {
        let maxCount = 3
        var valueCount = 0
        var errorCount = 0
        let p1 = Parser { stream -> Reply<Int> in
            valueCount += 1
            errorCount += 1
            if valueCount < maxCount {
                stream.stateTag += 1
                return .success(valueCount, [DummyError(rawValue: errorCount)!])
            }
            return .failure([DummyError(rawValue: errorCount)!])
        }
        
        let p2 = Parser { stream -> Reply<String> in
            errorCount += 1
            stream.stateTag += 1
            return .success(", ", [DummyError(rawValue: errorCount)!])
        }
        
        let errors = Array(Array(1..<maxCount * 2).map({ DummyError(rawValue: $0)! }).suffix(2))
        
        do {
            let p: Parser<[Int]> = many(p1, separator: p2,
                                        atLeastOne: true, allowEndBySeparator: true)
            let reply = p.parse(CharacterStream(string: ""))
            if case let .success(v, e) = reply {
                let values = Array(1..<maxCount)
                XCTAssertEqual(v, values)
                XCTAssertEqual(e as! [DummyError], errors)
            } else {
                XCTFail()
            }
        }
        
        do {
            valueCount = 0
            errorCount = 0
            let p: Parser<Void> = skipMany(p1, separator: p2,
                                           atLeastOne: false, allowEndBySeparator: true)
            let reply = p.parse(CharacterStream(string: ""))
            if case let .success(_, e) = reply {
                XCTAssertEqual(e as! [DummyError], errors)
            } else {
                XCTFail()
            }
        }
    }
    
    func test_manySeparator_whenSeparatorFatalFailWithoutStateChange_returnFatalFailure() {
        let maxCount = 3
        var valueCount = 0
        var errorCount = 0
        let p1 = Parser { stream -> Reply<Int> in
            valueCount += 1
            errorCount += 1
            stream.stateTag += 1
            return .success(valueCount, [DummyError(rawValue: errorCount)!])
        }
        
        let p2 = Parser { stream -> Reply<String> in
            errorCount += 1
            if valueCount < maxCount - 1 {
                stream.stateTag += 1
                return .success(", ", [DummyError(rawValue: errorCount)!])
            }
            return .fatalFailure([DummyError(rawValue: errorCount)!])
        }
        
        let errors = Array(Array(1..<maxCount * 2 - 1).map({ DummyError(rawValue: $0)! }).suffix(2))
        
        do {
            let p: Parser<[Int]> = many(p1, separator: p2,
                                        atLeastOne: false, allowEndBySeparator: false)
            let reply = p.parse(CharacterStream(string: ""))
            if case let .fatalFailure(e) = reply {
                XCTAssertEqual(e as! [DummyError], errors)
            } else {
                XCTFail()
            }
        }
        
        do {
            valueCount = 0
            errorCount = 0
            let p: Parser<Void> = skipMany(p1, separator: p2,
                                           atLeastOne: false, allowEndBySeparator: false)
            let reply = p.parse(CharacterStream(string: ""))
            if case let .fatalFailure(e) = reply {
                XCTAssertEqual(e as! [DummyError], errors)
            } else {
                XCTFail()
            }
        }
    }
    
    func test_manySeparator_whenParserFatalFailWithoutStateChange_returnFatalFailure() {
        let maxCount = 3
        var valueCount = 0
        var errorCount = 0
        let p1 = Parser { stream -> Reply<Int> in
            valueCount += 1
            errorCount += 1
            if valueCount < maxCount {
                stream.stateTag += 1
                return .success(valueCount, [DummyError(rawValue: errorCount)!])
            }
            return .fatalFailure([DummyError(rawValue: errorCount)!])
        }
        
        let p2 = Parser { stream -> Reply<String> in
            errorCount += 1
            stream.stateTag += 1
            return .success(", ", [DummyError(rawValue: errorCount)!])
        }
        
        let errors = Array(Array(1..<maxCount * 2).map({ DummyError(rawValue: $0)! }).suffix(2))
        
        do {
            let p: Parser<[Int]> = many(p1, separator: p2,
                                        atLeastOne: false, allowEndBySeparator: false)
            let reply = p.parse(CharacterStream(string: ""))
            if case let .fatalFailure(e) = reply {
                XCTAssertEqual(e as! [DummyError], errors)
            } else {
                XCTFail()
            }
        }
        
        do {
            valueCount = 0
            errorCount = 0
            let p: Parser<Void> = skipMany(p1, separator: p2,
                                           atLeastOne: false, allowEndBySeparator: false)
            let reply = p.parse(CharacterStream(string: ""))
            if case let .fatalFailure(e) = reply {
                XCTAssertEqual(e as! [DummyError], errors)
            } else {
                XCTFail()
            }
        }
    }
    
    func test_manySeparator_whenSeparatorFailWithStateChange_returnFailure() {
        let maxCount = 3
        var valueCount = 0
        var errorCount = 0
        let p1 = Parser { stream -> Reply<Int> in
            valueCount += 1
            errorCount += 1
            stream.stateTag += 1
            return .success(valueCount, [DummyError(rawValue: errorCount)!])
        }
        
        let p2 = Parser { stream -> Reply<String> in
            errorCount += 1
            stream.stateTag += 1
            if valueCount < maxCount - 1 {
                return .success(", ", [DummyError(rawValue: errorCount)!])
            }
            return .failure([DummyError(rawValue: errorCount)!])
        }
        
        let errors = [DummyError(rawValue: (maxCount - 1) * 2)!]
        
        do {
            let p: Parser<[Int]> = many(p1, separator: p2,
                                        atLeastOne: false, allowEndBySeparator: false)
            let reply = p.parse(CharacterStream(string: ""))
            if case let .failure(e) = reply {
                XCTAssertEqual(e as! [DummyError], errors)
            } else {
                XCTFail()
            }
        }
        
        do {
            valueCount = 0
            errorCount = 0
            let p: Parser<Void> = skipMany(p1, separator: p2,
                                           atLeastOne: false, allowEndBySeparator: false)
            let reply = p.parse(CharacterStream(string: ""))
            if case let .failure(e) = reply {
                XCTAssertEqual(e as! [DummyError], errors)
            } else {
                XCTFail()
            }
        }
    }
    
    func test_manySeparator_whenParserFailWithStateChange_returnFailure() {
        let maxCount = 3
        var valueCount = 0
        var errorCount = 0
        let p1 = Parser { stream -> Reply<Int> in
            valueCount += 1
            errorCount += 1
            stream.stateTag += 1
            if valueCount < maxCount {
                return .success(valueCount, [DummyError(rawValue: errorCount)!])
            }
            return .failure([DummyError(rawValue: errorCount)!])
        }
        
        let p2 = Parser { stream -> Reply<String> in
            errorCount += 1
            stream.stateTag += 1
            return .success(", ", [DummyError(rawValue: errorCount)!])
        }
        
        let errors = [DummyError(rawValue: maxCount * 2 - 1)!]
        
        do {
            let p: Parser<[Int]> = many(p1, separator: p2,
                                        atLeastOne: false, allowEndBySeparator: false)
            let reply = p.parse(CharacterStream(string: ""))
            if case let .failure(e) = reply {
                XCTAssertEqual(e as! [DummyError], errors)
            } else {
                XCTFail()
            }
        }
        
        do {
            valueCount = 0
            errorCount = 0
            let p: Parser<Void> = skipMany(p1, separator: p2,
                                           atLeastOne: false, allowEndBySeparator: false)
            let reply = p.parse(CharacterStream(string: ""))
            if case let .failure(e) = reply {
                XCTAssertEqual(e as! [DummyError], errors)
            } else {
                XCTFail()
            }
        }
    }
    
    func test_manySeparator_whenSeparatorFatalFailWithStateChange_returnFatalFailure() {
        let maxCount = 3
        var valueCount = 0
        var errorCount = 0
        let p1 = Parser { stream -> Reply<Int> in
            valueCount += 1
            errorCount += 1
            stream.stateTag += 1
            return .success(valueCount, [DummyError(rawValue: errorCount)!])
        }
        
        let p2 = Parser { stream -> Reply<String> in
            errorCount += 1
            stream.stateTag += 1
            if valueCount < maxCount - 1 {
                return .success(", ", [DummyError(rawValue: errorCount)!])
            }
            return .fatalFailure([DummyError(rawValue: errorCount)!])
        }
        
        let errors = [DummyError(rawValue: (maxCount - 1) * 2)!]
        
        do {
            let p: Parser<[Int]> = many(p1, separator: p2,
                                        atLeastOne: false, allowEndBySeparator: false)
            let reply = p.parse(CharacterStream(string: ""))
            if case let .fatalFailure(e) = reply {
                XCTAssertEqual(e as! [DummyError], errors)
            } else {
                XCTFail()
            }
        }
        
        do {
            valueCount = 0
            errorCount = 0
            let p: Parser<Void> = skipMany(p1, separator: p2,
                                           atLeastOne: false, allowEndBySeparator: false)
            let reply = p.parse(CharacterStream(string: ""))
            if case let .fatalFailure(e) = reply {
                XCTAssertEqual(e as! [DummyError], errors)
            } else {
                XCTFail()
            }
        }
    }
    
    func test_manySeparator_whenParserFatalFailWithStateChange_returnFatalFailure() {
        let maxCount = 3
        var valueCount = 0
        var errorCount = 0
        let p1 = Parser { stream -> Reply<Int> in
            valueCount += 1
            errorCount += 1
            stream.stateTag += 1
            if valueCount < maxCount {
                return .success(valueCount, [DummyError(rawValue: errorCount)!])
            }
            return .fatalFailure([DummyError(rawValue: errorCount)!])
        }
        
        let p2 = Parser { stream -> Reply<String> in
            errorCount += 1
            stream.stateTag += 1
            return .success(", ", [DummyError(rawValue: errorCount)!])
        }
        
        let errors = [DummyError(rawValue: maxCount * 2 - 1)!]
        
        do {
            let p: Parser<[Int]> = many(p1, separator: p2,
                                        atLeastOne: false, allowEndBySeparator: false)
            let reply = p.parse(CharacterStream(string: ""))
            if case let .fatalFailure(e) = reply {
                XCTAssertEqual(e as! [DummyError], errors)
            } else {
                XCTFail()
            }
        }
        
        do {
            valueCount = 0
            errorCount = 0
            let p: Parser<Void> = skipMany(p1, separator: p2,
                                           atLeastOne: false, allowEndBySeparator: false)
            let reply = p.parse(CharacterStream(string: ""))
            if case let .fatalFailure(e) = reply {
                XCTAssertEqual(e as! [DummyError], errors)
            } else {
                XCTFail()
            }
        }
    }
    
    func test_manySeparator_whenParserFailAtFirstWithoutStateChange_returnSuccess() {
        let maxCount = 1
        var valueCount = 0
        var errorCount = 0
        let p1 = Parser { stream -> Reply<Int> in
            valueCount += 1
            errorCount += 1
            return .failure([DummyError(rawValue: errorCount)!])
        }
        
        let p2 = Parser { stream -> Reply<String> in
            XCTFail("should not enter here")
            errorCount += 1
            stream.stateTag += 1
            return .success(", ", [DummyError(rawValue: errorCount)!])
        }
        
        let errors = [DummyError(rawValue: maxCount)!]
        
        do {
            let p: Parser<[Int]> = many(p1, separator: p2,
                                        atLeastOne: false, allowEndBySeparator: false)
            let reply = p.parse(CharacterStream(string: ""))
            if case let .success(v, e) = reply {
                let values = Array(1..<maxCount)
                XCTAssertEqual(v, values)
                XCTAssertEqual(e as! [DummyError], errors)
            } else {
                XCTFail()
            }
        }
        
        do {
            valueCount = 0
            errorCount = 0
            let p: Parser<Void> = skipMany(p1, separator: p2,
                                           atLeastOne: false, allowEndBySeparator: false)
            let reply = p.parse(CharacterStream(string: ""))
            if case let .success(_, e) = reply {
                XCTAssertEqual(e as! [DummyError], errors)
            } else {
                XCTFail()
            }
        }
    }
    
    func test_manySeparator_atLeastOne_whenParserFailAtFirstWithoutStateChange_returnFailure() {
        let maxCount = 1
        var valueCount = 0
        var errorCount = 0
        let p1 = Parser { stream -> Reply<Int> in
            valueCount += 1
            errorCount += 1
            return .failure([DummyError(rawValue: errorCount)!])
        }
        
        let p2 = Parser { stream -> Reply<String> in
            XCTFail("should not enter here")
            errorCount += 1
            stream.stateTag += 1
            return .success(", ", [DummyError(rawValue: errorCount)!])
        }
        
        let errors = [DummyError(rawValue: maxCount)!]
        
        do {
            let p: Parser<[Int]> = many(p1, separator: p2,
                                        atLeastOne: true, allowEndBySeparator: false)
            let reply = p.parse(CharacterStream(string: ""))
            if case let .failure(e) = reply {
                XCTAssertEqual(e as! [DummyError], errors)
            } else {
                XCTFail()
            }
        }
        
        do {
            valueCount = 0
            errorCount = 0
            let p: Parser<Void> = skipMany(p1, separator: p2,
                                           atLeastOne: true, allowEndBySeparator: false)
            let reply = p.parse(CharacterStream(string: ""))
            if case let .failure(e) = reply {
                XCTAssertEqual(e as! [DummyError], errors)
            } else {
                XCTFail()
            }
        }
    }
}



