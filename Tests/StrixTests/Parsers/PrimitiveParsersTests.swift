import Testing
@testable import Strix

@Suite struct PrimitiveParsersTests {
    // MARK: - just
    
    @Test func just() throws {
        let p: Parser<String> = .just("hello")
        let text = try p.run("Input")
        #expect(text == "hello")
    }
    
    // MARK: - fail
    
    @Test func fail() {
        let p: Parser<String> = .fail(message: "Invalid input")
        let reply = p.parse(ParserState(stream: "Input string"))
        #expect(reply.result.isFailure)
        #expect(reply.errors == [.generic(message: "Invalid input")])
    }
    
    // MARK: - discard
    
    @Test func discardFirst() throws {
        // Given
        let p1: Parser<Int> = .just(1)
        let p2: Parser<String> = .just("hello")
        
        // When
        let p: Parser<String> = .discardFirst(p1, p2)
        let text = try p.run("Input")
        
        // Then
        #expect(text == "hello")
    }
    
    @Test func discardSecond() throws {
        // Given
        let p1: Parser<Int> = .just(1)
        let p2: Parser<String> = .just("hello")
        
        // When
        let p: Parser<Int> = .discardSecond(p1, p2)
        let number = try p.run("Input")
        
        // Then
        #expect(number == 1)
    }
    
    // MARK: - tuple
    
    @Test func tuple2() throws {
        // Given
        let p1: Parser<Int> = .just(1)
        let p2: Parser<String> = .just("2")
        
        // When
        let p = Parser.tuple(p1, p2)
        let value = try p.run("Input")
        
        // Then
        #expect(value.0 == 1)
        #expect(value.1 == "2")
    }
    
    @Test func tuple3() throws {
        // Given
        let p1: Parser<Int> = .just(1)
        let p2: Parser<String> = .just("2")
        let p3: Parser<Double> = .just(3.0)
        
        // When
        let p = Parser.tuple(p1, p2, p3)
        let value = try p.run("Input")
        
        // Then
        #expect(value.0 == 1)
        #expect(value.1 == "2")
        #expect(value.2 == 3.0)
    }
    
    @Test func tuple4() throws {
        // Given
        let p1: Parser<Int> = .just(1)
        let p2: Parser<String> = .just("2")
        let p3: Parser<Double> = .just(3.0)
        let p4: Parser<Bool> = .just(true)
        
        // When
        let p = Parser.tuple(p1, p2, p3, p4)
        let value = try p.run("Input")
        
        // Then
        #expect(value.0 == 1)
        #expect(value.1 == "2")
        #expect(value.2 == 3.0)
        #expect(value.3 == true)
    }
    
    @Test func tuple5() throws {
        // Given
        let p1: Parser<Int> = .just(1)
        let p2: Parser<String> = .just("2")
        let p3: Parser<Double> = .just(3.0)
        let p4: Parser<Bool> = .just(true)
        let p5: Parser<Character> = .just("c")
        
        // When
        let p = Parser.tuple(p1, p2, p3, p4, p5)
        let value = try p.run("Input")
        
        // Then
        #expect(value.0 == 1)
        #expect(value.1 == "2")
        #expect(value.2 == 3.0)
        #expect(value.3 == true)
        #expect(value.4 == "c")
    }
    
    @Test func tuple6() throws {
        // Given
        let p1: Parser<Int> = .just(1)
        let p2: Parser<String> = .just("2")
        let p3: Parser<Double> = .just(3.0)
        let p4: Parser<Bool> = .just(true)
        let p5: Parser<Character> = .just("c")
        let p6: Parser<Int> = .just(6)
        
        // When
        let p = Parser.tuple(p1, p2, p3, p4, p5, p6)
        let value = try p.run("Input")
        
        // Then
        #expect(value.0 == 1)
        #expect(value.1 == "2")
        #expect(value.2 == 3.0)
        #expect(value.3 == true)
        #expect(value.4 == "c")
        #expect(value.5 == 6)
    }
    
    @Test func tuple7() throws {
        // Given
        let p1: Parser<Int> = .just(1)
        let p2: Parser<String> = .just("2")
        let p3: Parser<Double> = .just(3.0)
        let p4: Parser<Bool> = .just(true)
        let p5: Parser<Character> = .just("c")
        let p6: Parser<Int> = .just(6)
        let p7: Parser<String> = .just("7")
        
        // When
        let p = Parser.tuple(p1, p2, p3, p4, p5, p6, p7)
        let value = try p.run("Input")
        
        // Then
        #expect(value.0 == 1)
        #expect(value.1 == "2")
        #expect(value.2 == 3.0)
        #expect(value.3 == true)
        #expect(value.4 == "c")
        #expect(value.5 == 6)
        #expect(value.6 == "7")
    }
    
