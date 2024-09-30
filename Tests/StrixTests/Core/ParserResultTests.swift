import XCTest
@testable import Strix

final class ParserResultTests: XCTestCase {
    func test_value() {
        // Given
        let value = 3
        let result = ParserResult.success(value, [])
        
        // When
        let resultValue = result.value
        
        // Then
        XCTAssertEqual(resultValue, value)
    }
    
    func test_errors_setAndGetWhenSuccess() {
        // Given
        let errors: [ParseError] = [.expected(label: "number")]
        var result = ParserResult.success(3, [])
        
        // When
        result.errors = errors
        let resultErrors = result.errors
        
        // Then
        XCTAssertEqual(resultErrors, errors)
    }
    
    func test_errors_setAndGetWhenFailure() {
        // Given
        let errors: [ParseError] = [.expected(label: "number")]
        var result = ParserResult<Int>.failure([])
        
        // When
        result.errors = errors
        let resultErrors = result.errors
        
        // Then
        XCTAssertEqual(resultErrors, errors)
    }
    
    func test_map_successAndSuccess_returnSuccess() {
        // Given
        let sut = ParserResult.success("hello", [])
        
        // When
        let mapped = sut.map({ _ in 123 })
        
        // Then
        XCTAssertEqual(mapped.value, 123)
    }
    
    func test_map_successAndThrow_returnFailure() {
        // Given
        let sut = ParserResult.success("hello", [])
        
        // When
        let mapped: ParserResult<Int> = sut.map({ _ throws(ParseError) in
            throw ParseError.expected(label: "Hello")
        })
        
        // Then
        XCTAssertNil(mapped.value)
        XCTAssertEqual(mapped.errors, [.expected(label: "Hello")])
    }
    
    func test_map_failure_returnFailure() {
        // Given
        let sut = ParserResult<String>.failure([])
        
        // When
        let mapped = sut.map({ _ in 123 })
        
        // Then
        XCTAssertNil(mapped.value)
    }
}
