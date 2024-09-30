import XCTest
@testable import Strix

private enum Seed {
    static var state1: ParserState { .init(stream: "123456") }
    static var state2: ParserState { state1.advanced() }
    
    static let intErrors: [ParseError] = [.expected(label: "integer")]
    static let strErrors: [ParseError] = [.expected(label: "string")]
    
    static var intSuccessParser: Parser<Int> { .init({ _ in .success(1, intErrors, state2) }) }
    static var intFailureParser: Parser<Int> { .init({ _ in .failure(intErrors, state2) }) }
    
    static var strSuccessParser: Parser<String> {
        .init({ _ in .success("wow", strErrors, state2) })
    }
    static var strFailureParser: Parser<String> { .init({ _ in .failure(strErrors, state2) }) }
}

private class TextOutput: TextOutputStream {
    var text: String = ""
    
    func write(_ string: String) {
        text += string
    }
}

final class ParserTests: XCTestCase {
    func test_map_success_success() {
        // Given
        let parser = Seed.strSuccessParser
        
        // When
        let mappedParser = parser.map({ $0 })
        let reply = mappedParser.parse(Seed.state1)
        
        // Then
        XCTAssertEqual(reply.result.value, "wow")
    }
    
    func test_map_failure_failure() {
        // Given
        let parser = Seed.strFailureParser
        
        // When
        let mappedParser = parser.map({ $0 })
        let reply = mappedParser.parse(Seed.state1)
        
        // Then
        XCTAssertNil(reply.result.value)
    }
    
    func test_mapWithSubstring_success_success() {
        // Given
        let parser = Seed.strSuccessParser
        var substr: Substring = ""
        
        // When
        let mappedParser = parser.map { v, str -> String in
            substr = str
            return v
        }
        let reply = mappedParser.parse(Seed.state1)
        
        // Then
        XCTAssertEqual(reply.result.value, "wow")
        XCTAssertEqual(substr, "1")
    }
    
    func test_mapWithSubstring_failure_failure() {
        // Given
        let parser = Seed.strFailureParser
        
        // When
        let mappedParser: Parser<Substring> = parser.map({ $1 })
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
    
    func test_flatMapWithSubstring_successAndSuccess_success() {
        // Given
        let parser = Seed.intSuccessParser
        var substr: Substring = ""
        
        // When
        let mappedParser = parser.flatMap { _, str -> Parser<String> in
            substr = str
            return Seed.strSuccessParser
        }
        let reply = mappedParser.parse(Seed.state1)
        
        // Then
        XCTAssertEqual(reply.result.value, "wow")
        XCTAssertEqual(substr, "1")
    }
    
    func test_label_succeed_returnValue() {
        // Given
        let p1: Parser<String> = Parser { state in
            return .success("Hello", [], state.advanced())
        }
        
        // When
        let p: Parser<String> = p1.label("Greeting")
        let reply = p.parse(ParserState(stream: "Input"))
        
        // Then
        XCTAssertEqual(reply.result.value, "Hello")
        XCTAssertEqual(reply.errors, [])
    }
    
    func test_label_failWithoutChange_returnFailureWithLabel() {
        // Given
        let p1: Parser<String> = .fail(message: "Fail")
        
        // When
        let p: Parser<String> = p1.label("Greeting")
        let reply = p.parse(ParserState(stream: "Input"))
        
        // Then
        XCTAssertEqual(reply.errors, [.expected(label: "Greeting")])
    }
    
    func test_satisfying_predicateSucceded_returnValue() throws {
        // Given
        let p1: Parser<Int> = Parser { state in
            return .success(1, state.advanced())
        }
        
        // When
        let p: Parser<Int> = p1.satisfying("positive integer", { $0 > 0 })
        let reply = p.parse(ParserState(stream: "Input"))
        
        // Then
        XCTAssertEqual(reply.state.stream, "nput")
        XCTAssertEqual(reply.result.value, 1)
    }
    
    func test_satisfying_predicateFailed_backtrackAndReturnFailure() throws {
        // Given
        let p1: Parser<Int> = Parser { state in
            return .success(0, state.advanced())
        }
        
        // When
        let p: Parser<Int> = p1.satisfying("positive integer", { $0 > 0 })
        let reply = p.parse(ParserState(stream: "Input"))
        
        // Then
        XCTAssertEqual(reply.state.stream, "Input")
        XCTAssert(reply.result.isFailure)
    }
    
    func test_print() {
        // Given
        let parser = Seed.intSuccessParser
        let textOutput = TextOutput()
        
        // When
        let printableParser = parser.print("int number", to: textOutput)
        _ = printableParser.parse(Seed.state1)
        
        // Then
        XCTAssertEqual(textOutput.text, """
        (1:1:"1"): int number: enter
        (1:2:"2"): int number: leave: success(1, [expected(label: "integer")])
        
        """)
    }
    
    func test_run_success() throws {
        // Given
        let parser = Seed.intSuccessParser
        
        // When, then
        XCTAssertNoThrow(try parser.run("123456"))
    }
    
    func test_run_failure() {
        // Given
        let input = "hello"
        let errors: [ParseError] = Seed.intErrors
        let parser: Parser<Int> = .init { state in
            return .failure(errors, state.advanced())
        }
        
        // When
        XCTAssertThrowsError(try parser.run(input)) { error in
            guard let runError = error as? RunError else {
                XCTFail("Invalid error type: \(type(of: error))")
                return
            }
            
            // Then
            XCTAssertEqual(runError.input, input)
            XCTAssertEqual(runError.position, input.index(after: input.startIndex))
            XCTAssertEqual(runError.underlyingErrors, errors)
        }
    }
}
