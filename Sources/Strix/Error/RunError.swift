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
        
        return buffer.text
    }
    
    public var description: String {
        let textPosition = TextPosition(string: input, index: position)
        
        return "line: \(textPosition.line), column: \(textPosition.column), "
            + "underlyingErrors: \(underlyingErrors)"
    }
}
