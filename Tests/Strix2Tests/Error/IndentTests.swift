import XCTest
@testable import Strix2

final class IndentTests: XCTestCase {
    func test_toString() {
        // Given
        let indent = Indent(level: 2, width: 4)
        
        // When
        let indentString = indent.toString()
        
        // Then
        XCTAssertEqual(indentString, String(repeating: " ", count: 8))
    }
    
    func test_description() {
        // Given
        let indent = Indent(level: 2, width: 4)
        var description = ""
        
        // When
        print(indent, terminator: "", to: &description)
        
        // Then
        XCTAssertEqual(description, String(repeating: " ", count: 8))
    }
    
    func test_interpolation() {
        // Given
        let indent = Indent(level: 2, width: 4)
        var description = ""
        
        // When
        print("\(indent)", terminator: "", to: &description)
        
        // Then
        XCTAssertEqual(description, String(repeating: " ", count: 8))
    }
}
