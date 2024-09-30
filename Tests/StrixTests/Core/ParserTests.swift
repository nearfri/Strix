import Testing
@testable import Strix

private enum Fixture {
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

@Suite struct ParserTests {
    @Test func map_success_success() {
        // Given
        let parser = Fixture.strSuccessParser
        
        // When
        let mappedParser = parser.map({ $0 })
        let reply = mappedParser.parse(Fixture.state1)
        
        // Then
        #expect(reply.result.value == "wow")
    }
    
    @Test func map_failure_failure() {
        // Given
        let parser = Fixture.strFailureParser
        
        // When
        let mappedParser = parser.map({ $0 })
        let reply = mappedParser.parse(Fixture.state1)
        
        // Then
        #expect(reply.result.value == nil)
    }
    
    @Test func mapWithSubstring_success_success() {
        // Given
        let parser = Fixture.strSuccessParser
        var substr: Substring = ""
        
        // When
        let mappedParser = parser.map { v, str -> String in
            substr = str
            return v
        }
        let reply = mappedParser.parse(Fixture.state1)
        
        // Then
        #expect(reply.result.value == "wow")
        #expect(substr == "1")
    }
    
    @Test func mapWithSubstring_failure_failure() {
        // Given
        let parser = Fixture.strFailureParser
        
        // When
        let mappedParser: Parser<Substring> = parser.map({ $1 })
        let reply = mappedParser.parse(Fixture.state1)
        
        // Then
        #expect(reply.result.value == nil)
    }
    
    @Test func flatMap_successAndSuccess_success() {
        // Given
        let parser = Fixture.intSuccessParser
        
        // When
        let mappedParser = parser.flatMap({ _ in Fixture.strSuccessParser })
        let reply = mappedParser.parse(Fixture.state1)
        
        // Then
        #expect(reply.result.value == "wow")
    }
    
    @Test func flatMap_successAndFailure_failure() {
        // Given
        let parser = Fixture.intSuccessParser
        
        // When
        let mappedParser = parser.flatMap({ _ in Fixture.strFailureParser })
        let reply = mappedParser.parse(Fixture.state1)
        
        // Then
        #expect(reply.result.value == nil)
    }
    
    @Test func flatMap_failureAndSuccess_failure() {
        // Given
        let parser = Fixture.intFailureParser
        
        // When
        let mappedParser = parser.flatMap({ _ in Fixture.strSuccessParser })
        let reply = mappedParser.parse(Fixture.state1)
        
        // Then
        #expect(reply.result.value == nil)
    }
    
    @Test func flatMapWithSubstring_successAndSuccess_success() {
        // Given
        let parser = Fixture.intSuccessParser
        var substr: Substring = ""
        
        // When
        let mappedParser = parser.flatMap { _, str -> Parser<String> in
            substr = str
            return Fixture.strSuccessParser
        }
        let reply = mappedParser.parse(Fixture.state1)
        
        // Then
        #expect(reply.result.value == "wow")
        #expect(substr == "1")
    }
    
    @Test func label_succeed_returnValue() {
        // Given
        let p1: Parser<String> = Parser { state in
            return .success("Hello", [], state.advanced())
        }
        
        // When
        let p: Parser<String> = p1.label("Greeting")
        let reply = p.parse(ParserState(stream: "Input"))
        
        // Then
        #expect(reply.result.value == "Hello")
        #expect(reply.errors == [])
    }
    
    @Test func label_failWithoutChange_returnFailureWithLabel() {
        // Given
        let p1: Parser<String> = .fail(message: "Fail")
        
        // When
        let p: Parser<String> = p1.label("Greeting")
        let reply = p.parse(ParserState(stream: "Input"))
        
        // Then
        #expect(reply.errors == [.expected(label: "Greeting")])
    }
    
    @Test func satisfying_predicateSucceded_returnValue() throws {
        // Given
        let p1: Parser<Int> = Parser { state in
            return .success(1, state.advanced())
        }
        
        // When
        let p: Parser<Int> = p1.satisfying("positive integer", { $0 > 0 })
        let reply = p.parse(ParserState(stream: "Input"))
        
        // Then
        #expect(reply.state.stream == "nput")
        #expect(reply.result.value == 1)
    }
    
    @Test func satisfying_predicateFailed_backtrackAndReturnFailure() {
        // Given
        let p1: Parser<Int> = Parser { state in
            return .success(0, state.advanced())
        }
        
        // When
        let p: Parser<Int> = p1.satisfying("positive integer", { $0 > 0 })
        let reply = p.parse(ParserState(stream: "Input"))
        
        // Then
        #expect(reply.state.stream == "Input")
        #expect(reply.result.isFailure)
    }
    
    @Test func print() {
        // Given
        let parser = Fixture.intSuccessParser
        let textOutput = TextOutput()
        
        // When
        let printableParser = parser.print("int number", to: textOutput)
        _ = printableParser.parse(Fixture.state1)
        
        // Then
        #expect(textOutput.text == """
            (1:1:"1"): int number: enter
            (1:2:"2"): int number: leave: success(1, [expected(label: "integer")])
            
            """)
    }
    
    @Test func run_success() {
        // Given
        let parser = Fixture.intSuccessParser
        
        // When, then
        #expect(throws: Never.self, performing: {
            try parser.run("123456")
        })
    }
    
    @Test func run_failure() throws {
        // Given
        let input = "hello"
        let errors: [ParseError] = Fixture.intErrors
        let parser: Parser<Int> = .init { state in
            return .failure(errors, state.advanced())
        }
        
        let expectedError = RunError(
            input: input,
            position: input.index(after: input.startIndex),
            underlyingErrors: errors)
        
        // When, then
        #expect(throws: expectedError, performing: {
            try parser.run(input)
        })
    }
}
