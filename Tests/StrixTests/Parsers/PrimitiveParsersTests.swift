import XCTest
@testable import Strix

final class PrimitiveParsersTests: XCTestCase {
    // MARK: - just
    
    func test_just() throws {
        let p: Parser<String> = .just("hello")
        let text = try p.run("Input")
        XCTAssertEqual(text, "hello")
    }
    
    // MARK: - fail
    
    func test_fail() {
        let p: Parser<String> = .fail(message: "Invalid input")
        let reply = p.parse(ParserState(stream: "Input string"))
        XCTAssert(reply.result.isFailure)
        XCTAssertEqual(reply.errors, [.generic(message: "Invalid input")])
    }
    
    // MARK: - discard
    
    func test_discardFirst() throws {
        // Given
        let p1: Parser<Int> = .just(1)
        let p2: Parser<String> = .just("hello")
        
        // When
        let p: Parser<String> = .discardFirst(p1, p2)
        let text = try p.run("Input")
        
        // Then
        XCTAssertEqual(text, "hello")
    }
    
    func test_discardSecond() throws {
        // Given
        let p1: Parser<Int> = .just(1)
        let p2: Parser<String> = .just("hello")
        
        // When
        let p: Parser<Int> = .discardSecond(p1, p2)
        let number = try p.run("Input")
        
        // Then
        XCTAssertEqual(number, 1)
    }
    
    // MARK: - tuple
    
    func test_tuple2() throws {
        // Given
        let p1: Parser<Int> = .just(1)
        let p2: Parser<String> = .just("2")
        
        // When
        let p = Parser.tuple(p1, p2)
        let value = try p.run("Input")
        
        // Then
        XCTAssertEqual(value.0, 1)
        XCTAssertEqual(value.1, "2")
    }
    
    func test_tuple3() throws {
        // Given
        let p1: Parser<Int> = .just(1)
        let p2: Parser<String> = .just("2")
        let p3: Parser<Double> = .just(3.0)
        
        // When
        let p = Parser.tuple(p1, p2, p3)
        let value = try p.run("Input")
        
        // Then
        XCTAssertEqual(value.0, 1)
        XCTAssertEqual(value.1, "2")
        XCTAssertEqual(value.2, 3.0)
    }
    
    func test_tuple4() throws {
        // Given
        let p1: Parser<Int> = .just(1)
        let p2: Parser<String> = .just("2")
        let p3: Parser<Double> = .just(3.0)
        let p4: Parser<Bool> = .just(true)
        
        // When
        let p = Parser.tuple(p1, p2, p3, p4)
        let value = try p.run("Input")
        
        // Then
        XCTAssertEqual(value.0, 1)
        XCTAssertEqual(value.1, "2")
        XCTAssertEqual(value.2, 3.0)
        XCTAssertEqual(value.3, true)
    }
    
    func test_tuple5() throws {
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
        XCTAssertEqual(value.0, 1)
        XCTAssertEqual(value.1, "2")
        XCTAssertEqual(value.2, 3.0)
        XCTAssertEqual(value.3, true)
        XCTAssertEqual(value.4, "c")
    }
    
    func test_tuple6() throws {
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
        XCTAssertEqual(value.0, 1)
        XCTAssertEqual(value.1, "2")
        XCTAssertEqual(value.2, 3.0)
        XCTAssertEqual(value.3, true)
        XCTAssertEqual(value.4, "c")
        XCTAssertEqual(value.5, 6)
    }
    
    func test_tuple7() throws {
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
        XCTAssertEqual(value.0, 1)
        XCTAssertEqual(value.1, "2")
        XCTAssertEqual(value.2, 3.0)
        XCTAssertEqual(value.3, true)
        XCTAssertEqual(value.4, "c")
        XCTAssertEqual(value.5, 6)
        XCTAssertEqual(value.6, "7")
    }
    
    func test_tuple3_failure() {
        // Given
        let p1: Parser<Int> = .just(1)
        let p2: Parser<String> = .fail(message: "invalid input")
        let p3: Parser<Double> = .just(3.0)
        
        // When
        let p = Parser.tuple(p1, p2, p3)
        let reply = p.parse(ParserState(stream: "Input"))
        
        // Then
        XCTAssertFalse(reply.result.isSuccess)
        XCTAssertFalse(reply.errors.isEmpty)
    }
    
    // MARK: - alternative
    
    func test_alternative_leftSuccess_returnLeftReply() {
        // Given
        let p1: Parser<Int> = .just(1)
        let p2: Parser<Int> = .just(2)
        
        // When
        let p: Parser<Int> = .alternative(p1, p2)
        let reply = p.parse(ParserState(stream: "Input"))
        
        // Then
        XCTAssertEqual(reply.result.value, 1)
    }
    
    func test_alternative_leftFailWithoutChange_returnRightReply() {
        // Given
        let p1: Parser<Int> = .fail(message: "Invalid input")
        let p2: Parser<Int> = .just(2)
        
        // When
        let p: Parser<Int> = .alternative(p1, p2)
        let reply = p.parse(ParserState(stream: "Input"))
        
        // Then
        XCTAssertEqual(reply.result.value, 2)
    }
    
