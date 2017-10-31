
// MARK: - Parsing numbers

extension NumberComponents {
    public struct ParseOptions: OptionSet {
        public let rawValue: Int
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        public static let allowPlusSign = ParseOptions(rawValue: 1 << 0)
        public static let allowMinusSign = ParseOptions(rawValue: 1 << 1)
        public static let allowNaN = ParseOptions(rawValue: 1 << 2)
        public static let allowInfinity = ParseOptions(rawValue: 1 << 3)
        public static let allowHexadecimal = ParseOptions(rawValue: 1 << 4)
        public static let allowOctal = ParseOptions(rawValue: 1 << 5)
        public static let allowBinary = ParseOptions(rawValue: 1 << 6)
        public static let allowFraction = ParseOptions(rawValue: 1 << 7)
        public static let allowExponent = ParseOptions(rawValue: 1 << 8)
        public static let allowUnderscores = ParseOptions(rawValue: 1 << 9)
        
        public static let allowSign: ParseOptions = [.allowPlusSign, .allowMinusSign]
        public static let allowAllNotations: ParseOptions = [
            .allowHexadecimal, .allowOctal, .allowBinary
        ]
        
        public static let defaultInteger: ParseOptions = [
            .allowSign, .allowAllNotations
        ]
        public static let defaultFloatingPoint: ParseOptions = [
            .allowSign, .allowNaN, .allowInfinity,
            .allowAllNotations, .allowFraction, .allowExponent
        ]
    }
}

public func numberComponents(options: NumberComponents.ParseOptions) -> Parser<NumberComponents> {
    return Parser { stream in
        return NumberComponentsParser.parse(stream, options: options)
    }
}

public func floatingPoint(allowUnderscores: Bool = false) -> Parser<Double> {
    let options: NumberComponents.ParseOptions = {
        var opts = NumberComponents.ParseOptions.defaultFloatingPoint
        if allowUnderscores { opts.insert(.allowUnderscores) }
        return opts
    }()
    
    return Parser { stream in
        let state = stream.state
        return numberComponents(options: options).parse(stream).flatMap({ (components) in
            switch components.classification {
            case .nan:
                // components.signValue * Double.nan 으로 하면 항상 plus 값이 된다.
                let value = components.sign == .minus ? -Double.nan : Double.nan
                return .success(value, [])
            case .infinity:
                let value = components.sign == .minus ? -Double.infinity : Double.infinity
                return .success(value * Double.infinity, [])
            case .finite:
                if let significand = components.significandValue {
                    let signValue = Double(components.signValue)
                    let exponent = components.exponentValue ?? 1.0
                    return .success(signValue * significand * exponent, [])
                }
                stream.backtrack(to: state)
                return .fatalFailure([makeOverflowError(from: components)])
            }
        })
    }
}

public func integer(allowExponent: Bool = false, allowUnderscores: Bool = false) -> Parser<Int> {
    let options: NumberComponents.ParseOptions = {
        var opts = NumberComponents.ParseOptions.defaultInteger
        if allowExponent { opts.insert(.allowExponent) }
        if allowUnderscores { opts.insert(.allowUnderscores) }
        return opts
    }()
    
    return Parser { stream in
        let state = stream.state
        return numberComponents(options: options).parse(stream).flatMap({ (components) in
            let overflowError: () -> Error = { makeOverflowError(from: components) }
            do {
                guard let integer = components.integerValue else {
                    throw overflowError()
                }
                
                guard let exponent = components.exponentValue else {
                    return .success(components.signValue * integer, [])
                }
                
                guard let multipliedValue = Double(exactly: integer)
                    .map({ $0 * exponent })
                    .flatMap({ Int(exactly: $0) })
                    else { throw overflowError() }
                
                return .success(components.signValue * multipliedValue, [])
            } catch {
                stream.backtrack(to: state)
                return .fatalFailure([error])
            }
        })
    }
}

private func makeOverflowError(from components: NumberComponents) -> Error {
    guard let string = components.string else { preconditionFailure() }
    return ParseError.Generic(message: "\(string) is outside the allowable range")
}

private final class NumberComponentsParser {
    private let stream: CharacterStream
    private let options: NumberComponents.ParseOptions
    private var components: NumberComponents = NumberComponents()
    
    static func parse(_ stream: CharacterStream,
                      options: NumberComponents.ParseOptions) -> Reply<NumberComponents> {
        return NumberComponentsParser(stream: stream, options: options).parse()
    }
    
    private init(stream: CharacterStream, options: NumberComponents.ParseOptions) {
        self.stream = stream
        self.options = options
    }
    
