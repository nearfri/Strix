import XCTest
@testable import Strix2

final class ParseErrorSplitterTests: XCTestCase {
    func test_hasErrors_noError_returnFalse() {
        // Given
        let errors: [ParseError] = []
        let errorSplitter = ParseErrorSplitter(errors)
        
        // When
        let hasError = errorSplitter.hasErrors
        
        // Then
        XCTAssertFalse(hasError)
    }
    
    func test_hasErrors_hasError_returnTrue() {
        // Given
        let errors: [ParseError] = [.expected(label: "number")]
        let errorSplitter = ParseErrorSplitter(errors)
        
        // When
        let hasError = errorSplitter.hasErrors
        
        // Then
        XCTAssert(hasError)
    }
}