    func test_alternative_leftFailWithChange_returnLeftReply() {
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
        XCTAssert(reply.result.isFailure)
        XCTAssertEqual(reply.errors, [.generic(message: "Invalid input")])
    }
    
    // MARK: - oneOf
    
    func test_oneOf_returnFirstSuccess() {
        // Given
        let p1: Parser<Int> = .fail(message: "Fail 1")
        let p2: Parser<Int> = .just(2)
        let p3: Parser<Int> = .just(3)
        
        // When
        let p: Parser<Int> = .one(of: [p1, p2, p3])
        let reply = p.parse(ParserState(stream: "Input"))
        
        // Then
        XCTAssertEqual(reply.result.value, 2)
    }
    
    func test_oneOf_failWithChange_returnFailure() {
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
        XCTAssert(reply.result.isFailure)
    }
    
    func test_oneOf_failWithoutChange_mergeErrors() {
        // Given
        let p1: Parser<Int> = .fail(message: "Fail 1")
        let p2: Parser<Int> = .fail(message: "Fail 2")
        let p3: Parser<Int> = .fail(message: "Fail 3")
        
        // When
        let p: Parser<Int> = .one(of: [p1, p2, p3])
        let reply = p.parse(ParserState(stream: "Input"))
        
        // Then
        XCTAssertEqual(reply.errors, [.generic(message: "Fail 1"),
                                      .generic(message: "Fail 2"),
                                      .generic(message: "Fail 3")])
    }
    
    // MARK: - optional
    
    func test_optional_succeed_returnValue() throws {
        // Given
        let p1: Parser<String> = .just("hello")
        
        // When
        let p: Parser<String?> = .optional(p1)
        let reply = p.parse(ParserState(stream: "Input"))
        let value: String? = try XCTUnwrap(reply.result.value)
        
        // Then
        XCTAssert(reply.result.isSuccess)
        
        XCTAssertEqual(value, "hello")
    }
    
    func test_optional_fail_returnNil() throws {
        // Given
        let p1: Parser<String> = .fail(message: "Fail")
        
        // When
        let p: Parser<String?> = .optional(p1)
        let reply = p.parse(ParserState(stream: "Input"))
        let value: String? = try XCTUnwrap(reply.result.value)
        
        // Then
        XCTAssert(reply.result.isSuccess)
        XCTAssertNil(value)
    }
    
    // MARK: - notEmpty
    
    func test_notEmpty_succeedWithChange_succeed() {
        // Given
        let p1: Parser<String> = Parser { state in
            return .success("hello", state.advanced())
        }
        
        // When
        let p: Parser<String> = .notEmpty(p1)
        let reply = p.parse(ParserState(stream: "Input"))
        
        // Then
        XCTAssertEqual(reply.result.value, "hello")
    }
    
    func test_notEmpty_succeedWithoutChange_fail() {
        // Given
        let p1: Parser<String> = .just("hello")
        
        // When
        let p: Parser<String> = .notEmpty(p1)
        let reply = p.parse(ParserState(stream: "Input"))
        
        // Then
        XCTAssert(reply.result.isFailure)
    }
    
    // MARK: - attempt
    
    func test_attempt_succeed_consumeInput() {
        // Given
        let p1: Parser<String> = Parser { state in
            return .success("hello", state.advanced())
        }
        
        // When
        let p: Parser<String> = .attempt(p1)
        let reply = p.parse(ParserState(stream: "Input"))
        
        // Then
        XCTAssertEqual(reply.result.value, "hello")
        XCTAssertEqual(reply.state.stream, "nput")
    }
    
    func test_attempt_fail_backtrack() {
        // Given
        let p1: Parser<String> = Parser { state in
            return .failure([], state.advanced())
        }
        
        // When
        let p: Parser<String> = .attempt(p1)
        let reply = p.parse(ParserState(stream: "Input"))
        
        // Then
        XCTAssertEqual(reply.state.stream, "Input")
    }
    
    func test_attemptWithLabel_succeed_consumeInput() {
        // Given
        let p1: Parser<String> = Parser { state in
            return .success("hello", state.advanced())
        }
        
        // When
        let p: Parser<String> = .attempt(p1, label: "greeting")
        let reply = p.parse(ParserState(stream: "Input"))
        
        // Then
        XCTAssertEqual(reply.result.value, "hello")
        XCTAssertEqual(reply.state.stream, "nput")
    }
    
    func test_attemptWithLabel_failWithoutChange_returnExpectedError() {
        // Given
        let p1: Parser<String> = .fail(message: "invalid input")
        
        // When
        let p: Parser<String> = .attempt(p1, label: "greeting")
        let reply = p.parse(ParserState(stream: "Input"))
        
        // Then
        XCTAssertEqual(reply.errors, [.expected(label: "greeting")])
    }
    
    func test_attemptWithLabel_failWithChange_backtrackAndReturnCompoundError() {
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
        XCTAssertEqual(reply.state.stream, input)
        XCTAssertEqual(reply.errors,
                       [.compound(label: "greeting", position: secondIndex, errors: p1Errors)])
    }
    
