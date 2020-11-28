import Foundation

public struct ParserReply<T> {
    public var result: ParserResult<T>
    public var state: ParserState
    
    public var errors: [ParseError] {
        return result.errors
    }
    
    public init(result: ParserResult<T>, state: ParserState) {
        self.result = result
        self.state = state
    }
    
    public static func success(_ value: T,
                               _ state: ParserState,
                               _ errors: [ParseError] = []) -> ParserReply {
        return .init(result: .success(value, errors), state: state)
    }
    
    public static func failure(_ state: ParserState, _ errors: [ParseError]) -> ParserReply {
        return .init(result: .failure(errors), state: state)
    }
    
    public func map<U>(_ transform: (T) throws -> U) -> ParserReply<U> {
        return .init(result: result.map(transform), state: state)
    }
    
    public func withErrors(_ errors: [ParseError]) -> ParserReply {
        return .init(result: result.withErrors(errors), state: state)
    }
    
    public func appendingErrors(_ errors: [ParseError]) -> ParserReply {
        return .init(result: result.appendingErrors(errors), state: state)
    }
    
    public func prependingErrors(_ errors: [ParseError]) -> ParserReply {
        return .init(result: result.prependingErrors(errors), state: state)
    }
    
    public func compareStateAndAppendingErrors<U>(of reply: ParserReply<U>) -> ParserReply {
        return state == reply.state ? appendingErrors(reply.errors) : self
    }
    
    public func compareStateAndPrependingErrors<U>(of reply: ParserReply<U>) -> ParserReply {
        return state == reply.state ? prependingErrors(reply.errors) : self
    }
}
