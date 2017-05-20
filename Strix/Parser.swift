
public struct Parser<T> {
    public let parse: (CharacterStream) -> Reply<T>
    
    public init(_ parse: @escaping (CharacterStream) -> Reply<T>) {
        self.parse = parse
    }
    
    public func run(_ string: String) -> ParseResult<T> {
        let stream = CharacterStream(string: string)
        switch parse(stream) {
        case let .success(v, _):
            return .success(v)
        case let .failure(errors), let .fatalFailure(errors):
            let error = ParseResult<T>.Error(position: stream.position, underlyingErrors: errors)
            return .failure(error)
        }
    }
}



