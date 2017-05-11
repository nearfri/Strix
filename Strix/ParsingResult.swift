
public enum ParsingResult<T> {
    case success(T)
    case failure(ParsingResult.Error)
}

extension ParsingResult: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .success(v):
            return "Success: \(v)"
        case let .failure(e):
            return "Failure: \(e)"
        }
    }
}

extension ParsingResult {
    public struct Error: Swift.Error {
        public let position: CharacterPosition
        public let underlyingErrors: [Swift.Error]
    }
}

extension ParsingResult.Error: CustomStringConvertible {
    public var description: String {
        return "Error in \(position.lineNumber):\(position.columnNumber)"
    }
    
    private func columnPositionString() -> String {
        return ""
    }
}



