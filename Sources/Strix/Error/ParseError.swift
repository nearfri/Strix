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

extension ParseError: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .expected(label):
            return "expected(label: \"\(label)\")"
        case let .unexpected(label):
            return "unexpected(label: \"\(label)\")"
        case let .expectedString(string, caseSensitive):
            return "expectedString(string: \"\(string)\", caseSensitive: \(caseSensitive))"
        case let .unexpectedString(string, caseSensitive):
            return "unexpectedString(string: \"\(string)\", caseSensitive: \(caseSensitive))"
        case let .generic(message):
            return "generic(message: \"\(message)\")"
        case let .nested(_, errors):
            return "nested(errors: \(errors))"
        case let .compound(label, _, errors):
            return "compound(label: \"\(label)\", errors: \(errors))"
        }
    }
}
