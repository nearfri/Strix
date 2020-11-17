import Foundation

extension Parser {
    /// The parser `just(v)` always succeeds with the result `v` (without changing the parser state).
    public static func just(_ v: T) -> Parser<T> {
        return Parser { state in .success(v, state) }
    }
    
    /// The parser `fail(message: message)` always fails with a `.generic(message:)`.
    /// The string `message` will be displayed together with other error messages generated for the same input position.
    public static func fail(message: String) -> Parser<T> {
        return Parser { state in .failure(state, [.generic(message: message)]) }
    }
    
    /// The parser `discardFirst(lhs, rhs)` applies the parsers `lhs` and `rhs` in sequence and returns the result of `rhs`.
    public static func discardFirst<U>(_ lhs: Parser<U>, _ rhs: Parser<T>) -> Parser<T> {
        return tuple(lhs, rhs).map({ $0.1 })
    }
    
    /// The parser `discardFirst(lhs, rhs)` applies the parsers `lhs` and `rhs` in sequence and returns the result of `lhs`.
    public static func discardSecond<U>(_ lhs: Parser<T>, _ rhs: Parser<U>) -> Parser<T> {
        return tuple(lhs, rhs).map({ $0.0 })
    }
    
    /// The parser `tuple(p1, p2)` applies the parsers `p1` and `p2` in sequence and returns the results in a tuple.
    public static func tuple<T1, T2>(_ p1: Parser<T1>, _ p2: Parser<T2>) -> Parser<(T1, T2)> {
        return p1.flatMap { v1 in p2.map { v2 in (v1, v2) } }
    }
    
    /// The parser `tuple(p1, p2, p3)` applies the parsers `p1`, `p2`, and `p3` in sequence and returns the results in a tuple.
    public static func tuple<T1, T2, T3>(
        _ p1: Parser<T1>,
        _ p2: Parser<T2>,
        _ p3: Parser<T3>
    ) -> Parser<(T1, T2, T3)> {
        return p1.flatMap { v1 in p2.flatMap { v2 in p3.map { v3 in (v1, v2, v3) } } }
    }
    
    /// The parser `tuple(p1, p2, p3, p4)` applies the parsers `p1`, `p2`, `p3`, and `p4` in sequence
    /// and returns the results in a tuple.
    public static func tuple<T1, T2, T3, T4>(
        _ p1: Parser<T1>,
        _ p2: Parser<T2>,
        _ p3: Parser<T3>,
        _ p4: Parser<T4>
    ) -> Parser<(T1, T2, T3, T4)> {
        return tuple(p1, p2, p3).flatMap { vs in
            p4.map { v4 in (vs.0, vs.1, vs.2, v4) }
        }
    }
    
    /// The parser `tuple(p1, p2, p3, p4, p5)` applies the parsers `p1`, `p2`, `p3`, `p4`, and `p5` in sequence
    /// and returns the results in a tuple.
    public static func tuple<T1, T2, T3, T4, T5>(
        _ p1: Parser<T1>,
        _ p2: Parser<T2>,
        _ p3: Parser<T3>,
        _ p4: Parser<T4>,
        _ p5: Parser<T5>
    ) -> Parser<(T1, T2, T3, T4, T5)> {
        return tuple(p1, p2, p3, p4).flatMap { vs in
            p5.map { v5 in (vs.0, vs.1, vs.2, vs.3, v5) }
        }
    }
    
    /// The parser `alternative(lhs, rhs)` first applies the parser `lhs`. If `lhs` succeeds, the result of `lhs` is returned.
    /// If `lhs` fails *without changing the parser state*, the parser `rhs` is applied.
    /// Note: The stream position is part of the parser state, so if `lhs` fails after consuming input, `rhs` will not be applied.
    public static func alternative(_ lhs: Parser<T>, _ rhs: Parser<T>) -> Parser<T> {
        return Parser { state in
            let reply = lhs.parse(state)
            
            if reply.result.isSuccess || reply.state != state {
                return reply
            }
            
            return rhs.parse(state).compareStateAndPrependingErrors(of: reply)
        }
    }
    
    /// The parser `any(of: parsers)` is an optimized implementation of `p1 <|> p2 <|> ... <|> pn`,
    /// where `p1` ... `pn` are the parsers in the sequence `parsers`.
    public static func any<S: Sequence>(of parsers: S) -> Parser<T> where S.Element == Parser<T> {
        return Parser { state in
            var errors: [ParseError] = []
            
            for parser in parsers {
                let reply = parser.parse(state)
                
                if reply.state != state {
                    return reply
                }
                if reply.result.isSuccess {
                    return reply.prependingErrors(errors)
                }
                
                errors += reply.errors
            }
            
            return .failure(state, errors)
        }
    }
    
    /// The parser `optional(p)` parses an optional occurrence of `p` as an option value.
    public static func optional<U>(_ p: Parser<U>) -> Parser<U?> where T == U? {
        return p.map({ Optional($0) }) <|> .just(nil)
    }
    
    /// The parser `notEmpty(p)` behaves like `p`, except that it fails when `p` succeeds without changing the parser state.
    public static func notEmpty(_ p: Parser<T>) -> Parser<T> {
        return Parser { state in
            let reply = p.parse(state)
            if reply.result.isSuccess && reply.state == state {
                return .failure(state, reply.errors)
            }
            return reply
        }
    }
    
