
import XCTest
@testable import Strix

class SequencesManyTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
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
            checkSuccess(p.parse(makeEmptyStream()), values, errors)
        }
        
        do {
            count = 0
            let p: Parser<Void> = skipMany(p1)
            checkSuccess(p.parse(makeEmptyStream()), errors)
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
            checkFailure(p.parse(makeEmptyStream()), errors)
        }
        
        do {
            count = 0
            let p: Parser<Void> = skipMany(p1)
            checkFailure(p.parse(makeEmptyStream()), errors)
        }
    }
    
    func test_many_whenNotRequireAtLeastOneAndFailAtFirst_returnSuccess() {
        let p1 = Parser { stream -> Reply<Int> in
            return .failure([DummyError.err0])
        }
        let errors = [DummyError.err0]
        
        do {
            let p: Parser<[Int]> = many(p1, atLeastOne: false)
            checkSuccess(p.parse(makeEmptyStream()), [], errors)
        }
        
        do {
            let p: Parser<Void> = skipMany(p1, atLeastOne: false)
            checkSuccess(p.parse(makeEmptyStream()), errors)
        }
    }
    
    func test_many_whenRequireAtLeastOneAndFailAtFirst_returnFailure() {
        let p1 = Parser { stream -> Reply<Int> in
            return .failure([DummyError.err0])
        }
        let errors = [DummyError.err0]
        
        do {
            let p: Parser<[Int]> = many(p1, atLeastOne: true)
            checkFailure(p.parse(makeEmptyStream()), errors)
        }
        
        do {
            let p: Parser<Void> = skipMany(p1, atLeastOne: true)
            checkFailure(p.parse(makeEmptyStream()), errors)
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
            _ = p.parse(makeEmptyStream())
            
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
        checkSuccess(p.parse(makeEmptyStream()), values, errors)
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
        checkFailure(p.parse(makeEmptyStream()), [DummyError.err0])
    }
}



