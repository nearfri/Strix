import Foundation

public struct Parser<T> {
    public let parse: (ParserState) -> ParserReply<T>
    
    public init(_ parse: @escaping (ParserState) -> ParserReply<T>) {
        self.parse = parse
    }
    
    public func flatMap<U>(_ transform: @escaping (T) -> Parser<U>) -> Parser<U> {
        return Parser<U> { state -> ParserReply<U> in
            let reply = parse(state)
            switch reply.result {
            case .success(let v):
                return transform(v)
                    .parse(reply.state)
                    .prependingErrors(reply.errors, if: { $0.state == reply.state })
            case .failure:
                return .failure(reply.state, reply.errors)
            }
        }
    }
    
    public func map<U>(_ transform: @escaping (T) -> U) -> Parser<U> {
        return Parser<U> { state -> ParserReply<U> in
            return parse(state).map(transform)
        }
    }
}
