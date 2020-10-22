import Foundation

struct ParseErrorSplitter {
    var expectedErrors: [String] = []
    var unexpectedErrors: [String] = []
    var expectedStringErrors: [(string: String, caseSensitivity: CaseSensitivity)] = []
    var unexpectedStringErrors: [(string: String, caseSensitivity: CaseSensitivity)] = []
    var genericErrors: [String] = []
    var nestedErrors: [(position: String.Index, errors: [ParseError])] = []
    var compoundErrors: [(label: String, position: String.Index, errors: [ParseError])] = []
    
    init(_ errors: [ParseError]) {
        for error in errors {
            append(error)
        }
    }
    
    private mutating func append(_ error: ParseError) {
        switch error {
        case let .expected(label):
            expectedErrors.append(label)
        case let .unexpected(label):
            unexpectedErrors.append(label)
        case let .expectedString(string, caseSensitivity):
            expectedStringErrors.append((string, caseSensitivity))
        case let .unexpectedString(string, caseSensitivity):
            unexpectedStringErrors.append((string, caseSensitivity))
        case let .generic(message):
            genericErrors.append(message)
        case let .nested(position, errors):
            nestedErrors.append((position, errors))
        case let .compound(label, position, errors):
            compoundErrors.append((label, position, errors))
        }
    }

    var hasErrors: Bool {
        let allErrorLists: [[Any]] = [
            expectedErrors, unexpectedErrors, expectedStringErrors, unexpectedStringErrors,
            genericErrors, nestedErrors, compoundErrors
        ]
        return allErrorLists.contains(where: { !$0.isEmpty })
    }
    
    var hasExpectedErrors: Bool {
        return !expectedErrors.isEmpty || !expectedStringErrors.isEmpty
    }
    
    var hasUnexpectedErrors: Bool {
        return !unexpectedErrors.isEmpty || !unexpectedStringErrors.isEmpty
    }
}
