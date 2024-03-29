import Foundation

extension Parser where T == String {
    private typealias SubParser = Parser<Substring>
    
    /// `string(str, caseSensitive: flag)` parses the string `str` and returns the parsed string.
    /// It is an atomic parser: either it succeeds or it fails without consuming any input.
    public static func string(_ str: String, caseSensitive: Bool = true) -> Parser<String> {
        return SubParser.substring(str, caseSensitive: caseSensitive).map({ String($0) })
    }
    
    /// `string(until: boundary, caseSensitive: caseFlag, skipBoundary: skipBoundary)`
    /// parses all characters before the first occurance of the string `boundary` and,
    /// if `skipBoundary` is `true`, skips over `boundary`. It returns the parsed characters before the string.
    /// It is an atomic parser: either it succeeds or it fails without consuming any input.
    public static func string(
        until boundary: String,
        caseSensitive: Bool = true,
        skipBoundary: Bool = false
    ) -> Parser<String> {
        return SubParser.substring(
            until: boundary,
            caseSensitive: caseSensitive,
            skipBoundary: skipBoundary
        )
        .map({ String($0) })
    }
    
    /// `string(matchingRegex: pattern, label: label)` matches the regular expression given by the `pattern`.
    /// If the regular expression matches, the parser skips the matched characters and returns them as a string.
    /// If the regular expression does not match, the parser fails without consuming input.
    public static func string(matchingRegex pattern: String, label: String) -> Parser<String> {
        return SubParser.substring(matchingRegex: pattern, label: label).map({ String($0) })
    }
    
    /// `skipped(by: p)` applies the parser `p` and returns the characters skipped over by `p` as a string.
    public static func skipped<U>(by p: Parser<U>) -> Parser<String> {
        return SubParser.skippedSubstring(by: p).map({ String($0) })
    }
    
    /// `restOfLine(strippingNewline: flag)` parses any characters before the end of the line and
    /// skips to the beginning of the next line. It returns the parsed characters before the end of the line as a string.
    public static func restOfLine(strippingNewline: Bool = true) -> Parser<String> {
        return SubParser.restSubstringOfLine(strippingNewline: strippingNewline).map({ String($0) })
    }
}

extension Parser where T == Substring {
    /// `substring(str, caseSensitive: flag)` parses the string `str` and returns the parsed string.
    /// It is an atomic parser: either it succeeds or it fails without consuming any input.
    public static func substring(_ str: String, caseSensitive: Bool = true) -> Parser<Substring> {
        let equal: (Character, Character) -> Bool = {
            return caseSensitive
                ? { lhs, rhs in lhs == rhs }
                : { lhs, rhs in lhs.lowercased() == rhs.lowercased() }
        }()
        
        return Parser { state in
            let stream = state.stream
            var streamIndex = stream.startIndex
            var strIndex = str.startIndex
            
            while true {
                if strIndex == str.endIndex {
                    return .success(stream[stream.startIndex..<streamIndex],
                                    state.withStream(stream[streamIndex...]))
                }
                if streamIndex == stream.endIndex || !equal(stream[streamIndex], str[strIndex]) {
                    let error = ParseError.expectedString(string: str, caseSensitive: caseSensitive)
                    return .failure([error], state)
                }
                
                streamIndex = stream.index(after: streamIndex)
                strIndex = str.index(after: strIndex)
            }
        }
    }
    
    /// `substring(until: boundary, caseSensitive: caseFlag, skipBoundary: skipBoundary)`
    /// parses all characters before the first occurance of the string `boundary` and,
    /// if `skipBounday` is `true`, skips over `boundary`. It returns the parsed characters before the string.
    /// It is an atomic parser: either it succeeds or it fails without consuming any input.
    public static func substring(
        until boundary: String,
        caseSensitive: Bool = true,
        skipBoundary: Bool = false
    ) -> Parser<Substring> {
        let stringParser: Parser<Substring> = .substring(boundary, caseSensitive: caseSensitive)
        
        return Parser { state in
            var newState = state
            while true {
                let reply = stringParser.parse(newState)
                if reply.result.isSuccess {
                    let value = state.stream[state.stream.startIndex..<newState.stream.startIndex]
                    return .success(value, skipBoundary ? reply.state : newState)
                }
                if newState.stream.startIndex == newState.stream.endIndex {
                    let message = "could not find the string '\(boundary)'"
                    return .failure([.generic(message: message)], state)
                }
                newState = newState.advanced()
            }
        }
    }
    
    /// `substring(matchingRegex: pattern, label: label)` matches the regular expression given by the `pattern`.
    /// If the regular expression matches, the parser skips the matched characters and returns them as a string.
    /// If the regular expression does not match, the parser fails without consuming input.
    public static func substring(
        matchingRegex pattern: String,
        label: String
    ) -> Parser<Substring> {
        do {
            let expression = try NSRegularExpression(pattern: pattern, options: [])
            
            return Parser { state in
                let input = state.stream.base
                let searchRange = NSRange(state.stream.startIndex..., in: input)
                let matchRange = expression
                    .firstMatch(in: input, options: [.anchored], range: searchRange)
                    .flatMap({ Range($0.range, in: input) })
                
                if let matchRange = matchRange {
                    return .success(input[matchRange],
                                    state.withStream(input[matchRange.upperBound...]))
                }
                return .failure([.expected(label: label)], state)
            }
        } catch {
            preconditionFailure("regex pattern \(pattern) is invalid")
        }
    }
    
    /// `skippedSubstring(by: p)` applies the parser `p` and returns the characters skipped over by `p` as a string.
    public static func skippedSubstring<U>(by p: Parser<U>) -> Parser<Substring> {
        return p.map({ _, substr in substr })
    }
    
    /// `restSubstringOfLine(strippingNewline: flag)` parses any characters before the end of the line and
    /// skips to the beginning of the next line. It returns the parsed characters before the end of the line as a string.
    public static func restSubstringOfLine(strippingNewline: Bool = true) -> Parser<Substring> {
        let notNewline: Parser<Character> = .satisfy("not newline", { !$0.isNewline })
        let letters: Parser<[Character]> = .many(notNewline)
        let newlineOrEOS: Parser<Void> = .skip(.newline) <|> .endOfStream
        
        if strippingNewline {
            return skippedSubstring(by: letters) <* newlineOrEOS
        } else {
            return skippedSubstring(by: letters <* newlineOrEOS)
        }
    }
}
