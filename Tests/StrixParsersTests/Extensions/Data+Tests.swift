import XCTest
@testable import StrixParsers

final class Data_Tests: XCTestCase {
    func test_hexStringRepresentation_lowercase() {
        // Given
        let data = Data([
            0xab, 0xcd, 0xef, 0x01, 0x23, 0x45, 0x67, 0x89
        ])
        
        // When
        let hexString = data.hexStringRepresentation(uppercase: false)
        
        // Then
        XCTAssertEqual(hexString, "abcdef0123456789")
    }
    
    func test_hexStringRepresentation_uppercase() {
        // Given
        let data = Data([
            0xab, 0xcd, 0xef, 0x01, 0x23, 0x45, 0x67, 0x89
        ])
        
        // When
        let hexString = data.hexStringRepresentation(uppercase: true)
        
        // Then
        XCTAssertEqual(hexString, "ABCDEF0123456789")
    }
}
