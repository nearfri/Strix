
import Foundation

// MARK: - Parsing single chars

public func character(_ c: Character) -> Parser<Character> {
    return Parser { stream in
        return stream.skip(c) ? .success(c, []) : .failure([ParseError.Expected(String(c))])
    }
}

public func anyCharacter() -> Parser<Character> {
    return Parser { stream in
        if let c = stream.read() {
            return .success(c, [])
        }
        return .failure([ParseError.Expected("any character")])
    }
}

public func satisfy(
    _ predicate: @escaping (Character) -> Bool,
    errorLabel: String? = nil) -> Parser<Character> {
    
    return satisfy(predicate, errors: errorLabel.map { [ParseError.Expected($0)] } ?? [])
}

private func satisfy(
    _ predicate: @escaping (Character) -> Bool,
    errors: @autoclosure @escaping () -> [Error]) -> Parser<Character> {
    
    return Parser { stream in
        if let c = stream.peek(), predicate(c) {
            stream.skip()
            return .success(c, [])
        }
        return .failure(errors())
    }
}

public func any<S: Sequence>(of characters: S) -> Parser<Character> where S.Element == Character {
    return satisfy(characters.contains,
                   errors: [ParseError.Expected("any character in \(characters)")])
}

public func none<S: Sequence>(of characters: S) -> Parser<Character> where S.Element == Character {
    return satisfy({ !characters.contains($0) },
                   errors: [ParseError.Expected("any character not in \(characters)")])
}

public func asciiLetter() -> Parser<Character> {
    return satisfy(isASCIILetter, errors: [ParseError.Expected("ASCII letter")])
}

public func asciiUppercaseLetter() -> Parser<Character> {
    return satisfy(isASCIIUppercaseLetter, errors: [ParseError.Expected("ASCII uppercase letter")])
}

public func asciiLowercaseLetter() -> Parser<Character> {
    return satisfy(isASCIILowercaseLetter, errors: [ParseError.Expected("ASCII lowercase letter")])
}

public func decimalDigit() -> Parser<Character> {
    return satisfy(isDecimalDigit, errors: [ParseError.Expected("decimal digit")])
}

public func hexadecimalDigit() -> Parser<Character> {
    return satisfy(isHexadecimalDigit, errors: [ParseError.Expected("hexadecimal digit")])
}

public func octalDigit() -> Parser<Character> {
    return satisfy(isOctalDigit, errors: [ParseError.Expected("octal digit")])
}

public func binaryDigit() -> Parser<Character> {
    return satisfy(isBinaryDigit, errors: [ParseError.Expected("binary digit")])
}

// MARK: - Parsing whitespace

public func tab() -> Parser<Character> {
    return satisfy({ $0 == "\t" }, errors: [ParseError.Expected("tab")])
}

public func newline() -> Parser<Character> {
    return satisfy(isNewline, errors: [ParseError.Expected("newline")])
}

public func skipWhitespaces(atLeastOne: Bool = false) -> Parser<Void> {
    if atLeastOne {
        return Parser { stream in
            if stream.skip(while: isWhitespace).count > 0 {
                return .success((), [])
            }
            return .failure([ParseError.Expected("whitespace")])
        }
    }
    return Parser { stream in
        stream.skip(while: isWhitespace)
        return .success((), [])
    }
}

// MARK: - Predicate functions corresponding to the above parsers

public func isASCIIUppercaseLetter(_ c: Character) -> Bool {
    return ("A"..."Z").contains(c)
}

public func isASCIILowercaseLetter(_ c: Character) -> Bool {
    return ("a"..."z").contains(c)
}

public func isASCIILetter(_ c: Character) -> Bool {
    return isASCIIUppercaseLetter(c) || isASCIILowercaseLetter(c)
}

public func isDecimalDigit(_ c: Character) -> Bool {
    return ("0"..."9").contains(c)
}

public func isHexadecimalDigit(_ c: Character) -> Bool {
    return ("0"..."9").contains(c) || ("A"..."F").contains(c) || ("a"..."f").contains(c)
}

public func isOctalDigit(_ c: Character) -> Bool {
    return ("0"..."7").contains(c)
}

public func isBinaryDigit(_ c: Character) -> Bool {
    return c == "0" || c == "1"
}

public func isBlank(_ c: Character) -> Bool {
    switch c {
    case " ", "\t":
        return true
    default:
        return false
    }
}

public func isNewline(_ c: Character) -> Bool {
    switch c {
    case "\n", "\r", "\r\n", "\u{000B}", "\u{000C}", "\u{0085}", "\u{2028}", "\u{2029}":
        return true
    default:
        return false
    }
}

public func isWhitespace(_ c: Character) -> Bool {
    return isBlank(c) || isNewline(c)
}

