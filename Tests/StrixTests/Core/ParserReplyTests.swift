import Testing
@testable import Strix

private enum Fixture {
    static var state: ParserState { .init(stream: "stream") }
    static var state1: ParserState { .init(stream: "stream1") }
    static var state2: ParserState { .init(stream: "stream2") }
    
    static let errors1: [ParseError] = [.expected(label: "Hello")]
    static let errors2: [ParseError] = [.expected(label: "World")]
}

@Suite struct ParserReplyTests {
    @Test func compareStateAndAppendingErrors_equalState_appending() {
        // Given
        let reply1: ParserReply<Int> = .failure(Fixture.errors1, Fixture.state)
        let reply2: ParserReply<Int> = .failure(Fixture.errors2, Fixture.state)
        
        // When
        let newReply = reply1.compareStateAndAppendingErrors(of: reply2)
        
        // Then
        #expect(newReply.state == Fixture.state)
        #expect(newReply.errors == Fixture.errors1 + Fixture.errors2)
    }
    
    @Test func compareStateAndAppendingErrors_notEqualState_noAppending() {
        // Given
        let reply1: ParserReply<Int> = .failure(Fixture.errors1, Fixture.state1)
        let reply2: ParserReply<Int> = .failure(Fixture.errors2, Fixture.state2)
        
        // When
        let newReply = reply1.compareStateAndAppendingErrors(of: reply2)
        
        // Then
        #expect(newReply.state == Fixture.state1)
        #expect(newReply.errors == Fixture.errors1)
    }
    
    @Test func compareStateAndPrependingErrors_equalState_prepending() {
        // Given
        let reply1: ParserReply<Int> = .failure(Fixture.errors1, Fixture.state)
        let reply2: ParserReply<Int> = .failure(Fixture.errors2, Fixture.state)
        
        // When
        let newReply = reply1.compareStateAndPrependingErrors(of: reply2)
        
        // Then
        #expect(newReply.state == Fixture.state)
        #expect(newReply.errors == Fixture.errors2 + Fixture.errors1)
    }
    
    @Test func compareStateAndPrependingErrors_notEqualState_noPrepending() {
        // Given
        let reply1: ParserReply<Int> = .failure(Fixture.errors1, Fixture.state1)
        let reply2: ParserReply<Int> = .failure(Fixture.errors2, Fixture.state2)
        
        // When
        let newReply = reply1.compareStateAndPrependingErrors(of: reply2)
        
        // Then
        #expect(newReply.state == Fixture.state1)
        #expect(newReply.errors == Fixture.errors1)
    }
}
