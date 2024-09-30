import Testing
@testable import Strix

@Suite struct ParseErrorSplitterTests {
    @Test func hasErrors_noError_returnFalse() {
        // Given
        let errors: [ParseError] = []
        let errorSplitter = ParseErrorSplitter(errors)
        
        // When
        let hasError = errorSplitter.hasErrors
        
        // Then
        #expect(!hasError)
    }
    
    @Test func hasErrors_hasError_returnTrue() {
        // Given
        let errors: [ParseError] = [.expected(label: "number")]
        let errorSplitter = ParseErrorSplitter(errors)
        
        // When
        let hasError = errorSplitter.hasErrors
        
        // Then
        #expect(hasError)
    }
    
    @Test func init_removeDuplicates() {
        // Given
        let errors: [ParseError] = [.expected(label: "whitespace"), .expected(label: "whitespace")]
        
        // When
        let errorSplitter = ParseErrorSplitter(errors)
        
        // Then
        #expect(errorSplitter.expectedErrors == ["whitespace"])
    }
}
