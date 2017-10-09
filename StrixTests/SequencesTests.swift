
import XCTest
@testable import Strix

private func makeDefaultStream() -> CharacterStream {
    return CharacterStream(string: "")
}

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
        
        let reply2 = tuple(p1, p2).parse(makeDefaultStream())
        if case let .success(v, _) = reply2, v == ("1", 2) {
            
        } else {
            shouldNotEnterHere()
        }
        
        let reply3 = tuple(p1, p2, p3).parse(makeDefaultStream())
        if case let .success(v, _) = reply3, v == ("1", 2, "3") {
            
        } else {
            shouldNotEnterHere()
        }
        
        let reply4 = tuple(p1, p2, p3, p4).parse(makeDefaultStream())
        if case let .success(v, _) = reply4, v == ("1", 2, "3", 4) {
            
        } else {
            shouldNotEnterHere()
        }
        
        let reply5 = tuple(p1, p2, p3, p4, p5).parse(makeDefaultStream())
        if case let .success(v, _) = reply5, v == ("1", 2, "3", 4, "5") {
            
        } else {
            shouldNotEnterHere()
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
            let values = Array(1..<maxCount+1)
            let errors = values.map({ DummyError(rawValue: $0)! })
            checkSuccess(p.parse(makeDefaultStream()), values, errors, message)
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
            let values = Array(1..<maxCount+1)
            let errors = Array(values.map({ DummyError(rawValue: $0)! }).suffix(1))
            checkSuccess(p.parse(makeDefaultStream()), values, errors, message)
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
            if maxCount == 0 {
                checkSuccess(p.parse(makeDefaultStream()), [], [] as [DummyError], message)
            } else {
                let values = Array(1..<maxCount+1)
                let errors = values.map({ DummyError(rawValue: $0)! })
                checkFailure(p.parse(makeDefaultStream()), errors, message)
            }
        }
    }
    
    func test_array_whenParserFailure_returnFailure() {
        let p1 = Parser { stream -> Reply<Int> in
            return .failure([DummyError.err0])
        }
        let p: Parser<[Int]> = array(p1, count: 3)
        checkFailure(p.parse(makeDefaultStream()), [DummyError.err0])
    }
    
    func test_array_whenParserFatalFailure_returnFatalFailure() {
        let p1 = Parser { stream -> Reply<Int> in
            return .fatalFailure([DummyError.err0])
        }
        let p: Parser<[Int]> = array(p1, count: 3)
        checkFatalFailure(p.parse(makeDefaultStream()), [DummyError.err0])
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
            let errors = Array(1..<maxCount+1).map({ DummyError(rawValue: $0)! })
            checkSuccess(p.parse(makeDefaultStream()), errors, message)
        }
    }
    
    func test_skipArray_whenParserFailure_returnFailure() {
        let p1 = Parser { stream -> Reply<Int> in
            return .failure([DummyError.err0])
        }
        let p: Parser<Void> = skipArray(p1, count: 3)
        checkFailure(p.parse(makeDefaultStream()), [DummyError.err0])
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
            let values = Array(1..<maxCount)
            checkSuccess(p.parse(makeDefaultStream()), values, errors)
        }
        
        do {
            count = 0
            let p: Parser<Void> = skipMany(p1)
            checkSuccess(p.parse(makeDefaultStream()), errors)
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
            checkFatalFailure(p.parse(makeDefaultStream()), errors)
        }
        
        do {
            count = 0
            let p: Parser<Void> = skipMany(p1)
            checkFatalFailure(p.parse(makeDefaultStream()), errors)
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
            checkFailure(p.parse(makeDefaultStream()), errors)
        }
        
        do {
            count = 0
            let p: Parser<Void> = skipMany(p1)
            checkFailure(p.parse(makeDefaultStream()), errors)
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
            checkFatalFailure(p.parse(makeDefaultStream()), errors)
        }
        
        do {
            count = 0
            let p: Parser<Void> = skipMany(p1)
            checkFatalFailure(p.parse(makeDefaultStream()), errors)
        }
    }
    
    func test_many_whenNotRequireAtLeastOneAndFailAtFirst_returnSuccess() {
        let p1 = Parser { stream -> Reply<Int> in
            return .failure([DummyError.err0])
        }
        let errors = [DummyError.err0]
        
        do {
            let p: Parser<[Int]> = many(p1, atLeastOne: false)
            checkSuccess(p.parse(makeDefaultStream()), [], errors)
        }
        
        do {
            let p: Parser<Void> = skipMany(p1, atLeastOne: false)
            checkSuccess(p.parse(makeDefaultStream()), errors)
        }
    }
    
    func test_many_whenRequireAtLeastOneAndFailAtFirst_returnFailure() {
        let p1 = Parser { stream -> Reply<Int> in
            return .failure([DummyError.err0])
        }
        let errors = [DummyError.err0]
        
        do {
            let p: Parser<[Int]> = many(p1, atLeastOne: true)
            checkFailure(p.parse(makeDefaultStream()), errors)
        }
        
        do {
            let p: Parser<Void> = skipMany(p1, atLeastOne: true)
            checkFailure(p.parse(makeDefaultStream()), errors)
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
            _ = p.parse(makeDefaultStream())
            
            shouldNotEnterHere()
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
        
        let p: Parser<[Int]> = many(first: p1, repeating: p2)
        let values = Array(0..<maxCount)
        let errors = Array(Array(1..<maxCount+1).map({ DummyError(rawValue: $0)! }).suffix(2))
        checkSuccess(p.parse(makeDefaultStream()), values, errors)
    }
    
    func test_manyFirstRepeating_failure() {
        let p1 = Parser { stream -> Reply<Int> in
            stream.stateTag += 1
            return .failure([DummyError.err0])
        }
        
        let maxCount = 3
        var count = 0
        let p2 = Parser { stream -> Reply<Int> in
            shouldNotEnterHere()
            count += 1
            if count < maxCount {
                stream.stateTag += 1
                return .success(count, [DummyError(rawValue: count)!])
            }
            return .failure([DummyError(rawValue: count)!])
        }
        
        let p: Parser<[Int]> = many(first: p1, repeating: p2)
        checkFailure(p.parse(makeDefaultStream()), [DummyError.err0])
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
            let values = Array(1..<maxCount)
            checkSuccess(p.parse(makeDefaultStream()), values, errors)
        }
        
        do {
            valueCount = 0
            errorCount = 0
            let p: Parser<Void> = skipMany(p1, separator: p2,
                                           atLeastOne: false, allowEndBySeparator: false)
            checkSuccess(p.parse(makeDefaultStream()), errors)
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
            let values = Array(1..<maxCount)
            checkSuccess(p.parse(makeDefaultStream()), values, errors)
        }
        
        do {
            valueCount = 0
            errorCount = 0
            let p: Parser<Void> = skipMany(p1, separator: p2,
                                           atLeastOne: false, allowEndBySeparator: true)
            checkSuccess(p.parse(makeDefaultStream()), errors)
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
            checkFatalFailure(p.parse(makeDefaultStream()), errors)
        }
        
        do {
            valueCount = 0
            errorCount = 0
            let p: Parser<Void> = skipMany(p1, separator: p2,
                                           atLeastOne: false, allowEndBySeparator: false)
            checkFatalFailure(p.parse(makeDefaultStream()), errors)
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
            checkFatalFailure(p.parse(makeDefaultStream()), errors)
        }
        
        do {
            valueCount = 0
            errorCount = 0
            let p: Parser<Void> = skipMany(p1, separator: p2,
                                           atLeastOne: false, allowEndBySeparator: false)
            checkFatalFailure(p.parse(makeDefaultStream()), errors)
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
            checkFailure(p.parse(makeDefaultStream()), errors)
        }
        
        do {
            valueCount = 0
            errorCount = 0
            let p: Parser<Void> = skipMany(p1, separator: p2,
                                           atLeastOne: false, allowEndBySeparator: false)
            checkFailure(p.parse(makeDefaultStream()), errors)
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
            checkFailure(p.parse(makeDefaultStream()), errors)
        }
        
        do {
            valueCount = 0
            errorCount = 0
            let p: Parser<Void> = skipMany(p1, separator: p2,
                                           atLeastOne: false, allowEndBySeparator: false)
            checkFailure(p.parse(makeDefaultStream()), errors)
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
            checkFatalFailure(p.parse(makeDefaultStream()), errors)
        }
        
        do {
            valueCount = 0
            errorCount = 0
            let p: Parser<Void> = skipMany(p1, separator: p2,
                                           atLeastOne: false, allowEndBySeparator: false)
            checkFatalFailure(p.parse(makeDefaultStream()), errors)
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
            checkFatalFailure(p.parse(makeDefaultStream()), errors)
        }
        
        do {
            valueCount = 0
            errorCount = 0
            let p: Parser<Void> = skipMany(p1, separator: p2,
                                           atLeastOne: false, allowEndBySeparator: false)
            checkFatalFailure(p.parse(makeDefaultStream()), errors)
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
            shouldNotEnterHere()
            errorCount += 1
            stream.stateTag += 1
            return .success(", ", [DummyError(rawValue: errorCount)!])
        }
        
        let errors = [DummyError(rawValue: maxCount)!]
        
        do {
            let p: Parser<[Int]> = many(p1, separator: p2,
                                        atLeastOne: false, allowEndBySeparator: false)
            let values = Array(1..<maxCount)
            checkSuccess(p.parse(makeDefaultStream()), values, errors)
        }
        
        do {
            valueCount = 0
            errorCount = 0
            let p: Parser<Void> = skipMany(p1, separator: p2,
                                           atLeastOne: false, allowEndBySeparator: false)
            checkSuccess(p.parse(makeDefaultStream()), errors)
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
            shouldNotEnterHere()
            errorCount += 1
            stream.stateTag += 1
            return .success(", ", [DummyError(rawValue: errorCount)!])
        }
        
        let errors = [DummyError(rawValue: maxCount)!]
        
        do {
            let p: Parser<[Int]> = many(p1, separator: p2,
                                        atLeastOne: true, allowEndBySeparator: false)
            checkFailure(p.parse(makeDefaultStream()), errors)
        }
        
        do {
            valueCount = 0
            errorCount = 0
            let p: Parser<Void> = skipMany(p1, separator: p2,
                                           atLeastOne: true, allowEndBySeparator: false)
            checkFailure(p.parse(makeDefaultStream()), errors)
        }
    }
}



