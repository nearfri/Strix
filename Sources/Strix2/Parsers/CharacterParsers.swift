import Foundation

extension Parser where T == Character {
    /// `satisfy(predicate)` parses any one character for which the predicate function returns `true`.
    /// It returns the parsed character.
    public static func satisfy(
        _ predicate: @escaping (Character) -> Bool,
        label: String
    ) -> Parser<Character> {
        return Parser { state in
            if let c = state.stream.first, predicate(c) {
                return .success(c, state.withStream(state.stream.dropFirst()))
            }
            return .failure(state, [.expected(label: label)])
        }
    }
    
    /// `any(of: characterSet)` parses any character contained in the character set. It returns the parsed character.
    public static func any(of characterSet: CharacterSet, label: String) -> Parser<Character> {
        let predicate: (Character) -> Bool = { c in
            let scalars = String(c).precomposedStringWithCanonicalMapping.unicodeScalars
            let isSingleScalar = scalars.index(after: scalars.startIndex) == scalars.endIndex
            return isSingleScalar && characterSet.contains(scalars.first!)
        }
        return satisfy(predicate, label: label)
    }
    
    /// `any(of: sequence)` parses any character contained in the character sequence. It returns the parsed character.
    public static func any<S: Sequence>(
        of characters: S
    ) -> Parser<Character> where S.Element == Character {
        return satisfy(characters.contains,
                       label: "any character in \(Array(characters))")
    }
    
    /// `none(of: sequence)` parses any character not contained in the character sequence. It returns the parsed character.
    public static func none<S: Sequence>(
        of characters: S
    ) -> Parser<Character> where S.Element == Character {
        return satisfy({ !characters.contains($0) },
                       label: "any character not in \(Array(characters))")
    }
    
    /// `character(c)` parses the character `c` and returns `c`.
    public static func character(_ c: Character) -> Parser<Character> {
        return satisfy({ $0 == c }, label: String(c))
    }
    
    /// `anyCharacter` parses any single character and returns the parsed character.
    public static var anyCharacter: Parser<Character> {
        return satisfy({ _ in true }, label: "any character")
    }
    
    /// Parses any alphanumeric character identified by `CharacterSet.alphanumerics`.
    public static var alphanumeric: Parser<Character> {
        return any(of: .alphanumerics, label: "alphanumeric")
    }
    
    /// Parses any letter character identified by `Character.isLetter`.
    public static var letter: Parser<Character> {
        return satisfy({ $0.isLetter }, label: "letter")
    }
    
    /// Parses any ASCII character identified by `Character.isASCII`.
    public static var ascii: Parser<Character> {
        return satisfy({ $0.isASCII }, label: "ASCII letter")
    }
    
    /// Parses any character in the range `"A"` - `"Z"`.
    public static var asciiUppercase: Parser<Character> {
        return satisfy({ ("A"..."Z").contains($0) }, label: "ASCII uppercase letter")
    }
    
    /// Parses any character in the range `"a"` - `"z"`.
    public static var asciiLowercase: Parser<Character> {
        return satisfy({ ("a"..."z").contains($0) }, label: "ASCII lowercase letter")
    }
    
    /// Parses any character in the range `"0"` - `"9"`.
    public static var decimalDigit: Parser<Character> {
        return satisfy({ ("0"..."9").contains($0) }, label: "decimal digit")
    }
    
    /// Parses any character in the range `"0"` - `"9"`, `"A"` - `"F"`, and `"a"` - `"f"`.
    public static var hexadecimalDigit: Parser<Character> {
        let ranges: [ClosedRange<Character>] = ["0"..."9", "A"..."F", "a"..."f"]
        return satisfy({ c in ranges.contains(where: { $0.contains(c) }) },
                       label: "hexadecimal digit")
    }
    
    /// Parses any character in the range `"0"` - `"7"`.
    public static var octalDigit: Parser<Character> {
        return satisfy({ ("0"..."7").contains($0) }, label: "octal digit")
    }
    
    /// Parses any character `"0"` or `"1"`.
    public static var binaryDigit: Parser<Character> {
        return satisfy({ $0 == "0" || $0 == "1" }, label: "binary digit")
    }
    
    /// Parses the space character.
    public static var space: Parser<Character> {
        return satisfy({ $0 == " " }, label: "tab")
    }
    
    /// Parses the tab character.
    public static var tab: Parser<Character> {
        return satisfy({ $0 == "\t" }, label: "tab")
    }
    
    /// Parses any newline character identified by `Character.isNewline`.
    public static var newline: Parser<Character> {
        return satisfy({ $0.isNewline }, label: "newline")
    }
    
    /// Parses any whitespace character identified by `Character.isWhitespace`.
    public static var whitespace: Parser<Character> {
        return satisfy({ $0.isWhitespace }, label: "whitespace")
    }
    
    /// Parses any horizontal whitespace character identified by
    /// `Character.isWhitespace` and not `Character.isNewline`.
    public static var horizontalWhitespace: Parser<Character> {
        return satisfy({ $0.isWhitespace && !$0.isNewline }, label: "horizontal whitespace")
    }
}
