import Foundation

public struct ParserReply<T> {
    public enum Result {
        case success(T)
        case failure
    }
    
    public var result: Result
    public var state: ParserState
    public var errors: [ParseError]
    
    public init(result: Result, state: ParserState, errors: [ParseError] = []) {
        self.result = result
        self.state = state
        self.errors = errors
    }
    
    public static func success(_ value: T,
                               _ state: ParserState,
                               _ errors: [ParseError] = []) -> ParserReply {
        return .init(result: .success(value), state: state, errors: errors)
    }
    
    public static func failure(_ state: ParserState,
                               _ errors: [ParseError] = []) -> ParserReply {
        return .init(result: .failure, state: state, errors: errors)
    }
    
    public func map<U>(_ transform: (T) throws -> U) rethrows -> ParserReply<U> {
        switch result {
        case .success(let value):
            return .success(try transform(value), state, errors)
        case .failure:
            return .failure(state, errors)
        }
    }
    
    public func appendingErrors(_ errors: [ParseError]) -> ParserReply {
        return .init(result: result, state: state, errors: self.errors + errors)
    }
    
    public func appendingErrors(
        _ errors: [ParseError],
        if predicate: (ParserReply) throws -> Bool
    ) rethrows -> ParserReply {
        return try predicate(self) ? appendingErrors(errors) : self
    }
    
    public func prependingErrors(_ errors: [ParseError]) -> ParserReply {
        return .init(result: result, state: state, errors: errors + self.errors)
    }
    
    public func prependingErrors(
        _ errors: [ParseError],
        if predicate: (ParserReply) throws -> Bool
    ) rethrows -> ParserReply {
        return try predicate(self) ? prependingErrors(errors) : self
    }
}
