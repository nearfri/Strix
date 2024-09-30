import Testing
import Foundation
@testable import StrixParsers

@Suite struct DataTests {
    @Test func hexStringRepresentation_lowercase() {
        // Given
        let data = Data([
            0xab, 0xcd, 0xef, 0x01, 0x23, 0x45, 0x67, 0x89
        ])
        
        // When
        let hexString = data.hexStringRepresentation(uppercase: false)
        
        // Then
        #expect(hexString == "abcdef0123456789")
    }
    
    @Test func hexStringRepresentation_uppercase() {
        // Given
        let data = Data([
            0xab, 0xcd, 0xef, 0x01, 0x23, 0x45, 0x67, 0x89
        ])
        
        // When
        let hexString = data.hexStringRepresentation(uppercase: true)
        
        // Then
        #expect(hexString == "ABCDEF0123456789")
    }
}
