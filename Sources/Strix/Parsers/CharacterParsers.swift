import Foundation

extension Parser where T == Character {
    /// `satisfy(label, predicate)` parses any one character for which
    /// the function `predicate` returns `true`. It returns the parsed character.
    public static func satisfy(
        _ label: String,
        _ predicate: @escaping (Character) -> Bool
    ) -> Parser<Character> {
        return Parser { state in
            if let c = state.stream.first, predicate(c) {
                return .success(c, state.advanced())
            }
            return .failure([.expected(label: label)], state)
        }
    }
    
    /// Use the ``satisfy(_:_:)`` instead.
    @available(*, deprecated, renamed: "satisfy(_:_:)")
    public static func satisfy(
        _ predicate: @escaping (Character) -> Bool,
        label: String
    ) -> Parser<Character> {
        return satisfy(label, predicate)
    }
    
    /// `any(of: characterSet, label: label)` parses any character contained in the character set.
    /// It returns the parsed character.
    public static func any(of characterSet: CharacterSet, label: String) -> Parser<Character> {
        let predicate: (Character) -> Bool = { c in
            let scalars = String(c).precomposedStringWithCanonicalMapping.unicodeScalars
            let isSingleScalar = scalars.index(after: scalars.startIndex) == scalars.endIndex
            return isSingleScalar && characterSet.contains(scalars[scalars.startIndex])
        }
        return satisfy(label, predicate)
    }
    
    /// `any(of: sequence)` parses any character contained in the character sequence. It returns the parsed character.
    public static func any<S: Sequence>(
        of characters: S
    ) -> Parser<Character> where S.Element == Character {
        return satisfy("any character in [\(String(characters))]", characters.contains)
    }
    
    /// `none(of: sequence)` parses any character not contained in the character sequence. It returns the parsed character.
    public static func none<S: Sequence>(
        of characters: S
    ) -> Parser<Character> where S.Element == Character {
        return satisfy("any character not in [\(String(characters))]", { !characters.contains($0) })
    }
    
    /// `character(c)` parses the character `c` and returns `c`.
    public static func character(_ c: Character) -> Parser<Character> {
        return satisfy(String(c), { $0 == c })
    }
    
    /// `anyCharacter` parses any single character and returns the parsed character.
    public static var anyCharacter: Parser<Character> {
        return satisfy("any character", { _ in true })
    }
    
    /// Parses any alphanumeric character identified by `CharacterSet.alphanumerics`.
    public static var alphanumeric: Parser<Character> {
        return any(of: .alphanumerics, label: "alphanumeric")
    }
    
    /// Parses any letter character identified by `Character.isLetter`.
    public static var letter: Parser<Character> {
        return satisfy("letter", { $0.isLetter })
    }
    
    /// Parses any ASCII character identified by `Character.isASCII`.
    public static var ascii: Parser<Character> {
        return satisfy("ASCII letter", { $0.isASCII })
    }
    
    /// Parses any char in the range `"a"` - `"z"` and `"A"` - `"Z"`.
    public static var asciiLetter: Parser<Character> {
        return satisfy("ASCII letter", { ("a"..."z").contains($0) || ("A"..."Z").contains($0) })
    }
    
    /// Parses any character in the range `"a"` - `"z"`.
    public static var asciiLowercase: Parser<Character> {
        return satisfy("ASCII lowercase letter", { ("a"..."z").contains($0) })
    }
    
    /// Parses any character in the range `"A"` - `"Z"`.
    public static var asciiUppercase: Parser<Character> {
        return satisfy("ASCII uppercase letter", { ("A"..."Z").contains($0) })
    }
    
    /// Parses any character in the range `"0"` - `"9"`.
    public static var decimalDigit: Parser<Character> {
        return satisfy("decimal digit", { ("0"..."9").contains($0) })
    }
    
    /// Parses any character in the range `"0"` - `"9"`, `"A"` - `"F"`, and `"a"` - `"f"`.
    public static var hexadecimalDigit: Parser<Character> {
        let ranges: [ClosedRange<Character>] = ["0"..."9", "A"..."F", "a"..."f"]
        return satisfy("hexadecimal digit", { c in ranges.contains(where: { $0.contains(c) }) })
    }
    
    /// Parses any character in the range `"0"` - `"7"`.
    public static var octalDigit: Parser<Character> {
        return satisfy("octal digit", { ("0"..."7").contains($0) })
    }
    
    /// Parses any character `"0"` or `"1"`.
    public static var binaryDigit: Parser<Character> {
        return satisfy("binary digit", { $0 == "0" || $0 == "1" })
    }
    
    /// Parses the space character.
    public static var space: Parser<Character> {
        return satisfy("space", { $0 == " " })
    }
    
    /// Parses the tab character.
    public static var tab: Parser<Character> {
        return satisfy("tab", { $0 == "\t" })
    }
    
    /// Parses any newline character identified by `Character.isNewline`.
    public static var newline: Parser<Character> {
        return satisfy("newline", { $0.isNewline })
    }
    
    /// Parses any whitespace character identified by `Character.isWhitespace`.
    public static var whitespace: Parser<Character> {
        return satisfy("whitespace", { $0.isWhitespace })
    }
    
    /// Parses any horizontal whitespace character identified by
    /// `Character.isWhitespace` and not `Character.isNewline`.
    public static var horizontalWhitespace: Parser<Character> {
        return satisfy("horizontal whitespace", { $0.isWhitespace && !$0.isNewline })
    }
}
