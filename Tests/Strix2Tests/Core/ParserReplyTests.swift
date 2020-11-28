import XCTest
@testable import Strix2

private enum Seed {
    static let state: ParserState = .init(stream: "stream")
    static let state1: ParserState = .init(stream: "stream1")
    static let state2: ParserState = .init(stream: "stream2")
    
    static let errors1: [ParseError] = [.expected(label: "Hello")]
    static let errors2: [ParseError] = [.expected(label: "World")]
}

final class ParserReplyTests: XCTestCase {
    func test_compareStateAndAppendingErrors_equalState_appending() {
        // Given
        let reply1: ParserReply<Int> = .failure(Seed.state, Seed.errors1)
        let reply2: ParserReply<Int> = .failure(Seed.state, Seed.errors2)
        
        // When
        let newReply = reply1.compareStateAndAppendingErrors(of: reply2)
        
        // Then
        XCTAssertEqual(newReply.state, Seed.state)
        XCTAssertEqual(newReply.errors, Seed.errors1 + Seed.errors2)
    }
    
    func test_compareStateAndAppendingErrors_notEqualState_noAppending() {
        // Given
        let reply1: ParserReply<Int> = .failure(Seed.state1, Seed.errors1)
        let reply2: ParserReply<Int> = .failure(Seed.state2, Seed.errors2)
        
        // When
        let newReply = reply1.compareStateAndAppendingErrors(of: reply2)
        
        // Then
        XCTAssertEqual(newReply.state, Seed.state1)
        XCTAssertEqual(newReply.errors, Seed.errors1)
    }
    
    func test_compareStateAndPrependingErrors_equalState_prepending() {
        // Given
        let reply1: ParserReply<Int> = .failure(Seed.state, Seed.errors1)
        let reply2: ParserReply<Int> = .failure(Seed.state, Seed.errors2)
        
        // When
        let newReply = reply1.compareStateAndPrependingErrors(of: reply2)
        
        // Then
        XCTAssertEqual(newReply.state, Seed.state)
        XCTAssertEqual(newReply.errors, Seed.errors2 + Seed.errors1)
    }
    
    func test_compareStateAndPrependingErrors_notEqualState_noPrepending() {
        // Given
        let reply1: ParserReply<Int> = .failure(Seed.state1, Seed.errors1)
        let reply2: ParserReply<Int> = .failure(Seed.state2, Seed.errors2)
        
        // When
        let newReply = reply1.compareStateAndPrependingErrors(of: reply2)
        
        // Then
        XCTAssertEqual(newReply.state, Seed.state1)
        XCTAssertEqual(newReply.errors, Seed.errors1)
    }
}
