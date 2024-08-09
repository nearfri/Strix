import XCTest
@testable import Strix

final class StringParsersTests: XCTestCase {
    // MARK: - string
    
    func test_string_caseSensitive_succeed() {
        // Given
        let state = ParserState(stream: "Hello World")
        
        // When
        let p: Parser<String> = .string("Hello", caseSensitive: true)
        let reply = p.parse(state)
        
        // Then
        XCTAssertEqual(reply.result.value, "Hello")
        XCTAssertEqual(reply.state.stream, " World")
    }
    
    func test_string_caseSensitive_fail() {
        // Given
        let state = ParserState(stream: "Hello World")
        
        // When
        let p: Parser<String> = .string("hello", caseSensitive: true)
        let reply = p.parse(state)
        
        // Then
        XCTAssert(reply.result.isFailure)
        XCTAssertEqual(reply.state.stream, "Hello World")
    }
    
    func test_string_caseInsensitive() {
        // Given
        let state = ParserState(stream: "Hello World")
        
        // When
        let p: Parser<String> = .string("hEllO", caseSensitive: false)
        let reply = p.parse(state)
        
        // Then
        XCTAssertEqual(reply.result.value, "Hello")
        XCTAssertEqual(reply.state.stream, " World")
    }
    
    func test_string_endBeforeMatch_returnFailure() {
        // Given
        let state = ParserState(stream: "Hell")
        
        // When
        let p: Parser<String> = .string("Hello", caseSensitive: true)
        let reply = p.parse(state)
        
        // Then
        XCTAssert(reply.result.isFailure)
        XCTAssertEqual(reply.state.stream, "Hell")
    }
    
    // MARK: - stringUntil
    
    func test_stringUntil_skipBoundaryIsTrue_succeed() {
        // Given
        let state = ParserState(stream: "Hello Parser World")
        
        // When
        let p: Parser<String> = .string(until: "Parser", caseSensitive: true, skipBoundary: true)
        let reply = p.parse(state)
        
        // Then
        XCTAssertEqual(reply.result.value, "Hello ")
        XCTAssertEqual(reply.state.stream, " World")
    }
    
    func test_stringUntil_skipBoundaryIsTrue_fail() {
        // Given
        let state = ParserState(stream: "Hello Parser World")
        
        // When
        let p: Parser<String> = .string(until: "parser", caseSensitive: true, skipBoundary: true)
        let reply = p.parse(state)
        
        // Then
        XCTAssert(reply.result.isFailure)
        XCTAssertEqual(reply.state.stream, "Hello Parser World")
    }
    
    func test_stringUntil_skipBoundaryIsFalse() {
        // Given
        let state = ParserState(stream: "Hello Parser World")
        
        // When
        let p: Parser<String> = .string(until: "Parser", caseSensitive: true, skipBoundary: false)
        let reply = p.parse(state)
        
        // Then
        XCTAssertEqual(reply.result.value, "Hello ")
        XCTAssertEqual(reply.state.stream, "Parser World")
    }
    
    // MARK: - restOfLine
    
    func test_restOfLine_strippingNewlineIsTrue() {
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
        XCTAssertEqual(reply.result.value, "ello")
        XCTAssertEqual(reply.state.stream, "World")
    }
    
    func test_restOfLine_strippingNewlineIsFalse() {
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
        XCTAssertEqual(reply.result.value, "ello\n")
        XCTAssertEqual(reply.state.stream, "World")
    }
    
    func test_restOfLine_atLastLine() {
        // Given
        let input = "Hello"
        let state = ParserState(stream: input[input.index(after: input.startIndex)...])
        
        // When
        let p: Parser<String> = .restOfLine(strippingNewline: true)
        let reply = p.parse(state)
        
        // Then
        XCTAssertEqual(reply.result.value, "ello")
        XCTAssertEqual(reply.state.stream.startIndex, reply.state.stream.endIndex)
    }
    
    func test_restOfLine_atEOS() {
        // Given
        let input = "Hello"
        let state = ParserState(stream: input[input.endIndex...])
        
        // When
        let p: Parser<String> = .restOfLine(strippingNewline: true)
        let reply = p.parse(state)
        
        // Then
        XCTAssertEqual(reply.result.value, "")
        XCTAssertEqual(reply.state.stream.startIndex, reply.state.stream.endIndex)
    }
}
