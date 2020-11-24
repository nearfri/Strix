import Foundation

extension Parser {
    public static func numberLiteral(
        options: NumberParseOptions
    ) -> Parser<T> where T == NumberLiteral {
        return NumberLiteralParserGenerator(options: options).make()
    }
    
    public static func number(
        options: NumberParseOptions,
        transform: @escaping (NumberLiteral) throws -> T
    ) -> Parser<T> {
        return Parser { state in
            let literalReply = Parser<NumberLiteral>.numberLiteral(options: options).parse(state)
            switch literalReply.result {
            case .success(let literal):
                do {
                    return .success(try transform(literal), literalReply.state)
                } catch let e {
                    let error = (e as? ParseError) ?? .generic(message: e.localizedDescription)
                    return .failure(state, [error])
                }
            case .failure:
                return .failure(literalReply.state, literalReply.errors)
            }
        }
    }
    
    public static func signedInteger(
        allowExponent: Bool = false,
        allowUnderscore: Bool = false
    ) -> Parser<T> where T: (FixedWidthInteger & SignedInteger) {
        let options = NumberParseOptions.defaultSignedInteger
            .union(allowExponent ? .allowExponent : [])
            .union(allowUnderscore ? .allowUnderscore : [])
        
        return number(options: options) { literal in
            guard let num = literal.toValue(type: T.self) else {
                throw overflowError(literal: literal)
            }
            return num
        }
    }
    
    public static func unsignedInteger(
        allowExponent: Bool = false,
        allowUnderscore: Bool = false
    ) -> Parser<T> where T: (FixedWidthInteger & UnsignedInteger) {
        let options = NumberParseOptions.defaultUnsignedInteger
            .union(allowExponent ? .allowExponent : [])
            .union(allowUnderscore ? .allowUnderscore : [])
        
        return number(options: options) { literal in
            guard let num = literal.toValue(type: T.self) else {
                throw overflowError(literal: literal)
            }
            return num
        }
    }
    
    public static func floatingPoint(
        allowUnderscore: Bool = false
    ) -> Parser<T> where T: BinaryFloatingPoint {
        let options = NumberParseOptions.defaultFloatingPoint
            .union(allowUnderscore ? .allowUnderscore : [])
        
        return number(options: options) { literal in
            guard let num = literal.toValue(type: T.self) else {
                throw overflowError(literal: literal)
            }
            return num
        }
    }
    
    public static func number(allowUnderscore: Bool = false) -> Parser<T> where T == NSNumber {
        let options = NumberParseOptions.defaultFloatingPoint
            .union(allowUnderscore ? .allowUnderscore : [])
        
        return number(options: options) { literal in
            guard let num = literal.toNumber() else {
                throw overflowError(literal: literal)
            }
            return num
        }
    }
    
    private static func overflowError(literal: NumberLiteral) -> ParseError {
        guard let string = literal.string else { preconditionFailure() }
        return .generic(message: "\(string) is outside the allowable range")
    }
    
    public static func int(
        allowExponent: Bool = false,
        allowUnderscore: Bool = false
    ) -> Parser<T> where T == Int {
        return signedInteger(allowExponent: allowExponent, allowUnderscore: allowUnderscore)
    }
    
    public static func uint(
        allowExponent: Bool = false,
        allowUnderscore: Bool = false
    ) -> Parser<T> where T == UInt {
        return unsignedInteger(allowExponent: allowExponent, allowUnderscore: allowUnderscore)
    }
    
    public static func double(allowUnderscore: Bool = false) -> Parser<T> where T == Double {
        return floatingPoint(allowUnderscore: allowUnderscore)
    }
    
    public static func float(allowUnderscore: Bool = false) -> Parser<T> where T == Float {
        return floatingPoint(allowUnderscore: allowUnderscore)
    }
}

private struct NumberLiteralParserGenerator {
    private enum Result<T> {
        case success(T)
        case failure([ParseError])
        
        var value: T? {
            switch self {
            case .success(let v):   return v
            case .failure:          return nil
            }
        }
    }
    
    private let options: NumberParseOptions
    
    init(options: NumberParseOptions) {
        self.options = options
    }
    