    private func parse() -> Reply<NumberComponents> {
        do {
            try parseNumber()
        } catch {
            return .failure([error])
        }
        return .success(components, [])
    }
    
    private func parseNumber() throws {
        let state = stream.state
        
        parseSign()
        
        if parseNaN() || parseInfinity() {
            components.string = String(stream.readUpToNextIndex(from: state.index))
            return
        }
        
        do {
            try parseSignificand()
        } catch {
            // 아무런 숫자도 없는 경우 backtrack 한다.
            stream.backtrack(to: state)
            throw error
        }
        
        try parseExponent()
        
        components.string = String(stream.readUpToNextIndex(from: state.index))
    }
    
    private func parseSign() {
        switch stream.peek() {
        case "+"? where options.contains(.allowPlusSign):
            components.sign = .plus
            stream.skip()
        case "-"? where options.contains(.allowMinusSign):
            components.sign = .minus
            stream.skip()
        default:
            components.sign = .none
        }
    }
    
    private func parseNaN() -> Bool {
        guard options.contains(.allowNaN) && stream.skip("nan", case: .insensitive) else {
            return false
        }
        components.classification = .nan
        return true
    }
    
    private func parseInfinity() -> Bool {
        guard options.contains(.allowInfinity) && stream.skip("inf", case: .insensitive) else {
            return false
        }
        stream.skip("inity", case: .insensitive)
        components.classification = .infinity
        return true
    }
    
    private func parseSignificand() throws {
        parseNotation()
        
        let predicate = digitPredicate
        parseIntegerDigits(predicate: predicate)
        parseFractionDigits(predicate: predicate)
        
        if components.integer == nil && components.fraction == nil {
            throw ParseError.Expected("number")
        }
    }
    
    private func parseNotation() {
        func skipNotationString(_ string: String, when option: NumberComponents.ParseOptions,
                                andSet notation: NumberComponents.Notation) -> Bool {
            if self.options.contains(option) && stream.skip(string, case: .insensitive) {
                self.components.notation = notation
                return true
            }
            return false
        }
        
        if skipNotationString("0x", when: .allowHexadecimal, andSet: .hexadecimal) {
            return
        }
        if skipNotationString("0o", when: .allowOctal, andSet: .octal) {
            return
        }
        if skipNotationString("0b", when: .allowBinary, andSet: .binary) {
            return
        }
        components.notation = .decimal
    }
    
    private var digitPredicate: (Character) -> Bool {
        switch components.notation {
        case .decimal:
            return isDecimalDigit
        case .hexadecimal:
            return isHexadecimalDigit
        case .octal:
            return isOctalDigit
        case .binary:
            return isBinaryDigit
        }
    }
    
    private func parseIntegerDigits(predicate: @escaping (Character) -> Bool) {
        components.integer = readDigits(predicate: predicate)
    }
    
    private func parseFractionDigits(predicate: @escaping (Character) -> Bool) {
        guard options.contains(.allowFraction) && stream.skip(".") else { return }
        components.fraction = readDigits(predicate: predicate)
    }
    
    private func parseExponent() throws {
        guard options.contains(.allowExponent) else { return }
        
        switch components.notation {
        case .decimal:
            try parseExponent(separatedBy: "e")
        case .hexadecimal:
            try parseExponent(separatedBy: "p")
        case .octal, .binary:
            break
        }
    }
    
    private func parseExponent(separatedBy separator: Character) throws {
        guard stream.skip(String(separator), case: .insensitive) else { return }
        
        let sign = stream.read(maxCount: 1, while: { $0 == "+" || $0 == "-" })
        
        guard let exp = readDigits(predicate: isDecimalDigit) else {
            throw ParseError.Expected("decimal digit")
        }
        
        components.exponent = String(sign + exp)
    }
    
    func readDigits(predicate: @escaping (Character) -> Bool) -> String? {
        var hasUnderscores = false
        let isUnderscore: (Character) -> Bool = {
            if $0 == "_" {
                hasUnderscores = true
                return true
            }
            return false
        }
        
        let repeatedPredicate: (Character) -> Bool
        if !options.contains(.allowUnderscores) {
            repeatedPredicate = predicate
        } else {
            repeatedPredicate = { predicate($0) || isUnderscore($0) }
        }
        
        let parser = manyCharacters(minCount: 1, first: predicate, while: repeatedPredicate)
        guard let digits = parser.parse(stream).value else {
            return nil
        }
        return hasUnderscores ? digits.filter({ $0 != "_" }) : String(digits)
    }
}