    /// The parser `one(p, label: label)` applies the parser `p`.
    /// If `p` does not change the parser state (usually because `p` failed),
    /// the errors are replaced with a `.expected(label:)`.
    public static func one(_ p: Parser<T>, label: String) -> Parser<T> {
        return Parser { state in
            let reply = p.parse(state)
            return reply.state != state ? reply : reply.withErrors([.expected(label: label)])
        }
    }
    
    /// The parser `attempt(p)` applies the parser `p`.
    /// If `p` fails after changing the parser state, backtrack to the original parser state and report a error.
    public static func attempt(_ p: Parser<T>) -> Parser<T> {
        return Parser { state in
            let reply = p.parse(state)
            
            if reply.result.isSuccess || reply.state == state {
                return reply
            }
            
            if reply.errors.count == 1, case .nested = reply.errors[0] {
                return .failure(state, reply.errors)
            }
            return .failure(state, [.nested(position: reply.state.position, errors: reply.errors)])
        }
    }
    
    /// The parser `attempt(p, label: label)` applies the parser `p`.
    /// If `p` fails without changing the parser state, the errors are replaced with `.expected(label:)`.
    /// If `p` fails after changing the parser state, backtrack to the original parser state
    /// and report a `.compound(label:position:errors:)`.
    public static func attempt(_ p: Parser<T>, label: String) -> Parser<T> {
        return Parser { state in
            let reply = p.parse(state)
            
            if reply.result.isSuccess {
                return reply.state != state ? reply : reply.withErrors([.expected(label: label)])
            }
            
            if reply.state == state {
                switch (reply.errors.count, reply.errors.first) {
                case let (1, .nested(pos, errs)), let (1, .compound(_, pos, errs)):
                    return .failure(state, [.compound(label: label, position: pos, errors: errs)])
                default:
                    return .failure(state, [.expected(label: label)])
                }
            } else {
                switch (reply.errors.count, reply.errors.first) {
                case let (1, .nested(pos, errs)):
                    return .failure(state, [.compound(label: label, position: pos, errors: errs)])
                default:
                    let (pos, errs) = (reply.state.position, reply.errors)
                    return .failure(state, [.compound(label: label, position: pos, errors: errs)])
                }
            }
        }
    }
    
    /// The parser` lookAhead(p)` parses `p` and restores the original parser state afterwards.
    /// If `p` fails after changing the parser state, the errors are wrapped in a `.nested(position:errors:)`.
    /// If it succeeds, any errors are discarded.
    public static func lookAhead(_ p: Parser<T>) -> Parser<T> {
        return Parser { state in
            let reply = p.parse(state)
            
            if case let .success(v) = reply.result {
                return .success(v, state)
            }
            
            if reply.state == state {
                return reply
            }
            
            if reply.errors.count == 1, case .nested = reply.errors[0] {
                return .failure(state, reply.errors)
            }
            return .failure(state, [.nested(position: reply.state.position, errors: reply.errors)])
        }
    }
    
    /// `skip(p, apply: f)` applies the parser `p` and returns the result `f(x, str)`,
    /// where `x` is the result returned by `p` and `str` is the substring skipped over by `p`.
    public static func skip<U>(
        _ p: Parser<U>,
        apply transform: @escaping (U, Substring) -> T
    ) -> Parser<T> {
        return Parser { state in
            let stream = state.stream
            let reply = p.parse(state)
            let newStream = reply.state.stream
            return reply.map({ transform($0, stream[stream.startIndex..<newStream.startIndex]) })
        }
    }
}

extension Parser where T == Void {
    /// The parser `endOfStream` only succeeds at the end of the input. It never consumes input.
    public static var endOfStream: Parser<Void> {
        return Parser { state in
            if state.stream.startIndex == state.stream.endIndex {
                return .success((), state)
            }
            return .failure(state, [.expected(label: "end of stream")])
        }
    }
    
    /// The parser `follow(p)` succeeds if the parser `p` succeeds. Otherwise it fails with a `.expected(label: label)`.
    /// This parser never changes the parser state.
    public static func follow<U>(_ p: Parser<U>, label: String) -> Parser<Void> {
        return follow(p, error: .expected(label: label))
    }
    
    /// The parser `follow(p)` succeeds if the parser `p` succeeds. Otherwise it fails with a `error`.
    /// This parser never changes the parser state.
    public static func follow<U>(_ p: Parser<U>, error: ParseError) -> Parser<Void> {
        return Parser { state in
            if p.parse(state).result.isSuccess {
                return .success((), state)
            }
            return .failure(state, [error])
        }
    }
    
    /// The parser `not(p)` succeeds if the parser `p` fails to parse. Otherwise it fails with a `.unexpected(label: label)`.
    /// This parser never changes the parser state.
    public static func not<U>(_ p: Parser<U>, label: String) -> Parser<Void> {
        return not(p, error: .unexpected(label: label))
    }
    
    /// The parser `not(p)` succeeds if the parser `p` fails to parse. Otherwise it fails with a `error`.
    /// This parser never changes the parser state.
    public static func not<U>(_ p: Parser<U>, error: ParseError) -> Parser<Void> {
        return Parser { state in
            if p.parse(state).result.isFailure {
                return .success((), state)
            }
            return .failure(state, [error])
        }
    }
    
    /// The parser `skip(p)` skips over the result of `p`.
    public static func skip<U>(_ p: Parser<U>) -> Parser<Void> {
        return p.map({ _ in () })
    }
}