    @Test func tuple3_failure() {
        // Given
        let p1: Parser<Int> = .just(1)
        let p2: Parser<String> = .fail(message: "invalid input")
        let p3: Parser<Double> = .just(3.0)
        
        // When
        let p = Parser.tuple(p1, p2, p3)
        let reply = p.parse(ParserState(stream: "Input"))
        
        // Then
        #expect(!reply.result.isSuccess)
        #expect(!reply.errors.isEmpty)
    }
    
    // MARK: - alternative
    
    @Test func alternative_leftSuccess_returnLeftReply() {
        // Given
        let p1: Parser<Int> = .just(1)
        let p2: Parser<Int> = .just(2)
        
        // When
        let p: Parser<Int> = .alternative(p1, p2)
        let reply = p.parse(ParserState(stream: "Input"))
        
        // Then
        #expect(reply.result.value == 1)
    }
    
    @Test func alternative_leftFailWithoutChange_returnRightReply() {
        // Given
        let p1: Parser<Int> = .fail(message: "Invalid input")
        let p2: Parser<Int> = .just(2)
        
        // When
        let p: Parser<Int> = .alternative(p1, p2)
        let reply = p.parse(ParserState(stream: "Input"))
        
        // Then
        #expect(reply.result.value == 2)
    }
    
    @Test func alternative_leftFailWithChange_returnLeftReply() {
        // Given
        let p1: Parser<Int> = Parser { state in
            return .failure([.generic(message: "Invalid input")],
                            state.advanced())
        }
        let p2: Parser<Int> = .just(2)
        
        // When
        let p: Parser<Int> = .alternative(p1, p2)
        let reply = p.parse(ParserState(stream: "Input"))
        
        // Then
        #expect(reply.result.isFailure)
        #expect(reply.errors == [.generic(message: "Invalid input")])
    }
    
    // MARK: - oneOf
    
    @Test func oneOf_returnFirstSuccess() {
        // Given
        let p1: Parser<Int> = .fail(message: "Fail 1")
        let p2: Parser<Int> = .just(2)
        let p3: Parser<Int> = .just(3)
        
        // When
        let p: Parser<Int> = .one(of: [p1, p2, p3])
        let reply = p.parse(ParserState(stream: "Input"))
        
        // Then
        #expect(reply.result.value == 2)
    }
    
    @Test func oneOf_failWithChange_returnFailure() {
        // Given
        let p1: Parser<Int> = .fail(message: "Fail 1")
        let p2: Parser<Int> = Parser { state in
            return .failure([.generic(message: "Fail 3")],
                            state.advanced())
        }
        let p3: Parser<Int> = .just(3)
        
        // When
        let p: Parser<Int> = .one(of: [p1, p2, p3])
        let reply = p.parse(ParserState(stream: "Input"))
        
        // Then
        #expect(reply.result.isFailure)
    }
    
