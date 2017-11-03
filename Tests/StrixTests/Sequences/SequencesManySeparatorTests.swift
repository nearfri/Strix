
import XCTest
@testable import Strix

class SequencesManySeparatorTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
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
            checkSuccess(p.parse(makeEmptyStream()), values, errors)
        }
        
        do {
            valueCount = 0
            errorCount = 0
            let p: Parser<Void> = skipMany(p1, separator: p2,
                                           atLeastOne: false, allowEndBySeparator: false)
            checkSuccess(p.parse(makeEmptyStream()), errors)
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
            checkSuccess(p.parse(makeEmptyStream()), values, errors)
        }
        
        do {
            valueCount = 0
            errorCount = 0
            let p: Parser<Void> = skipMany(p1, separator: p2,
                                           atLeastOne: false, allowEndBySeparator: true)
            checkSuccess(p.parse(makeEmptyStream()), errors)
        }
    }
    
    func test_manySeparator_whenParserSuccessWithoutStateChange_returnSuccess() {
        let maxCount = 3
        var valueCount = 0
        var errorCount = 0
        let p1 = Parser { stream -> Reply<Int> in
            valueCount += 1
            errorCount += 1
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
        
        let errors = Array(Array(1..<maxCount * 2).map({ DummyError(rawValue: $0)! }).suffix(2))
        
        do {
            let p: Parser<[Int]> = many(p1, separator: p2,
                                        atLeastOne: true, allowEndBySeparator: true)
            let values = Array(1..<maxCount)
            checkSuccess(p.parse(makeEmptyStream()), values, errors)
        }
        
        do {
            valueCount = 0
            errorCount = 0
            let p: Parser<Void> = skipMany(p1, separator: p2,
                                           atLeastOne: false, allowEndBySeparator: true)
            checkSuccess(p.parse(makeEmptyStream()), errors)
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
            checkFatalFailure(p.parse(makeEmptyStream()), errors)
        }
        
        do {
            valueCount = 0
            errorCount = 0
            let p: Parser<Void> = skipMany(p1, separator: p2,
                                           atLeastOne: false, allowEndBySeparator: false)
            checkFatalFailure(p.parse(makeEmptyStream()), errors)
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
            checkFatalFailure(p.parse(makeEmptyStream()), errors)
        }
        
        do {
            valueCount = 0
            errorCount = 0
            let p: Parser<Void> = skipMany(p1, separator: p2,
                                           atLeastOne: false, allowEndBySeparator: false)
            checkFatalFailure(p.parse(makeEmptyStream()), errors)
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
            checkFailure(p.parse(makeEmptyStream()), errors)
        }
        
        do {
            valueCount = 0
            errorCount = 0
            let p: Parser<Void> = skipMany(p1, separator: p2,
                                           atLeastOne: false, allowEndBySeparator: false)
            checkFailure(p.parse(makeEmptyStream()), errors)
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
            checkFailure(p.parse(makeEmptyStream()), errors)
        }
        
        do {
            valueCount = 0
            errorCount = 0
            let p: Parser<Void> = skipMany(p1, separator: p2,
                                           atLeastOne: false, allowEndBySeparator: false)
            checkFailure(p.parse(makeEmptyStream()), errors)
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
            checkFatalFailure(p.parse(makeEmptyStream()), errors)
        }
        
        do {
            valueCount = 0
            errorCount = 0
            let p: Parser<Void> = skipMany(p1, separator: p2,
                                           atLeastOne: false, allowEndBySeparator: false)
            checkFatalFailure(p.parse(makeEmptyStream()), errors)
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
            checkFatalFailure(p.parse(makeEmptyStream()), errors)
        }
        
        do {
            valueCount = 0
            errorCount = 0
            let p: Parser<Void> = skipMany(p1, separator: p2,
                                           atLeastOne: false, allowEndBySeparator: false)
            checkFatalFailure(p.parse(makeEmptyStream()), errors)
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
            checkSuccess(p.parse(makeEmptyStream()), values, errors)
        }
        
        do {
            valueCount = 0
            errorCount = 0
            let p: Parser<Void> = skipMany(p1, separator: p2,
                                           atLeastOne: false, allowEndBySeparator: false)
            checkSuccess(p.parse(makeEmptyStream()), errors)
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
            checkFailure(p.parse(makeEmptyStream()), errors)
        }
        
        do {
            valueCount = 0
            errorCount = 0
            let p: Parser<Void> = skipMany(p1, separator: p2,
                                           atLeastOne: true, allowEndBySeparator: false)
            checkFailure(p.parse(makeEmptyStream()), errors)
        }
    }
}



