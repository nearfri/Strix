import Foundation

public struct Parser<T> {
    public let parse: (ParserState) -> ParserReply<T>
    
    public init(_ parse: @escaping (ParserState) -> ParserReply<T>) {
        self.parse = parse
    }
    
    public func map<U>(_ transform: @escaping (T) -> U) -> Parser<U> {
        return Parser<U> { state -> ParserReply<U> in
            return parse(state).map(transform)
        }
    }
    
    public func flatMap<U>(_ transform: @escaping (T) -> Parser<U>) -> Parser<U> {
        return Parser<U> { state -> ParserReply<U> in
            let reply = parse(state)
            switch reply.result {
            case .success(let v):
                return transform(v)
                    .parse(reply.state)
                    .compareStateAndPrependingErrors(of: reply)
            case .failure:
                return .failure(reply.state, reply.errors)
            }
        }
    }
    
    public func run(_ input: String) throws -> T {
        let initialState = ParserState(stream: input[...])
        
        let reply = parse(initialState)
        
        switch reply.result {
        case .success(let value):
            return value
        case .failure:
            throw RunError(input: input,
                           position: reply.state.stream.startIndex,
                           underlyingErrors: reply.errors)
        }
    }
}