import Testing
@testable import Strix

private enum Fixture {
    static let input = """
        12345
        abcde
        ABCDE
        """
}

@Suite struct TextPositionTests {
    @Test func init_lineAtStartIndex() {
        // Given
        let startIndex = Fixture.input.startIndex
        
        // When
        let position = TextPosition(string: Fixture.input, index: startIndex)
        
        // Then
        #expect(position.line == 1)
    }
    
    @Test func init_lineAtEndIndex() {
        // Given
        let endIndex = Fixture.input.endIndex
        
        // When
        let position = TextPosition(string: Fixture.input, index: endIndex)
        
        // Then
        #expect(position.line == 3)
    }
    
    @Test func init_lineAtStartOfLine() throws {
        // Given
        let indexA = try #require(Fixture.input.firstIndex(of: "a"))
        
        // When
        let position = TextPosition(string: Fixture.input, index: indexA)
        
        // Then
        #expect(position.line == 2)
    }
    
    @Test func init_lineAtEndOfLine() throws {
        // Given
        let indexE = try #require(Fixture.input.firstIndex(of: "e"))
        let indexAfterE = Fixture.input.index(after: indexE)
        
        // When
        let position = TextPosition(string: Fixture.input, index: indexAfterE)
        
        // Then
        #expect(position.line == 2)
    }
    
    @Test func init_lineAtEmptyString_startIndex() {
        // Given
        let input = ""
        let index = input.startIndex
        
        // When
        let position = TextPosition(string: input, index: index)
        
        // Then
        #expect(position.line == 1)
    }
    
    @Test func init_lineAtEmptyString_endIndex() {
        // Given
        let input = ""
        let index = input.endIndex
        
        // When
        let position = TextPosition(string: input, index: index)
        
        // Then
        #expect(position.line == 1)
    }
    
    @Test func init_lineAtSingleLineString() {
        // Given
        let input = "hello world\n"
        let index = input.endIndex
        
        // When
        let position = TextPosition(string: input, index: index)
        
        // Then
        #expect(position.line == 1)
    }
    
    @Test func init_columnAtFirstIndex() {
        // Given
        let startIndex = Fixture.input.startIndex
        
        // When
        let position = TextPosition(string: Fixture.input, index: startIndex)
        
        // Then
        #expect(position.column == 1)
    }
    
    @Test func init_columnAtEndIndex() {
        // Given
        let endIndex = Fixture.input.endIndex
        
        // When
        let position = TextPosition(string: Fixture.input, index: endIndex)
        
        // Then
        #expect(position.column == 6)
    }
    
    @Test func init_columnAtStartOfLine() throws {
        // Given
        let indexA = try #require(Fixture.input.firstIndex(of: "a"))
        
        // When
        let position = TextPosition(string: Fixture.input, index: indexA)
        
        // Then
        #expect(position.column == 1)
    }
    
    @Test func init_columnAtEndOfLine() throws {
        // Given
        let indexE = try #require(Fixture.input.firstIndex(of: "e"))
        let indexAfterE = Fixture.input.index(after: indexE)
        
        // When
        let position = TextPosition(string: Fixture.input, index: indexAfterE)
        
        // Then
        #expect(position.column == 6)
    }
    
    @Test func init_columnAtEmptyString() throws {
        // Given
        let input = ""
        let index = input.startIndex
        
        // When
        let position = TextPosition(string: input, index: index)
        
        // Then
        #expect(position.column == 1)
    }
}
