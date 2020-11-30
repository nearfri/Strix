import XCTest
@testable import Strix

final class SequenceParsersTests: XCTestCase {
    func test_repeat_enoughSuccess_succeed() {
        // Given
        var count = 0
        let p1: Parser<Int> = Parser { state in
            count += 1
            return .success(count, state)
        }
        
        // When
        let p: Parser<[Int]> = .repeat(p1, count: 3)
        let reply = p.parse(ParserState(stream: "Input"))
        
        // Then
        XCTAssertEqual(reply.result.value, [1, 2, 3])
    }
    
    func test_repeat_notEnoughSuccess_fail() {
        // Given
        var count = 0
        let p1: Parser<Int> = Parser { state in
            count += 1
            if count > 2 {
                return .failure([.expected(label: "number")], state)
            }
            return .success(count, state)
        }
        
        // When
        let p: Parser<[Int]> = .repeat(p1, count: 3)
        let reply = p.parse(ParserState(stream: "Input"))
        
        // Then
        XCTAssert(reply.result.isFailure)
    }
    
    func test_many_enoughSuccess_succeed() {
        // Given
        let p1: Parser<Int> = .just(1)
        
        var count = 1
        let p2: Parser<Int> = Parser { state in
            count += 1
            if count > 5 {
                return .failure([.expected(label: "number")], state)
            }
            return .success(count, state.withStream(state.stream.dropFirst()))
        }
        
        // When
        let p: Parser<[Int]> = .many(first: p1, repeating: p2, minCount: 5)
        let reply = p.parse(ParserState(stream: "Input..........."))
        
        // Then
        XCTAssertEqual(reply.result.value, [1, 2, 3, 4, 5])
    }
    
    func test_many_notEnoughSuccess_fail() {
        // Given
        let p1: Parser<Int> = .just(1)
        
        var count = 1
        let p2: Parser<Int> = Parser { state in
            count += 1
            if count > 4 {
                return .failure([.expected(label: "number")], state)
            }
            return .success(count, state.withStream(state.stream.dropFirst()))
        }
        
        // When
        let p: Parser<[Int]> = .many(first: p1, repeating: p2, minCount: 5)
        let reply = p.parse(ParserState(stream: "Input..........."))
        
        // Then
        XCTAssert(reply.result.isFailure)
    }
    
    func test_manySeparated_failAtSeparator_succeed() {
        // Given
        var count = 0
        let p1: Parser<Int> = Parser { state in
            count += 1
            return .success(count, state)
        }
        
        var sepCount = 0
        let sep: Parser<String> = Parser { state in
            sepCount += 1
            if sepCount > 2 {
                return .failure([.expected(label: "comma")], state)
            }
            return .success(",", state.withStream(state.stream.dropFirst()))
        }
        
        // When
        let p: Parser<[Int]> = .many(p1, separatedBy: sep)
        let reply = p.parse(ParserState(stream: "Input..........."))
        
        // Then
        XCTAssertEqual(reply.result.value, [1, 2, 3])
    }
    
    func test_manySeparated_failAtParser_fail() {
        // Given
        var count = 0
        let p1: Parser<Int> = Parser { state in
            count += 1
            if count > 2 {
                return .failure([.expected(label: "number")], state)
            }
            return .success(count, state)
        }
        
        var sepCount = 0
        let sep: Parser<String> = Parser { state in
            sepCount += 1
            return .success(",", state.withStream(state.stream.dropFirst()))
        }
        
        // When
        let p: Parser<[Int]> = .many(p1, separatedBy: sep)
        let reply = p.parse(ParserState(stream: "Input..........."))
        
        // Then
        XCTAssert(reply.result.isFailure)
    }
    
    func test_manySeparatedWithAllowEndBySeparator_failAtParser_succeed() {
        // Given
        var count = 0
        let p1: Parser<Int> = Parser { state in
            count += 1
            if count > 2 {
                return .failure([.expected(label: "number")], state)
            }
            return .success(count, state)
        }
        
        var sepCount = 0
        let sep: Parser<String> = Parser { state in
            sepCount += 1
            return .success(",", state.withStream(state.stream.dropFirst()))
        }
        
        // When
        let p: Parser<[Int]> = .many(p1, separatedBy: sep, allowEndBySeparator: true)
        let reply = p.parse(ParserState(stream: "Input..........."))
        
        // Then
        XCTAssertEqual(reply.result.value, [1, 2])
    }
}

