import Foundation

extension Parser {
    /// The parser `repeat(p, count: count)` parses `count` occurrences of `p` and returns the results in an array.
    public static func `repeat`<U>(_ p: Parser<U>, count: Int) -> Parser<T> where T == [U] {
        return Parser { state in
            var state = state
            var values: [U] = []
            var errors: [ParseError] = []
            
            for _ in 0..<count {
                let reply = p.parse(state)
                errors = reply.state != state ? reply.errors : errors + reply.errors
                guard case let .success(v, _) = reply.result else {
                    return .failure(state, errors)
                }
                values.append(v)
                state = reply.state
            }
            return .success(values, errors, state)
        }
    }
    
    /// The parser `many(p)` repeatedly applies the parser `p` until `p` fails. It returns a list of the results returned by `p`.
    /// At the end of the sequence `p` must fail without changing the parser state,
    /// otherwise `many(p)` will fail with the error reported by `p`.
    /// If `p` succeeds without changing the parser state, it stops program execution to avoid an infinite loop.
    public static func many<U>(_ p: Parser<U>, minCount: Int = 0) -> Parser<T> where T == [U] {
        return many(first: p, repeating: p, minCount: minCount)
    }
    
    /// The parser `many(first: p1, repeating: p2)` first applies the parser `p1` to the input,
    /// then repeatedly applies the parser `p2` until `p2` fails. It returns a list of the results returned by `p1` and `p2`.
    /// At the end of the sequence `p2` must fail without changing the parser state,
    /// otherwise parsing will fail with the error reported by `p2`.
    /// If `p2` succeeds without changing the parser state, it stops program execution to avoid an infinite loop.
    public static func many<U>(
        first firstParser: Parser<U>,
        repeating repeatedParser: Parser<U>,
        minCount: Int = 0
    ) -> Parser<[U]> where T == [U] {
        return Parser { state in
            var parser = ManyParser(firstParser: firstParser,
                                    repeatedParser: repeatedParser,
                                    minCount: minCount,
                                    state: state)
            return parser.parse()
        }
    }
    
    /// The parser `many(p, separatedBy: sep)` parses occurrences of `p` separated by `sep`.
    /// It returns a list of the results returned by `p`.
    /// If `p` and `sep` succeeds without changing the parser state, it stops program execution to avoid an infinite loop.
    public static func many<U, V>(
        _ p: Parser<U>,
        separatedBy separator: Parser<V>,
        allowEndBySeparator: Bool = false,
        minCount: Int = 0
    ) -> Parser<T> where T == [U] {
        if !allowEndBySeparator {
            let repeatedParser: Parser<U> = separator *> p
            return many(first: p, repeating: repeatedParser, minCount: minCount)
        } else {
            let repeatedParser: Parser<U> = .attempt(separator *> p)
            return many(first: p, repeating: repeatedParser, minCount: minCount)
                <* .optional(separator)
        }
    }
}

private struct ManyParser<U> {
    private let firstParser: Parser<U>
    private let repeatedParser: Parser<U>
    private let minCount: Int
    
    private var state: ParserState
    private var values: [U] = []
    private var errors: [ParseError] = []
    
    init(firstParser: Parser<U>, repeatedParser: Parser<U>, minCount: Int, state: ParserState) {
        self.firstParser = firstParser
        self.repeatedParser = repeatedParser
        self.minCount = minCount
        self.state = state
    }
    
    mutating func parse() -> ParserReply<[U]> {
        let firstReply = firstParser.parse(state)
        switch firstReply.result {
        case let .success(value, errors):
            handleSuccess(value: value, newErrors: errors, newState: firstReply.state)
        case let .failure(errors):
            return handleFailure(newErrors: errors, newState: firstReply.state)
        }
        
        while true {
            let reply = repeatedParser.parse(state)
            switch reply.result {
            case let .success(value, errors):
                precondition(reply.state != state, infiniteLoopErrorMessage(at: state.position))
                handleSuccess(value: value, newErrors: errors, newState: reply.state)
            case let .failure(errors):
                return handleFailure(newErrors: errors, newState: reply.state)
            }
        }
    }
    
    private mutating func handleSuccess(value: U, newErrors: [ParseError], newState: ParserState) {
        values.append(value)
        errors = newErrors
        state = newState
    }
    
    private func handleFailure(newErrors: [ParseError], newState: ParserState) -> ParserReply<[U]> {
        if newState == state && values.count >= minCount {
            return .success(values, errors + newErrors, newState)
        }
        return .failure(newState, newErrors)
    }
    
    private func infiniteLoopErrorMessage(at position: Substring.Index) -> String {
        let textPosition = TextPosition(string: state.stream.base, index: position)
        
        return """
        Infinite loop at line \(textPosition.line), column \(textPosition.column):
        The combinator 'many' was applied to a parser that succeeds \
        without changing the parser state in any other way. \
        (If no exception had been raised, the combinator likely would have \
        entered an infinite loop.)
        """
    }
}
