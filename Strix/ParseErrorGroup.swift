
internal struct ParseErrorGroup {
    private(set) var expectedErrors: [ParseError.Expected] = []
    private(set) var expectedStringErrors: [ParseError.ExpectedString] = []
    private(set) var unexpectedErrors: [ParseError.Unexpected] = []
    private(set) var unexpectedStringErrors: [ParseError.UnexpectedString] = []
    private(set) var genericErrors: [ParseError.Generic] = []
    private(set) var nestedErrors: [ParseError.Nested] = []
    private(set) var compoundErrors: [ParseError.Compound] = []
    private(set) var unknownErrors: [Error] = []
    
    init(_ errors: [Error]) {
        append(contentsOf: errors)
        sort()
    }
    
    private mutating func append(contentsOf errors: [Error]) {
        for error in errors {
            switch error {
            case let error as ParseError.Expected:
                expectedErrors.append(error)
            case let error as ParseError.ExpectedString:
                expectedStringErrors.append(error)
            case let error as ParseError.Unexpected:
                unexpectedErrors.append(error)
            case let error as ParseError.UnexpectedString:
                unexpectedStringErrors.append(error)
            case let error as ParseError.Generic:
                genericErrors.append(error)
            case let error as ParseError.Nested:
                nestedErrors.append(error)
            case let error as ParseError.Compound:
                compoundErrors.append(error)
            default:
                unknownErrors.append(error)
            }
        }
    }
    
    private mutating func sort() {
        expectedErrors.sort()
        expectedStringErrors.sort()
        unexpectedErrors.sort()
        unexpectedStringErrors.sort()
        genericErrors.sort()
        
        nestedErrors.sort { $0.position < $1.position }
        
        compoundErrors.sort { (lhs, rhs) -> Bool in
            if lhs.position != rhs.position {
                return lhs.position < rhs.position
            }
            return lhs.label < rhs.label
        }
    }
}