    // MARK: - lookAhead
    
    func test_lookAhead_succeed_backtrackAndReturnValue() {
        // Given
        let p1: Parser<String> = Parser { state in
            return .success("hello", state.advanced())
        }
        
        // When
        let p: Parser<String> = .lookAhead(p1)
        let reply = p.parse(ParserState(stream: "Input"))
        
        // Then
        XCTAssertEqual(reply.result.value, "hello")
        XCTAssertEqual(reply.state.stream, "Input")
    }
    
    func test_lookAhead_failWithoutChange_backtrack() {
        // Given
        let p1Errors = [ParseError.generic(message: "invalid input")]
        let p1: Parser<String> = Parser { state in
            return .failure(p1Errors, state)
        }
        
        // When
        let p: Parser<String> = .lookAhead(p1)
        let reply = p.parse(ParserState(stream: "Input"))
        
        // Then
        XCTAssertEqual(reply.state.stream, "Input")
        XCTAssertEqual(reply.errors, p1Errors)
    }
    
    func test_lookAhead_failWithChange_backtrackAndReturnNestedError() {
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
        XCTAssertEqual(reply.state.stream, input)
        XCTAssertEqual(reply.errors, [.nested(position: secondIndex, errors: p1Errors)])
    }
    
    // MARK: - recursive
    
    func test_recursive() throws {
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
        
        XCTAssertEqual(parsedContainer, expectedContainer)
    }
    
    // MARK: - endOfStream
    
    func test_endOfStream_atEOS_returnSuccess() {
        // Given
        let input = "Input"
        let endState = ParserState(stream: input[input.endIndex...])
        
        // When
        let p: Parser<Void> = .endOfStream
        let reply = p.parse(endState)
        
        // Then
        XCTAssert(reply.result.isSuccess)
    }
    
    func test_endOfStream_beforeEOS_returnFailure() {
        // Given
        let input = "Input"
        let endState = ParserState(stream: input[input.index(before: input.endIndex)...])
        
        // When
        let p: Parser<Void> = .endOfStream
        let reply = p.parse(endState)
        
        // Then
        XCTAssert(reply.result.isFailure)
    }
    
    // MARK: - follow
    
    func test_follow_succeed_backtrackAndSucceed() {
        // Given
        let p1: Parser<String> = Parser { state in
            return .success("hello", state.advanced())
        }
        
        // When
        let p: Parser<Void> = .follow(p1, label: "greeting")
        let reply = p.parse(ParserState(stream: "Input"))
        
        // Then
        XCTAssert(reply.result.isSuccess)
        XCTAssertEqual(reply.state.stream, "Input")
    }
    
    func test_follow_fail_backtrackAndReturnExpectedError() {
        // Given
        let p1: Parser<String> = Parser { state in
            return .failure([], state.advanced())
        }
        
        // When
        let p: Parser<Void> = .follow(p1, label: "greeting")
        let reply = p.parse(ParserState(stream: "Input"))
        
        // Then
        XCTAssert(reply.result.isFailure)
        XCTAssertEqual(reply.state.stream, "Input")
        XCTAssertEqual(reply.errors, [.expected(label: "greeting")])
    }
    
    // MARK: - not
    
    func test_not_succeed_backtrackAndReturnUnexpectedError() {
        // Given
        let p1: Parser<String> = Parser { state in
            return .success("hello", state.advanced())
        }
        
        // When
        let p: Parser<Void> = .not(p1, label: "greeting")
        let reply = p.parse(ParserState(stream: "Input"))
        
        // Then
        XCTAssert(reply.result.isFailure)
        XCTAssertEqual(reply.state.stream, "Input")
        XCTAssertEqual(reply.errors, [.unexpected(label: "greeting")])
    }
    
    func test_not_fail_backtrackAndSucceed() {
        // Given
        let p1: Parser<String> = Parser { state in
            return .failure([], state.advanced())
        }
        
        // When
        let p: Parser<Void> = .not(p1, label: "greeting")
        let reply = p.parse(ParserState(stream: "Input"))
        
        // Then
        XCTAssert(reply.result.isSuccess)
        XCTAssertEqual(reply.state.stream, "Input")
    }
    
    func test_updateUserInfo() {
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
        XCTAssertEqual(reply.state.userInfo[GreetingUserInfoKey.self], "hello")
    }
    
    func test_satisfyUserInfo_succeed_returnSuccess() {
        // Given
        let p: Parser<Void> = .satisfyUserInfo("Nested tags are not allowed.", { _ in true })
        
        // When
        let reply = p.parse(ParserState(stream: "Input"))
        
        // Then
        XCTAssert(reply.result.isSuccess)
    }
    
    func test_satisfyUserInfo_failed_returnFailure() {
        // Given
        let message = "Nested tags are not allowed."
        let p: Parser<Void> = .satisfyUserInfo(message, { _ in false })
        
        // When
        let reply = p.parse(ParserState(stream: "Input"))
        
        // Then
        XCTAssert(reply.result.isFailure)
        XCTAssertEqual(reply.state.stream, "Input")
        XCTAssertEqual(reply.errors, [.generic(message: message)])
    }
}