    @Test func oneOf_failWithoutChange_mergeErrors() {
        // Given
        let p1: Parser<Int> = .fail(message: "Fail 1")
        let p2: Parser<Int> = .fail(message: "Fail 2")
        let p3: Parser<Int> = .fail(message: "Fail 3")
        
        // When
        let p: Parser<Int> = .one(of: [p1, p2, p3])
        let reply = p.parse(ParserState(stream: "Input"))
        
        // Then
        #expect(reply.errors == [
            .generic(message: "Fail 1"),
            .generic(message: "Fail 2"),
            .generic(message: "Fail 3")
        ])
    }
    
    // MARK: - optional
    
    @Test func optional_succeed_returnValue() throws {
        // Given
        let p1: Parser<String> = .just("hello")
        
        // When
        let p: Parser<String?> = .optional(p1)
        let reply = p.parse(ParserState(stream: "Input"))
        let value: String? = try #require(reply.result.value)
        
        // Then
        #expect(reply.result.isSuccess)
        
        #expect(value == "hello")
    }
    
    @Test func optional_fail_returnNil() throws {
        // Given
        let p1: Parser<String> = .fail(message: "Fail")
        
        // When
        let p: Parser<String?> = .optional(p1)
        let reply = p.parse(ParserState(stream: "Input"))
        let value: String? = try #require(reply.result.value)
        
        // Then
        #expect(reply.result.isSuccess)
        #expect(value == nil)
    }
    
    // MARK: - notEmpty
    
    @Test func notEmpty_succeedWithChange_succeed() {
        // Given
        let p1: Parser<String> = Parser { state in
            return .success("hello", state.advanced())
        }
        
        // When
        let p: Parser<String> = .notEmpty(p1)
        let reply = p.parse(ParserState(stream: "Input"))
        
        // Then
        #expect(reply.result.value == "hello")
    }
    
    @Test func notEmpty_succeedWithoutChange_fail() {
        // Given
        let p1: Parser<String> = .just("hello")
        
        // When
        let p: Parser<String> = .notEmpty(p1)
        let reply = p.parse(ParserState(stream: "Input"))
        
        // Then
        #expect(reply.result.isFailure)
    }
    
    // MARK: - attempt
    
    @Test func attempt_succeed_consumeInput() {
        // Given
        let p1: Parser<String> = Parser { state in
            return .success("hello", state.advanced())
        }
        
        // When
        let p: Parser<String> = .attempt(p1)
        let reply = p.parse(ParserState(stream: "Input"))
        
        // Then
        #expect(reply.result.value == "hello")
        #expect(reply.state.stream == "nput")
    }
    
    @Test func attempt_fail_backtrack() {
        // Given
        let p1: Parser<String> = Parser { state in
            return .failure([], state.advanced())
        }
        
        // When
        let p: Parser<String> = .attempt(p1)
        let reply = p.parse(ParserState(stream: "Input"))
        
        // Then
        #expect(reply.state.stream == "Input")
    }
    
    @Test func attemptWithLabel_succeed_consumeInput() {
        // Given
        let p1: Parser<String> = Parser { state in
            return .success("hello", state.advanced())
        }
        
        // When
        let p: Parser<String> = .attempt(p1, label: "greeting")
        let reply = p.parse(ParserState(stream: "Input"))
        
        // Then
        #expect(reply.result.value == "hello")
        #expect(reply.state.stream == "nput")
    }
    
    @Test func attemptWithLabel_failWithoutChange_returnExpectedError() {
        // Given
        let p1: Parser<String> = .fail(message: "invalid input")
        
        // When
        let p: Parser<String> = .attempt(p1, label: "greeting")
        let reply = p.parse(ParserState(stream: "Input"))
        
        // Then
        #expect(reply.errors == [.expected(label: "greeting")])
    }
    
    @Test func attemptWithLabel_failWithChange_backtrackAndReturnCompoundError() {
        // Given
        let input: Substring = "Input"
        let secondIndex = input.index(after: input.startIndex)
        let p1Errors = [ParseError.generic(message: "invalid input")]
        let p1: Parser<String> = Parser { state in
            return .failure(p1Errors, state.withStream(input[secondIndex...]))
        }
        
        // When
        let p: Parser<String> = .attempt(p1, label: "greeting")
        let reply = p.parse(ParserState(stream: input))
        
        // Then
        #expect(reply.state.stream == input)
        #expect(reply.errors == [
            .compound(label: "greeting", position: secondIndex, errors: p1Errors)
        ])
    }
    
    // MARK: - lookAhead
    
    @Test func lookAhead_succeed_backtrackAndReturnValue() {
        // Given
        let p1: Parser<String> = Parser { state in
            return .success("hello", state.advanced())
        }
        
        // When
        let p: Parser<String> = .lookAhead(p1)
        let reply = p.parse(ParserState(stream: "Input"))
        
        // Then
        #expect(reply.result.value == "hello")
        #expect(reply.state.stream == "Input")
    }
    
    @Test func lookAhead_failWithoutChange_backtrack() {
        // Given
        let p1Errors = [ParseError.generic(message: "invalid input")]
        let p1: Parser<String> = Parser { state in
            return .failure(p1Errors, state)
        }
        
        // When
        let p: Parser<String> = .lookAhead(p1)
        let reply = p.parse(ParserState(stream: "Input"))
        
        // Then
        #expect(reply.state.stream == "Input")
        #expect(reply.errors == p1Errors)
    }
    
    @Test func lookAhead_failWithChange_backtrackAndReturnNestedError() {
        // Given
        let input: Substring = "Input"
        let secondIndex = input.index(after: input.startIndex)
        let p1Errors = [ParseError.generic(message: "invalid input")]
        let p1: Parser<String> = Parser { state in
            return .failure(p1Errors, state.withStream(input[secondIndex...]))
        }
        
        // When
        let p: Parser<String> = .lookAhead(p1)
        let reply = p.parse(ParserState(stream: input))
        
        // Then
        #expect(reply.state.stream == input)
        #expect(reply.errors == [.nested(position: secondIndex, errors: p1Errors)])
    }
    
    // MARK: - recursive
    
    @Test func recursive() throws {
        enum Container: Equatable {
            indirect case wrapper(Container)
            case value(Int)
        }
        
        let containerParser: Parser<Container> = .recursive { placeholder in
            let wrapperParser: Parser<Container> =
                (.character("(") *> placeholder <* .character(")")).map({ .wrapper($0) })
            
            let valueParser: Parser<Container> = Parser.int().map({ .value($0) })
            
            return wrapperParser <|> valueParser
        }
        
        let parsedContainer: Container = try containerParser.run("((5))")
        let expectedContainer: Container = .wrapper(.wrapper(.value(5)))
        
        #expect(parsedContainer == expectedContainer)
    }
    
    // MARK: - match
    
    @Test func matchRegex_succeed() throws {
        // Given
        let input = "a123b"
        let regex = try Regex<Substring>("[0-9]+")
        let state = ParserState(stream: input[input.index(after: input.startIndex)...])
        
        // When
        let p: Parser<Regex<Substring>.Match> = Parser.match(regex, label: "number")
        let reply = p.parse(state)
        
        // Then
        #expect(reply.result.value?.output == "123")
        #expect(reply.state.stream == "b")
    }
    
    @Test func matchRegex_fail() throws {
        // Given
        let input = "a123b"
        let regex = try Regex<Substring>("[0-9]+")
        let state = ParserState(stream: input[input.startIndex...])
        
        // When
        let p: Parser<Regex<Substring>.Match> = Parser.match(regex, label: "number")
        let reply = p.parse(state)
        
        // Then
        #expect(reply.result.isFailure)
        #expect(reply.state.stream == "a123b")
    }
    
    // MARK: - endOfStream
    
    @Test func endOfStream_atEOS_returnSuccess() {
        // Given
        let input = "Input"
        let endState = ParserState(stream: input[input.endIndex...])
        
        // When
        let p: Parser<Void> = .endOfStream
        let reply = p.parse(endState)
        
        // Then
        #expect(reply.result.isSuccess)
    }
    
    @Test func endOfStream_beforeEOS_returnFailure() {
        // Given
        let input = "Input"
        let endState = ParserState(stream: input[input.index(before: input.endIndex)...])
        
        // When
        let p: Parser<Void> = .endOfStream
        let reply = p.parse(endState)
        
        // Then
        #expect(reply.result.isFailure)
    }
    
    // MARK: - follow
    
    @Test func follow_succeed_backtrackAndSucceed() {
        // Given
        let p1: Parser<String> = Parser { state in
            return .success("hello", state.advanced())
        }
        
        // When
        let p: Parser<Void> = .follow(p1, label: "greeting")
        let reply = p.parse(ParserState(stream: "Input"))
        
        // Then
        #expect(reply.result.isSuccess)
        #expect(reply.state.stream == "Input")
    }
    
    @Test func follow_fail_backtrackAndReturnExpectedError() {
        // Given
        let p1: Parser<String> = Parser { state in
            return .failure([], state.advanced())
        }
        
        // When
        let p: Parser<Void> = .follow(p1, label: "greeting")
        let reply = p.parse(ParserState(stream: "Input"))
        
        // Then
        #expect(reply.result.isFailure)
        #expect(reply.state.stream == "Input")
        #expect(reply.errors == [.expected(label: "greeting")])
    }
    
    // MARK: - not
    
    @Test func not_succeed_backtrackAndReturnUnexpectedError() {
        // Given
        let p1: Parser<String> = Parser { state in
            return .success("hello", state.advanced())
        }
        
        // When
        let p: Parser<Void> = .not(p1, label: "greeting")
        let reply = p.parse(ParserState(stream: "Input"))
        
        // Then
        #expect(reply.result.isFailure)
        #expect(reply.state.stream == "Input")
        #expect(reply.errors == [.unexpected(label: "greeting")])
    }
    
    @Test func not_fail_backtrackAndSucceed() {
        // Given
        let p1: Parser<String> = Parser { state in
            return .failure([], state.advanced())
        }
        
        // When
        let p: Parser<Void> = .not(p1, label: "greeting")
        let reply = p.parse(ParserState(stream: "Input"))
        
        // Then
        #expect(reply.result.isSuccess)
        #expect(reply.state.stream == "Input")
    }
    
    @Test func updateUserInfo() {
        struct GreetingUserInfoKey: UserInfoKey {
            static let defaultValue: String? = nil
        }
        
        // Given
        let p: Parser<Void> = .updateUserInfo { userInfo in
            userInfo[GreetingUserInfoKey.self] = "hello"
        }
        
        // When
        let reply = p.parse(ParserState(stream: "Input"))
        
        // Then
        #expect(reply.state.userInfo[GreetingUserInfoKey.self] == "hello")
    }
    
    @Test func satisfyUserInfo_succeed_returnSuccess() {
        // Given
        let p: Parser<Void> = .satisfyUserInfo("Nested tags are not allowed.", { _ in true })
        
        // When
        let reply = p.parse(ParserState(stream: "Input"))
        
        // Then
        #expect(reply.result.isSuccess)
    }
    
    @Test func satisfyUserInfo_failed_returnFailure() {
        // Given
        let message = "Nested tags are not allowed."
        let p: Parser<Void> = .satisfyUserInfo(message, { _ in false })
        
        // When
        let reply = p.parse(ParserState(stream: "Input"))
        
        // Then
        #expect(reply.result.isFailure)
        #expect(reply.state.stream == "Input")
        #expect(reply.errors == [.generic(message: message)])
    }
}
