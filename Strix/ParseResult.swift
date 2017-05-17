
public enum ParseResult<T> {
    case success(T)
    case failure(ParseResult.Error)
}

extension ParseResult: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .success(v):
            return "Success: \(v)"
        case let .failure(e):
            return "Failure: \(e)"
        }
    }
}

extension ParseResult {
    public struct Error: Swift.Error {
        public let position: TextPosition
        public let underlyingErrors: [Swift.Error]
    }
}

extension ParseResult.Error: CustomStringConvertible {
    public var description: String {
        var outputBuffer = ErrorOutputBuffer()
        ErrorMessageWriter.write(position: position, errors: underlyingErrors, to: &outputBuffer)
        return outputBuffer.text
    }
}



