import XCTest
@testable import Strix2

private enum Seed {
    static let state1: ParserState = .init(stream: "123456")
    static let state2: ParserState = state1.withStream(state1.stream.dropFirst())
    
    static let intErrors: [ParseError] = [.expected(label: "integer")]
    static let strErrors: [ParseError] = [.expected(label: "string")]
    
    static let intSuccessParser: Parser<Int> = .init({ _ in .success(1, state2, intErrors) })
    static let intFailureParser: Parser<Int> = .init({ _ in .failure(state2, intErrors) })
    
    static let strSuccessParser: Parser<String> = .init({ _ in .success("wow", state2, strErrors)})
    static let strFailureParser: Parser<String> = .init({ _ in .failure(state2, strErrors) })
}

final class ParserTests: XCTestCase {
    func test_map_success_success() {
        // Given
        let parser = Seed.intSuccessParser
        
        // When
        let mappedParser = parser.map({ _ in "hello" })
        let reply = mappedParser.parse(Seed.state1)
        
        // Then
        XCTAssertEqual(reply.result.value, "hello")
    }
    
    func test_map_failure_failure() {
        // Given
        let parser = Seed.intFailureParser
        
        // When
        let mappedParser = parser.map({ _ in "hello" })
        let reply = mappedParser.parse(Seed.state1)
        
        // Then
        XCTAssertNil(reply.result.value)
    }
    
    func test_flatMap_successAndSuccess_success() {
        // Given
        let parser = Seed.intSuccessParser
        
        // When
        let mappedParser = parser.flatMap({ _ in Seed.strSuccessParser })
        let reply = mappedParser.parse(Seed.state1)
        
        // Then
        XCTAssertEqual(reply.result.value, "wow")
    }
    
    func test_flatMap_successAndFailure_failure() {
        // Given
        let parser = Seed.intSuccessParser
        
        // When
        let mappedParser = parser.flatMap({ _ in Seed.strFailureParser })
        let reply = mappedParser.parse(Seed.state1)
        
        // Then
        XCTAssertNil(reply.result.value)
    }
    
    func test_flatMap_failureAndSuccess_failure() {
        // Given
        let parser = Seed.intFailureParser
        
        // When
        let mappedParser = parser.flatMap({ _ in Seed.strSuccessParser })
        let reply = mappedParser.parse(Seed.state1)
        
        // Then
        XCTAssertNil(reply.result.value)
    }
}
