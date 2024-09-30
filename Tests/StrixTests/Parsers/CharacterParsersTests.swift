import Testing
@testable import Strix

@Suite struct CharacterParsersTests {
    @Test func satisfy_succeed_returnCharacter() {
        // Given
        let state = ParserState(stream: "123")
        
        // When
        let p: Parser<Character> = .satisfy("number", { _ in true })
        let reply = p.parse(state)
        
        // Then
        #expect(reply.result.value == "1")
        #expect(reply.state.stream.startIndex == state.stream.index(after: state.stream.startIndex))
    }
    
    @Test func satisfy_fail_returnFailure() {
        // Given
        let state = ParserState(stream: "123")
        
        // When
        let p: Parser<Character> = .satisfy("number", { _ in false })
        let reply = p.parse(state)
        
        // Then
        #expect(reply.result.isFailure)
        #expect(reply.state.stream.startIndex == state.stream.startIndex)
        #expect(reply.errors == [.expected(label: "number")])
    }
    
    @Test func anyOfCharacterSet_succeed() {
        // Given
        let state = ParserState(stream: "123")
        
        // When
        let p: Parser<Character> = .any(of: .decimalDigits, label: "decimal")
        let reply = p.parse(state)
        
        // Then
        #expect(reply.result.value == "1")
    }
    
    @Test func anyOfCharacterSet_fail() {
        // Given
        let state = ParserState(stream: "abc")
        
        // When
        let p: Parser<Character> = .any(of: .decimalDigits, label: "decimal")
        let reply = p.parse(state)
        
        // Then
        #expect(reply.result.isFailure)
    }
    
    @Test func anyOfSequence() {
        // Given
        let state = ParserState(stream: "123")
        
        // When
        let p: Parser<Character> = .any(of: "0123456789")
        let reply = p.parse(state)
        
        // Then
        #expect(reply.result.value == "1")
    }
    
    @Test func noneOfSequence() {
        // Given
        let state = ParserState(stream: "abc")
        
        // When
        let p: Parser<Character> = .none(of: "0123456789")
        let reply = p.parse(state)
        
        // Then
        #expect(reply.result.value == "a")
    }
    
    @Test func hexadecimalDigit_succeed() {
        // Given
        let state = ParserState(stream: "f")
        
        // When
        let p: Parser<Character> = .hexadecimalDigit
        let reply = p.parse(state)
        
        // Then
        #expect(reply.result.value == "f")
    }
    
    @Test func hexadecimalDigit_fail() {
        // Given
        let state = ParserState(stream: "g")
        
        // When
        let p: Parser<Character> = .hexadecimalDigit
        let reply = p.parse(state)
        
        // Then
        #expect(reply.result.isFailure)
    }
}
