import Testing
@testable import Strix

@Suite struct IndentTests {
    @Test func toString() {
        // Given
        let indent = Indent(level: 2, width: 4)
        
        // When
        let indentString = indent.toString()
        
        // Then
        #expect(indentString == String(repeating: " ", count: 8))
    }
    
    @Test func description() {
        // Given
        let indent = Indent(level: 2, width: 4)
        var description = ""
        
        // When
        print(indent, terminator: "", to: &description)
        
        // Then
        #expect(description == String(repeating: " ", count: 8))
    }
    
    @Test func interpolation() {
        // Given
        let indent = Indent(level: 2, width: 4)
        var description = ""
        
        // When
        print("\(indent)", terminator: "", to: &description)
        
        // Then
        #expect(description == String(repeating: " ", count: 8))
    }
}
