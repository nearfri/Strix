
import XCTest
@testable import Strix

class SequencesArrayTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
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
            checkSuccess(p.parse(makeEmptyStream()), values, errors, message)
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
            checkSuccess(p.parse(makeEmptyStream()), values, errors, message)
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
                checkSuccess(p.parse(makeEmptyStream()), [], [] as [DummyError], message)
            } else {
                let values = Array(1..<maxCount+1)
                let errors = values.map({ DummyError(rawValue: $0)! })
                checkFailure(p.parse(makeEmptyStream()), errors, message)
            }
        }
    }
    
    func test_array_whenParserFailure_returnFailure() {
        let p1 = Parser { stream -> Reply<Int> in
            return .failure([DummyError.err0])
        }
        let p: Parser<[Int]> = array(p1, count: 3)
        checkFailure(p.parse(makeEmptyStream()), [DummyError.err0])
    }
    
    func test_array_whenParserFatalFailure_returnFatalFailure() {
        let p1 = Parser { stream -> Reply<Int> in
            return .fatalFailure([DummyError.err0])
        }
        let p: Parser<[Int]> = array(p1, count: 3)
        checkFatalFailure(p.parse(makeEmptyStream()), [DummyError.err0])
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
            checkSuccess(p.parse(makeEmptyStream()), errors, message)
        }
    }
    
    func test_skipArray_whenParserFailure_returnFailure() {
        let p1 = Parser { stream -> Reply<Int> in
            return .failure([DummyError.err0])
        }
        let p: Parser<Void> = skipArray(p1, count: 3)
        checkFailure(p.parse(makeEmptyStream()), [DummyError.err0])
    }
}



