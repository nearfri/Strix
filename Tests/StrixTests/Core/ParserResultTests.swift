import Testing
@testable import Strix

@Suite struct ParserResultTests {
    @Test func value() {
        // Given
        let value = 3
        let result = ParserResult.success(value, [])
        
        // When
        let resultValue = result.value
        
        // Then
        #expect(resultValue == value)
    }
    
    @Test func errors_setAndGetWhenSuccess() {
        // Given
        let errors: [ParseError] = [.expected(label: "number")]
        var result = ParserResult.success(3, [])
        
        // When
        result.errors = errors
        let resultErrors = result.errors
        
        // Then
        #expect(resultErrors == errors)
    }
    
    @Test func errors_setAndGetWhenFailure() {
        // Given
        let errors: [ParseError] = [.expected(label: "number")]
        var result = ParserResult<Int>.failure([])
        
        // When
        result.errors = errors
        let resultErrors = result.errors
        
        // Then
        #expect(resultErrors == errors)
    }
    
    @Test func map_successAndSuccess_returnSuccess() {
        // Given
        let sut = ParserResult.success("hello", [])
        
        // When
        let mapped = sut.map({ _ in 123 })
        
        // Then
        #expect(mapped.value == 123)
    }
    
    @Test func map_successAndThrow_returnFailure() {
        // Given
        let sut = ParserResult.success("hello", [])
        
        // When
        let mapped: ParserResult<Int> = sut.map({ _ throws(ParseError) in
            throw ParseError.expected(label: "Hello")
        })
        
        // Then
        #expect(mapped.value == nil)
        #expect(mapped.errors == [.expected(label: "Hello")])
    }
    
    @Test func map_failure_returnFailure() {
        // Given
        let sut = ParserResult<String>.failure([])
        
        // When
        let mapped = sut.map({ _ in 123 })
        
        // Then
        #expect(mapped.value == nil)
    }
}