// MARK: - Parsing strings directly

public func string(
    _ str: String, case caseSensitivity: StringSensitivity = .sensitive) -> Parser<Substring> {
    
    return Parser { stream in
        if let substr = stream.read(str, case: caseSensitivity) {
            return .success(substr, [])
        }
        return .failure([ParseError.ExpectedString(str, case: caseSensitivity)])
    }
}

public func restOfLine(strippingNewline: Bool = true) -> Parser<Substring> {
    if strippingNewline {
        return Parser { stream in
            let substr = stream.read(while: { !isNewline($0) })
            stream.skip(isNewline(_:))
            return .success(substr, [])
        }
    }
    return Parser { stream in
        let start = stream.nextIndex
        stream.skip(while: { !isNewline($0) })
        stream.skip(isNewline(_:))
        let substr = stream.readUpToNextIndex(from: start)
        return .success(substr, [])
    }
}

public func string(
    until str: String, case caseSensitivity: StringSensitivity = .sensitive,
    maxCount: String.IndexDistance = .max, thenSkipString skipString: Bool) -> Parser<Substring> {
    
    precondition(!str.isEmpty, "str is empty")
    precondition(maxCount >= 0, "maxCount is negative")
    return Parser { stream in
        func skipAndReturnIndexOfStr() -> String.Index? {
            let skipOrMatches = skipString ? stream.skip(_:case:) : stream.matches(_:case:)
            for _ in 0...maxCount {
                if stream.isAtEnd { return nil }
                let end = stream.nextIndex
                if skipOrMatches(str, caseSensitivity) {
                    return end
                }
                stream.skip()
            }
            return nil
        }
        
        let state = stream.state
        if let end = skipAndReturnIndexOfStr() {
            return .success(stream.string[state.index..<end], [])
        }
        stream.backtrack(to: state)
        return .failure([ParseError.Generic(message: "could not find the string \"\(str)\"")])
    }
}

public func manyCharacters(
    minCount: String.IndexDistance = 0, maxCount: String.IndexDistance = .max,
    errorLabel: String? = nil,
    while predicate: @escaping (Character) -> Bool) -> Parser<Substring> {
    
    return manyCharacters(minCount: minCount, maxCount: maxCount, errorLabel: errorLabel,
                          first: predicate, while: predicate)
}

public func manyCharacters(
    minCount: String.IndexDistance = 0, maxCount: String.IndexDistance = .max,
    errorLabel: String? = nil,
    first firstPredicate: @escaping (Character) -> Bool,
    while predicate: @escaping (Character) -> Bool) -> Parser<Substring> {
    
    let errors = { errorLabel.map { [ParseError.Expected($0)] } ?? [] }
    return Parser { stream in
        let state = stream.state
        
        if !stream.skip(firstPredicate) {
            if minCount == 0 {
                return .success(stream.readUpToNextIndex(from: state.index), [])
            }
            return .failure(errors())
        }
        
        if stream.skip(minCount: minCount - 1, maxCount: maxCount - 1, while: predicate) != nil {
            return .success(stream.readUpToNextIndex(from: state.index), [])
        }
        stream.backtrack(to: state)
        return .failure(errors())
    }
}

public func regex(_ pattern: String, errorLabel: String? = nil) -> Parser<Substring> {
    let expression: NSRegularExpression
    do {
        try expression = NSRegularExpression(pattern: pattern, options: [])
    } catch {
        preconditionFailure("regex pattern \(pattern) is invalid")
    }
    let errors = { [ParseError.Expected(errorLabel ?? "string matching the regex \(pattern)")] }
    
    return Parser { stream in
        if let substr = stream.read(expression) {
            return .success(substr, [])
        }
        return .failure(errors())
    }
}

// MARK: - Parsing strings with the help of other parsers

public func manyCharacters(
    _ repeatedParser: Parser<Character>, atLeastOne: Bool = false) -> Parser<String> {
    
    return manyCharacters(first: repeatedParser, repeating: repeatedParser, atLeastOne: atLeastOne)
}

public func manyCharacters(
    first firstParser: Parser<Character>, repeating repeatedParser: Parser<Character>,
    atLeastOne: Bool = false) -> Parser<String> {
    
    return many(first: firstParser, repeating: repeatedParser, atLeastOne: atLeastOne,
                makeHandler: CharacterCollector.init)
}

private struct CharacterCollector: ValueHandling {
    var result: String = ""
    mutating func valueOccurred(_ value: Character) {
        result.append(value)
    }
}

public func manyStrings<S: Sequence>(
    _ repeatedParser: Parser<S>,
    atLeastOne: Bool = false) -> Parser<String> where S.Element == Character {
    
    return manyStrings(first: repeatedParser, repeating: repeatedParser,
                       atLeastOne: atLeastOne)
}

