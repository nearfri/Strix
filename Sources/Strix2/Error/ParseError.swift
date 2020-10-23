import Foundation

public enum ParseError: Error, Equatable {
    case expected(label: String)
    case unexpected(label: String)
    case expectedString(string: String, caseSensitive: Bool)
    case unexpectedString(string: String, caseSensitive: Bool)
    case generic(message: String)
    case nested(position: String.Index, errors: [ParseError])
    case compound(label: String, position: String.Index, errors: [ParseError])
}
