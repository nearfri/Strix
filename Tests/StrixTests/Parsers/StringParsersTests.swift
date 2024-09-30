import Testing
@testable import Strix

@Suite struct StringParsersTests {
    // MARK: - string
    
    @Test func string_caseSensitive_succeed() {
        // Given
        let state = ParserState(stream: "Hello World")
        
        // When
        let p: Parser<String> = .string("Hello", caseSensitive: true)
        let reply = p.parse(state)
        
        // Then
        #expect(reply.result.value == "Hello")
        #expect(reply.state.stream == " World")
    }
    
    @Test func string_caseSensitive_fail() {
        // Given
        let state = ParserState(stream: "Hello World")
        
        // When
        let p: Parser<String> = .string("hello", caseSensitive: true)
        let reply = p.parse(state)
        
        // Then
        #expect(reply.result.isFailure)
        #expect(reply.state.stream == "Hello World")
    }
    
    @Test func string_caseInsensitive() {
        // Given
        let state = ParserState(stream: "Hello World")
        
        // When
        let p: Parser<String> = .string("hEllO", caseSensitive: false)
        let reply = p.parse(state)
        
        // Then
        #expect(reply.result.value == "Hello")
        #expect(reply.state.stream == " World")
    }
    
    @Test func string_endBeforeMatch_returnFailure() {
        // Given
        let state = ParserState(stream: "Hell")
        
        // When
        let p: Parser<String> = .string("Hello", caseSensitive: true)
        let reply = p.parse(state)
        
        // Then
        #expect(reply.result.isFailure)
        #expect(reply.state.stream == "Hell")
    }
    
    // MARK: - stringUntil
    
    @Test func stringUntil_skipBoundaryIsTrue_succeed() {
        // Given
        let state = ParserState(stream: "Hello Parser World")
        
        // When
        let p: Parser<String> = .string(until: "Parser", caseSensitive: true, skipBoundary: true)
        let reply = p.parse(state)
        
        // Then
        #expect(reply.result.value == "Hello ")
        #expect(reply.state.stream == " World")
    }
    
    @Test func stringUntil_skipBoundaryIsTrue_fail() {
        // Given
        let state = ParserState(stream: "Hello Parser World")
        
        // When
        let p: Parser<String> = .string(until: "parser", caseSensitive: true, skipBoundary: true)
        let reply = p.parse(state)
        
        // Then
        #expect(reply.result.isFailure)
        #expect(reply.state.stream == "Hello Parser World")
    }
    
    @Test func stringUntil_skipBoundaryIsFalse() {
        // Given
        let state = ParserState(stream: "Hello Parser World")
        
        // When
        let p: Parser<String> = .string(until: "Parser", caseSensitive: true, skipBoundary: false)
        let reply = p.parse(state)
        
        // Then
        #expect(reply.result.value == "Hello ")
        #expect(reply.state.stream == "Parser World")
    }
    
    // MARK: - restOfLine
    
    @Test func restOfLine_strippingNewlineIsTrue() {
        // Given
        let input = """
        Hello
        World
        """
        let state = ParserState(stream: input[input.index(after: input.startIndex)...])
        
        // When
        let p: Parser<String> = .restOfLine(strippingNewline: true)
        let reply = p.parse(state)
        
        // Then
        #expect(reply.result.value == "ello")
        #expect(reply.state.stream == "World")
    }
    
    @Test func restOfLine_strippingNewlineIsFalse() {
        // Given
        let input = """
        Hello
        World
        """
        let state = ParserState(stream: input[input.index(after: input.startIndex)...])
        
        // When
        let p: Parser<String> = .restOfLine(strippingNewline: false)
        let reply = p.parse(state)
        
        // Then
        #expect(reply.result.value == "ello\n")
        #expect(reply.state.stream == "World")
    }
    
    @Test func restOfLine_atLastLine() {
        // Given
        let input = "Hello"
        let state = ParserState(stream: input[input.index(after: input.startIndex)...])
        
        // When
        let p: Parser<String> = .restOfLine(strippingNewline: true)
        let reply = p.parse(state)
        
        // Then
        #expect(reply.result.value == "ello")
        #expect(reply.state.stream.startIndex == reply.state.stream.endIndex)
    }
    
    @Test func restOfLine_atEOS() {
        // Given
        let input = "Hello"
        let state = ParserState(stream: input[input.endIndex...])
        
        // When
        let p: Parser<String> = .restOfLine(strippingNewline: true)
        let reply = p.parse(state)
        
        // Then
        #expect(reply.result.value == "")
        #expect(reply.state.stream.startIndex == reply.state.stream.endIndex)
    }
}