public func manyStrings<S1: Sequence, S2: Sequence>(
    first firstParser: Parser<S1>, repeating repeatedParser: Parser<S2>,
    atLeastOne: Bool = false
    ) -> Parser<String> where S1.Element == Character, S2.Element == Character {
    
    return many(first: firstParser >>| Substring.init,
                repeating: repeatedParser >>| Substring.init,
                atLeastOne: atLeastOne,
                makeHandler: StringCollector.init)
}

private struct StringCollector: ValueHandling {
    var result: String = ""
    mutating func valueOccurred(_ value: Substring) {
        result += value
    }
}

public func manyStrings<S1: Sequence, S2: Sequence>(
    _ parser: Parser<S1>, separator: Parser<S2>, includeSeparator: Bool,
    allowEndBySeparator: Bool = false
    ) -> Parser<String> where S1.Element == Character, S2.Element == Character {
    
    let makeHandler = { StringSeparatorCollector.init(includeSeparator: includeSeparator) }
    return many(parser >>| Substring.init,
                separator: separator >>| Substring.init,
                atLeastOne: false, allowEndBySeparator: allowEndBySeparator,
                makeHandler: makeHandler)
}

private final class StringSeparatorCollector: ValueHandling, SeparatorHandling {
    var result: String = ""
    var handleSeparator: (Substring) -> () = { _ in }
    
    init(includeSeparator: Bool) {
        if includeSeparator {
            self.handleSeparator = { [unowned self] in self.result += $0 }
        }
    }
    
    func valueOccurred(_ value: Substring) {
        result += value
    }
    
    func separatorOccurred(_ separator: Substring) {
        handleSeparator(separator)
    }
}

public func skip<T1, T2>(
    _ parser: Parser<T1>, apply transform: @escaping (T1, Substring) -> T2) -> Parser<T2> {
    
    return Parser { stream in
        let start = stream.nextIndex
        return parser.parse(stream)
            .map { transform($0, stream.readUpToNextIndex(from: start)) }
    }
}

public func stringSkipped<T>(by parser: Parser<T>) -> Parser<Substring> {
    return skip(parser, apply: { (_, substr) in substr })
}

// MARK: - Conditional parsing

public func endOfStream() -> Parser<Void> {
    return Parser { stream in
        return stream.isAtEnd ? .success((), []) : .failure([ParseError.Expected("end of stream")])
    }
}

public func notEndOfStream() -> Parser<Void> {
    return not(endOfStream(), errors: [ParseError.Unexpected("end of stream")])
}

private func not(
    _ parser: Parser<Void>, errors: @autoclosure @escaping () -> [Error]) -> Parser<Void> {
    
    return Parser { stream in
        if case .success = parser.parse(stream) {
            return .failure(errors())
        }
        return .success((), [])
    }
}

public func followed(
    by predicate: @escaping (Character) -> Bool,
    errorLabel: String? = nil) -> Parser<Void> {
    
    return followed(by: predicate, errors: errorLabel.map { [ParseError.Expected($0)] } ?? [])
}

private func followed(
    by predicate: @escaping (Character) -> Bool,
    errors: @autoclosure @escaping () -> [Error]) -> Parser<Void> {
    
    return Parser { stream in
        return stream.matches(predicate) ? .success((), []) : .failure(errors())
    }
}

public func followedByNewline() -> Parser<Void> {
    return followed(by: isNewline, errors: [ParseError.Expected("newline")])
}

public func notFollowedByNewline() -> Parser<Void> {
    return not(followedByNewline(), errors: [ParseError.Unexpected("newline")])
}

public func followed(
    by str: String, case caseSensitivity: StringSensitivity = .sensitive) -> Parser<Void> {
    
    return Parser { stream in
        if stream.matches(str, case: caseSensitivity) {
            return .success((), [])
        }
        return .failure([ParseError.ExpectedString(str, case: caseSensitivity)])
    }
}

public func notFollowed(
    by str: String, case caseSensitivity: StringSensitivity = .sensitive) -> Parser<Void> {
    
    return not(followed(by: str, case: caseSensitivity),
               errors: [ParseError.UnexpectedString(str, case: caseSensitivity)])
}

public func preceded(
    by predicate: @escaping (Character) -> Bool,
    errorLabel: String? = nil) -> Parser<Void> {
    
    return preceded(by: predicate, errors: errorLabel.map { [ParseError.Expected($0)] } ?? [])
}

private func preceded(
    by predicate: @escaping (Character) -> Bool,
    errors: @autoclosure @escaping () -> [Error]) -> Parser<Void> {
    
    return Parser { stream in
        if let c = stream.peek(offset: -1), predicate(c) {
            return .success((), [])
        }
        return .failure(errors())
    }
}



