import XCTest
@testable import Strix

final class CharacterParsersTests: XCTestCase {
    func test_satisfy_succeed_returnCharacter() {
        // Given
        let state = ParserState(stream: "123")
        
        // When
        let p: Parser<Character> = .satisfy("number", { _ in true })
        let reply = p.parse(state)
        
        // Then
        XCTAssertEqual(reply.result.value, "1")
        XCTAssertEqual(reply.state.stream.startIndex,
                       state.stream.index(after: state.stream.startIndex))
    }
    
    func test_satisfy_fail_returnFailure() {
        // Given
        let state = ParserState(stream: "123")
        
        // When
        let p: Parser<Character> = .satisfy("number", { _ in false })
        let reply = p.parse(state)
        
        // Then
        XCTAssert(reply.result.isFailure)
        XCTAssertEqual(reply.state.stream.startIndex, state.stream.startIndex)
        XCTAssertEqual(reply.errors, [.expected(label: "number")])
    }
    
    func test_anyOfCharacterSet_succeed() {
        // Given
        let state = ParserState(stream: "123")
        
        // When
        let p: Parser<Character> = .any(of: .decimalDigits, label: "decimal")
        let reply = p.parse(state)
        
        // Then
        XCTAssertEqual(reply.result.value, "1")
    }
    
    func test_anyOfCharacterSet_fail() {
        // Given
        let state = ParserState(stream: "abc")
        
        // When
        let p: Parser<Character> = .any(of: .decimalDigits, label: "decimal")
        let reply = p.parse(state)
        
        // Then
        XCTAssert(reply.result.isFailure)
    }
    
    func test_anyOfSequence() {
        // Given
        let state = ParserState(stream: "123")
        
        // When
        let p: Parser<Character> = .any(of: "0123456789")
        let reply = p.parse(state)
        
        // Then
        XCTAssertEqual(reply.result.value, "1")
    }
    
    func test_noneOfSequence() {
        // Given
        let state = ParserState(stream: "abc")
        
        // When
        let p: Parser<Character> = .none(of: "0123456789")
        let reply = p.parse(state)
        
        // Then
        XCTAssertEqual(reply.result.value, "a")
    }
    
    func test_hexadecimalDigit_succeed() {
        // Given
        let state = ParserState(stream: "f")
        
        // When
        let p: Parser<Character> = .hexadecimalDigit
        let reply = p.parse(state)
        
        // Then
        XCTAssertEqual(reply.result.value, "f")
    }
    
    func test_hexadecimalDigit_fail() {
        // Given
        let state = ParserState(stream: "g")
        
        // When
        let p: Parser<Character> = .hexadecimalDigit
        let reply = p.parse(state)
        
        // Then
        XCTAssert(reply.result.isFailure)
    }
}
