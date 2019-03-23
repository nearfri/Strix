
public struct Parser<T> {
    public let parse: (CharacterStream) -> Reply<T>
    
    public init(_ parse: @escaping (CharacterStream) -> Reply<T>) {
        self.parse = parse
    }
}

extension Parser {
    public func flatMap<U>(_ transform: @escaping (T) -> Parser<U>) -> Parser<U> {
        return Parser<U>({ (stream) -> Reply<U> in
            switch self.parse(stream) {
            case let .success(v, e):
                let stateTag = stream.stateTag
                let reply = transform(v).parse(stream)
                return stateTag == stream.stateTag && !e.isEmpty ? reply.prepending(e) : reply
            case let .failure(e):
                return .failure(e)
            }
        })
    }
    
    public func compactMap<U>(_ transform: @escaping (T) -> Reply<U>) -> Parser<U> {
        return flatMap({ (v) -> Parser<U> in
            return Parser<U>({ _ in transform(v) })
        })
    }
    
    public func map<U>(_ transform: @escaping (T) -> U) -> Parser<U> {
        return flatMap { (v) -> Parser<U> in
            return Parser<U>({ _ in .success(transform(v), []) })
        }
    }
}

extension Parser {
    public func run(_ string: String) -> ParseResult<T> {
        let stream = CharacterStream(string: string)
        switch parse(stream) {
        case let .success(v, _):
            return .success(v)
        case let .failure(errors):
            let error = ParseResult<T>.Error(position: stream.position, underlyingErrors: errors)
            return .failure(error)
        }
    }
}



