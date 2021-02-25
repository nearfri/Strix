import Foundation

public struct RunError: LocalizedError, CustomStringConvertible {
    public var input: String
    public var position: String.Index
    public var underlyingErrors: [ParseError]
    
    public init(input: String, position: String.Index, underlyingErrors: [ParseError]) {
        self.input = input
        self.position = position
        self.underlyingErrors = underlyingErrors
    }
    
    public var errorDescription: String? {
        var buffer = ErrorOutputBuffer()
        
        ErrorMessageWriter(input: input, position: position, errors: underlyingErrors)
            .write(to: &buffer)
        
        return buffer.text.trimmingCharacters(in: .newlines)
    }
    
    public var failureReason: String? {
        var buffer = ErrorOutputBuffer()
        
        ErrorMessageWriter(errors: underlyingErrors).write(to: &buffer)
        
        return buffer.text.trimmingCharacters(in: .newlines)
    }
    
    public var description: String {
        return "line: \(textPosition.line), column: \(textPosition.column), "
            + "underlyingErrors: \(underlyingErrors)"
    }
    
    public var textPosition: TextPosition {
        return TextPosition(string: input, index: position)
    }
}