    func make() -> Parser<NumberLiteral> {
        return Parser { state in
            var newState = state
            var numberLiteral = NumberLiteral()
            let literalString: () -> String = {
                return String(state.stream[state.stream.startIndex..<newState.stream.startIndex])
            }
            
            parse(&newState, using: sign).value.map({ numberLiteral.sign = $0 })
            
            parse(&newState, using: classification).value.map({ numberLiteral.classification = $0 })
            
            if numberLiteral.classification == .nan || numberLiteral.classification == .infinity {
                numberLiteral.string = literalString()
                return .success(numberLiteral, newState)
            }
            
            parse(&newState, using: notation).value.map({ numberLiteral.notation = $0 })
            
            parse(&newState, using: integerPart(notation: numberLiteral.notation))
                .value.map({ numberLiteral.integerPart = $0 })
            
            parse(&newState, using: fractionalPart(notation: numberLiteral.notation))
                .value.map({ numberLiteral.fractionalPart = $0 })
            
            if numberLiteral.integerPart == nil && numberLiteral.fractionalPart == nil {
                // 아무런 숫자도 없는 경우 처음으로 돌아간다
                return .failure(state, [.expected(label: "number")])
            }
            
            switch parse(&newState, using: exponentPart(notation: numberLiteral.notation)) {
            case .success(let exp):
                numberLiteral.exponentPart = exp
            case .failure(let errors):
                return .failure(newState, errors)
            }
            
            numberLiteral.string = literalString()
            return .success(numberLiteral, newState)
        }
    }
    
    private func parse<T>(
        _ state: inout ParserState,
        using parser: Parser<T>
    ) -> Result<T> {
        let reply = parser.parse(state)
        
        state = reply.state
        
        switch reply.result {
        case .success(let value):
            return .success(value)
        case .failure:
            return .failure(reply.errors)
        }
    }
    
    private func character(_ c: Character) -> Parser<Character> {
        return .character(c)
    }
    
    private func string(_ str: String) -> Parser<String> {
        return .string(str, caseSensitive: false)
    }
    
    private var sign: Parser<NumberLiteral.Sign> {
        var parsers: [Parser<NumberLiteral.Sign>] = []
        
        if options.contains(.allowPlusSign) {
            parsers.append(character("+").map({ _ in .plus }))
        }
        if options.contains(.allowMinusSign) {
            parsers.append(character("-").map({ _ in .minus }))
        }
        parsers.append(.just(.none))
        
        return .any(of: parsers)
    }
    
    private var classification: Parser<NumberLiteral.Classification> {
        var parsers: [Parser<NumberLiteral.Classification>] = []
        
        if options.contains(.allowNaN) {
            parsers.append(string("nan").map({ _ in .nan }))
        }
        if options.contains(.allowInfinity) {
            parsers.append((string("infinity") <|> string("inf")).map({ _ in .infinity }))
        }
        parsers.append(.just(.finite))
        
        return .any(of: parsers)
    }
    
    private var notation: Parser<NumberLiteral.Notation> {
        var parsers: [Parser<NumberLiteral.Notation>] = []
        
        if options.contains(.allowHexadecimal) {
            parsers.append(string("0x").map({ _ in .hexadecimal }))
        }
        if options.contains(.allowOctal) {
            parsers.append(string("0o").map({ _ in .octal }))
        }
        if options.contains(.allowBinary) {
            parsers.append(string("0b").map({ _ in .binary }))
        }
        parsers.append(.just(.decimal))
        
        return .any(of: parsers)
    }
    
    private func integerPart(notation: NumberLiteral.Notation) -> Parser<String?> {
        return .optional(digits(notation: notation))
    }
    
    private func fractionalPart(notation: NumberLiteral.Notation) -> Parser<String?> {
        if !options.contains(.allowFraction) {
            return .just(nil)
        }
        return .optional(character(".") *> digits(notation: notation))
    }
    
    private func digits(notation: NumberLiteral.Notation) -> Parser<String> {
        let digit = self.digit(notation: notation)
        
        if !options.contains(.allowUnderscore) {
            return Parser.many(digit, minCount: 1).map({ String($0) })
        }
        
        return Parser.many(first: digit, repeating: digit <|> character("_"), minCount: 1)
            .map({ characters in String(characters.filter({ $0 != "_" })) })
    }
    
    private func digit(notation: NumberLiteral.Notation) -> Parser<Character> {
        switch notation {
        case .decimal:      return .decimalDigit
        case .hexadecimal:  return .hexadecimalDigit
        case .octal:        return .octalDigit
        case .binary:       return .binaryDigit
        }
    }
    
    private func exponentPart(notation: NumberLiteral.Notation) -> Parser<String?> {
        guard options.contains(.allowExponent),
              let separator = exponentSeparator(notation: notation)
        else { return .just(nil) }
        
        let sign = (character("+") <|> character("-")).map({ String($0) }) <|> .just("")
        let decimalDigits = digits(notation: .decimal)
        return .optional(separator *> Parser.tuple(sign, decimalDigits).map({ $0 + $1 }))
    }
    
    private func exponentSeparator(notation: NumberLiteral.Notation) -> Parser<Character>? {
        switch notation {
        case .decimal:      return character("e") <|> character("E")
        case .hexadecimal:  return character("p") <|> character("P")
        case .octal:        return nil
        case .binary:       return nil
        }
    }
}
