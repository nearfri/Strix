import XCTest
@testable import Strix2

private enum Seed {
    static let input = """
    12345
    abcde
    ABCDE
    """
}

final class TextPositionTests: XCTestCase {
    func test_init_lineAtStartIndex() {
        // Given
        let startIndex = Seed.input.startIndex
        
        // When
        let position = TextPosition(string: Seed.input, index: startIndex)
        
        // Then
        XCTAssertEqual(position.line, 1)
    }
    
    func test_init_lineAtEndIndex() {
        // Given
        let endIndex = Seed.input.endIndex
        
        // When
        let position = TextPosition(string: Seed.input, index: endIndex)
        
        // Then
        XCTAssertEqual(position.line, 3)
    }
    
    func test_init_lineAtStartOfLine() throws {
        // Given
        let indexA = try XCTUnwrap(Seed.input.firstIndex(of: "a"))
        
        // When
        let position = TextPosition(string: Seed.input, index: indexA)
        
        // Then
        XCTAssertEqual(position.line, 2)
    }
    
    func test_init_lineAtEndOfLine() throws {
        // Given
        let indexE = try XCTUnwrap(Seed.input.firstIndex(of: "e"))
        let indexAfterE = Seed.input.index(after: indexE)
        
        // When
        let position = TextPosition(string: Seed.input, index: indexAfterE)
        
        // Then
        XCTAssertEqual(position.line, 2)
    }
    
    func test_init_lineAtEmptyString() throws {
        // Given
        let input = ""
        let index = input.startIndex
        
        // When
        let position = TextPosition(string: input, index: index)
        
        // Then
        XCTAssertEqual(position.line, 1)
    }
    
    func test_init_columnAtFirstIndex() {
        // Given
        let startIndex = Seed.input.startIndex
        
        // When
        let position = TextPosition(string: Seed.input, index: startIndex)
        
        // Then
        XCTAssertEqual(position.column, 1)
    }
    
    func test_init_columnAtEndIndex() {
        // Given
        let endIndex = Seed.input.endIndex
        
        // When
        let position = TextPosition(string: Seed.input, index: endIndex)
        
        // Then
        XCTAssertEqual(position.column, 6)
    }
    
    func test_init_columnAtStartOfLine() throws {
        // Given
        let indexA = try XCTUnwrap(Seed.input.firstIndex(of: "a"))
        
        // When
        let position = TextPosition(string: Seed.input, index: indexA)
        
        // Then
        XCTAssertEqual(position.column, 1)
    }
    
    func test_init_columnAtEndOfLine() throws {
        // Given
        let indexE = try XCTUnwrap(Seed.input.firstIndex(of: "e"))
        let indexAfterE = Seed.input.index(after: indexE)
        
        // When
        let position = TextPosition(string: Seed.input, index: indexAfterE)
        
        // Then
        XCTAssertEqual(position.column, 6)
    }
    
    func test_init_columnAtEmptyString() throws {
        // Given
        let input = ""
        let index = input.startIndex
        
        // When
        let position = TextPosition(string: input, index: index)
        
        // Then
        XCTAssertEqual(position.column, 1)
    }
}
