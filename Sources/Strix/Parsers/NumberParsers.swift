import Foundation

extension Parser {
    /// `numberLiteral(options: options)` parses a number literal and
    /// returns the result in form of a `NumberLiteral` value.
    /// The given `NumberParseOptions` argument determines the kind of number literals accepted.
    /// The parser fails without consuming input if not at least one digit can be parsed.
    /// It fails after consuming input, if no decimal digit comes after an exponent marker.
    public static func numberLiteral(
        options: NumberParseOptions
    ) -> Parser<T> where T == NumberLiteral {
        return NumberLiteralParserGenerator(options: options).make()
    }
    
    /// `number(options: options, transform: transform)` parses a number literal and
    /// returns the result of the function application `transform(literal)`, where `literal` is the `NumberLiteral` value.
    /// The given `NumberParseOptions` argument determines the kind of number literals accepted.
    public static func number(
        options: NumberParseOptions,
        transform: @escaping (NumberLiteral) throws -> T
    ) -> Parser<T> {
        let numberLiteral = Parser<NumberLiteral>.numberLiteral(options: options)
        return Parser { state in
            let literalReply = numberLiteral.parse(state)
            switch literalReply.result {
            case .success(let literal, _):
                do {
                    return .success(try transform(literal), literalReply.state)
                } catch let e {
                    let error = (e as? ParseError) ?? .generic(message: e.localizedDescription)
                    return .failure([error], state)
                }
            case .failure:
                return .failure(literalReply.errors, literalReply.state)
            }
        }
    }
    
    /// Parses a signed integer number in the decimal, hexadecimal (0[xX]), octal (0[oO]) and binary (0[bB]) formats.
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
    
    /// Parses an unsigned integer number in the decimal, hexadecimal (0[xX]), octal (0[oO]) and binary (0[bB]) formats.
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
    
    /// Parses a floating point number in the decimal, hexadecimal (0[xX]), octal (0[oO]) and binary (0[bB]) formats.
    /// The special values `NaN` and `Inf(inity)?` (case‐insensitive) are also recognized.
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
    
    /// Parses a `NSNumber` in the decimal, hexadecimal (0[xX]), octal (0[oO]) and binary (0[bB]) formats.
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
        return .generic(message: "\(literal.string) is outside the allowable range")
    }
    
    /// Parses an `Int` in the decimal, hexadecimal (0[xX]), octal (0[oO]) and binary (0[bB]) formats.
    public static func int(
        allowExponent: Bool = false,
        allowUnderscore: Bool = false
    ) -> Parser<T> where T == Int {
        return signedInteger(allowExponent: allowExponent, allowUnderscore: allowUnderscore)
    }
    
    /// Parses a `UInt` in the decimal, hexadecimal (0[xX]), octal (0[oO]) and binary (0[bB]) formats.
    public static func uint(
        allowExponent: Bool = false,
        allowUnderscore: Bool = false
    ) -> Parser<T> where T == UInt {
        return unsignedInteger(allowExponent: allowExponent, allowUnderscore: allowUnderscore)
    }
    
    /// Parses a `Double` in the decimal, hexadecimal (0[xX]), octal (0[oO]) and binary (0[bB]) formats.
    /// The special values `NaN` and `Inf(inity)?` (case‐insensitive) are also recognized.
    public static func double(allowUnderscore: Bool = false) -> Parser<T> where T == Double {
        return floatingPoint(allowUnderscore: allowUnderscore)
    }
    
    /// Parses a `Float` in the decimal, hexadecimal (0[xX]), octal (0[oO]) and binary (0[bB]) formats.
    /// The special values `NaN` and `Inf(inity)?` (case‐insensitive) are also recognized.
    public static func float(allowUnderscore: Bool = false) -> Parser<T> where T == Float {
        return floatingPoint(allowUnderscore: allowUnderscore)
    }
}

private struct NumberLiteralParserGenerator {
    private let options: NumberParseOptions
    
    init(options: NumberParseOptions) {
        self.options = options
    }
    
    func make() -> Parser<NumberLiteral> {
        return Parser { [sign, classification, notation,
                         integerPart, fractionalPart, exponentPart] state in
            var newState = state
            var numberLiteral = NumberLiteral()
            let literalString: () -> String = {
                return String(state.stream[state.stream.startIndex..<newState.stream.startIndex])
            }
            
            sign.parse(&newState).value.map({ numberLiteral.sign = $0 })
            
            classification.parse(&newState).value.map({ numberLiteral.classification = $0 })
            
            if numberLiteral.classification == .nan || numberLiteral.classification == .infinity {
                numberLiteral.string = literalString()
                return .success(numberLiteral, newState)
            }
            
            notation.parse(&newState).value.map({ numberLiteral.notation = $0 })
            
            integerPart(numberLiteral.notation).parse(&newState)
                .value.map({ numberLiteral.integerPart = $0 })
            
            fractionalPart(numberLiteral.notation).parse(&newState)
                .value.map({ numberLiteral.fractionalPart = $0 })
            
            if numberLiteral.integerPart.isEmpty && numberLiteral.fractionalPart.isEmpty {
                // 아무런 숫자도 없는 경우 처음으로 돌아간다
                return .failure([.expected(label: "number")], state)
            }
            
            switch exponentPart(numberLiteral.notation).parse(&newState) {
            case .success(let exp, _):
                numberLiteral.exponentPart = exp
            case .failure(let errors):
                return .failure(errors, newState)
            }
            
            numberLiteral.string = literalString()
            return .success(numberLiteral, newState)
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
        
        return .one(of: parsers)
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
        
        return .one(of: parsers)
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
        
        return .one(of: parsers)
    }
    
    private func integerPart(notation: NumberLiteral.Notation) -> Parser<String> {
        return digits(notation: notation) <|> .just("")
    }
    
    private func fractionalPart(notation: NumberLiteral.Notation) -> Parser<String> {
        if !options.contains(.allowFraction) {
            return .just("")
        }
        return (character(".") *> digits(notation: notation)) <|> .just("")
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
    
    private func exponentPart(notation: NumberLiteral.Notation) -> Parser<String> {
        guard options.contains(.allowExponent),
              let separator = exponentSeparator(notation: notation)
        else { return .just("") }
        
        let sign = (character("+") <|> character("-")).map({ String($0) }) <|> .just("")
        let decimalDigits = digits(notation: .decimal)
        return (separator *> Parser.tuple(sign, decimalDigits).map({ $0 + $1 })) <|> .just("")
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
