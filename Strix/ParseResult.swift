
public enum ParseResult<T> {
    case success(T)
    case failure(ParseResult.Error)
}

extension ParseResult {
    public var value: T? {
        switch self {
        case .success(let v):   return v
        case .failure:          return nil
        }
    }
    
    public var error: ParseResult.Error? {
        switch self {
        case .success:          return nil
        case .failure(let e):   return e
        }
    }
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



