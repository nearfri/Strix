
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
        return "Error in \(position.lineNumber):\(position.columnNumber)"
    }
    
    private func columnPositionString() -> String {
        return ""
    }
}



