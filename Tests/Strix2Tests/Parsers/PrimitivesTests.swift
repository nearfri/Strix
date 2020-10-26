import XCTest
@testable import Strix2

final class PrimitivesTests: XCTestCase {
    func test_just() throws {
        let p: Parser<String> = .just("hello")
        let text = try p.run("Input")
        XCTAssertEqual(text, "hello")
    }
    
    func test_fail() {
        let p: Parser<String> = .fail(message: "Invalid input")
        let reply = p.parse(ParserState(stream: "Input string"))
        XCTAssertFalse(reply.result.isSuccess)
        XCTAssertEqual(reply.errors, [.generic(message: "Invalid input")])
    }
    
    func test_discardLeft() throws {
        // Given
        let p1: Parser<Int> = .just(1)
        let p2: Parser<String> = .just("hello")
        
        // When
        let p: Parser<String> = .discardLeft(p1, p2)
        let text = try p.run("Input")
        
        // Then
        XCTAssertEqual(text, "hello")
    }
    
    func test_discardRight() throws {
        // Given
        let p1: Parser<Int> = .just(1)
        let p2: Parser<String> = .just("hello")
        
        // When
        let p: Parser<Int> = .discardRight(p1, p2)
        let number = try p.run("Input")
        
        // Then
        XCTAssertEqual(number, 1)
    }
    
    func test_tuple2() throws {
        // Given
        let p1: Parser<Int> = .just(1)
        let p2: Parser<String> = .just("2")
        
        // When
        let p: Parser<(Int, String)> = .tuple(p1, p2)
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
        let p = Parser<()>.tuple(p1, p2, p3)
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
        let p = Parser<()>.tuple(p1, p2, p3, p4)
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
        let p = Parser<()>.tuple(p1, p2, p3, p4, p5)
        let value = try p.run("Input")
        
        // Then
        XCTAssertEqual(value.0, 1)
        XCTAssertEqual(value.1, "2")
        XCTAssertEqual(value.2, 3.0)
        XCTAssertEqual(value.3, true)
        XCTAssertEqual(value.4, "c")
    }
    
    func test_tuple3_failure() {
        // Given
        let p1: Parser<Int> = .just(1)
        let p2: Parser<String> = .fail(message: "invalid input")
        let p3: Parser<Double> = .just(3.0)
        
        // When
        let p = Parser<()>.tuple(p1, p2, p3)
        let reply = p.parse(ParserState(stream: "Input"))
        
        // Then
        XCTAssertFalse(reply.result.isSuccess)
        XCTAssertFalse(reply.errors.isEmpty)
    }
    
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
            return .failure(state.withStream(state.stream.dropFirst()),
                            [.generic(message: "Invalid input")])
        }
        let p2: Parser<Int> = .just(2)
        
        // When
        let p: Parser<Int> = .alternative(p1, p2)
        let reply = p.parse(ParserState(stream: "Input"))
        
        // Then
        XCTAssertFalse(reply.result.isSuccess)
        XCTAssertEqual(reply.errors, [.generic(message: "Invalid input")])
    }
    
    func test_any_returnFirstSuccess() {
        // Given
        let p1: Parser<Int> = .fail(message: "Fail 1")
        let p2: Parser<Int> = .just(2)
        let p3: Parser<Int> = .just(3)
        
        // When
        let p: Parser<Int> = .any(of: [p1, p2, p3])
        let reply = p.parse(ParserState(stream: "Input"))
        
        // Then
        XCTAssertEqual(reply.result.value, 2)
    }
    
    func test_any_failWithChange_returnFailure() {
        // Given
        let p1: Parser<Int> = .fail(message: "Fail 1")
        let p2: Parser<Int> = Parser { state in
            return .failure(state.withStream(state.stream.dropFirst()),
                            [.generic(message: "Fail 3")])
        }
        let p3: Parser<Int> = .just(3)
        
        // When
        let p: Parser<Int> = .any(of: [p1, p2, p3])
        let reply = p.parse(ParserState(stream: "Input"))
        
        // Then
        XCTAssertFalse(reply.result.isSuccess)
    }
    
    func test_any_failWithoutChange_mergeErrors() {
        // Given
        let p1: Parser<Int> = .fail(message: "Fail 1")
        let p2: Parser<Int> = .fail(message: "Fail 2")
        let p3: Parser<Int> = .fail(message: "Fail 3")
        
        // When
        let p: Parser<Int> = .any(of: [p1, p2, p3])
        let reply = p.parse(ParserState(stream: "Input"))
        
        // Then
        XCTAssertEqual(reply.errors, [.generic(message: "Fail 1"),
                                      .generic(message: "Fail 2"),
                                      .generic(message: "Fail 3")])
    }
}
