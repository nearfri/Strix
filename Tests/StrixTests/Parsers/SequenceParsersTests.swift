import Testing
@testable import Strix

@Suite struct SequenceParsersTests {
    @Test func repeat_enoughSuccess_succeed() {
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
        #expect(reply.result.value == [1, 2, 3])
    }
    
    @Test func repeat_notEnoughSuccess_fail() {
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
        #expect(reply.result.isFailure)
    }
    
    @Test func many_enoughSuccess_succeed() {
        // Given
        let p1: Parser<Int> = .just(1)
        
        var count = 1
        let p2: Parser<Int> = Parser { state in
            count += 1
            if count > 5 {
                return .failure([.expected(label: "number")], state)
            }
            return .success(count, state.advanced())
        }
        
        // When
        let p: Parser<[Int]> = .many(first: p1, repeating: p2, minCount: 5)
        let reply = p.parse(ParserState(stream: "Input..........."))
        
        // Then
        #expect(reply.result.value == [1, 2, 3, 4, 5])
    }
    
    @Test func many_notEnoughSuccess_fail() {
        // Given
        let p1: Parser<Int> = .just(1)
        
        var count = 1
        let p2: Parser<Int> = Parser { state in
            count += 1
            if count > 4 {
                return .failure([.expected(label: "number")], state)
            }
            return .success(count, state.advanced())
        }
        
        // When
        let p: Parser<[Int]> = .many(first: p1, repeating: p2, minCount: 5)
        let reply = p.parse(ParserState(stream: "Input..........."))
        
        // Then
        #expect(reply.result.isFailure)
    }
    
    @Test func manySeparated_failAtSeparator_succeed() {
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
            return .success(",", state.advanced())
        }
        
        // When
        let p: Parser<[Int]> = .many(p1, separatedBy: sep)
        let reply = p.parse(ParserState(stream: "Input..........."))
        
        // Then
        #expect(reply.result.value == [1, 2, 3])
    }
    
    @Test func manySeparated_failAtParser_fail() {
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
            return .success(",", state.advanced())
        }
        
        // When
        let p: Parser<[Int]> = .many(p1, separatedBy: sep)
        let reply = p.parse(ParserState(stream: "Input..........."))
        
        // Then
        #expect(reply.result.isFailure)
    }
    
    @Test func manySeparatedWithAllowEndBySeparator_failAtParser_succeed() {
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
            return .success(",", state.advanced())
        }
        
        // When
        let p: Parser<[Int]> = .many(p1, separatedBy: sep, allowEndBySeparator: true)
        let reply = p.parse(ParserState(stream: "Input..........."))
        
        // Then
        #expect(reply.result.value == [1, 2])
    }
}
