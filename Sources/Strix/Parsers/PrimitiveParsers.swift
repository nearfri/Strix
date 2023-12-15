import Foundation

private typealias P<A> = Parser<A>

extension Parser {
    /// The parser `just(v)` always succeeds with the result `v` (without changing the parser state).
    public static func just(_ v: T) -> Parser<T> {
        return Parser { state in .success(v, state) }
    }
    
    /// The parser `fail(message: message)` always fails with a `.generic(message:)`.
    /// The string `message` will be displayed together with other error messages generated for the same input position.
    public static func fail(message: String) -> Parser<T> {
        return Parser { state in .failure([.generic(message: message)], state) }
    }
    
    /// The parser `discardFirst(lhs, rhs)` applies the parsers `lhs` and `rhs`
    /// in sequence and returns the result of `rhs`.
    public static func discardFirst<U>(_ lhs: Parser<U>, _ rhs: Parser<T>) -> Parser<T> {
        return lhs.flatMap { _ in rhs }
    }
    
    /// The parser `discardFirst(lhs, rhs)` applies the parsers `lhs` and `rhs`
    /// in sequence and returns the result of `lhs`.
    public static func discardSecond<U>(_ lhs: Parser<T>, _ rhs: Parser<U>) -> Parser<T> {
        return lhs.flatMap { v1 in rhs.map { _ in v1 } }
    }
    
    /// The parser `tuple(p0, p1)` applies the parsers `p0` and `p1` in sequence and returns the results in a tuple.
    public static func tuple<T0, T1>(
        _ p0: Parser<T0>,
        _ p1: Parser<T1>
    ) -> Parser<T> where T == (T0, T1) {
        return p0.flatMap { v0 in p1.map { v1 in (v0, v1) } }
    }
    
    /// The parser `tuple(p0, p1, p2)` applies the parsers `p0`, `p1`, and `p2`
    /// in sequence and returns the results in a tuple.
    public static func tuple<T0, T1, T2>(
        _ p0: Parser<T0>,
        _ p1: Parser<T1>,
        _ p2: Parser<T2>
    ) -> Parser<T> where T == (T0, T1, T2) {
        return p0.flatMap { v0 in p1.flatMap { v1 in p2.map { v2 in (v0, v1, v2) } } }
    }
    
    /// The parser `tuple(p0, p1, p2, p3)` applies the parsers `p0`, `p1`, `p2`, and `p3`
    /// in sequence and returns the results in a tuple.
    public static func tuple<T0, T1, T2, T3>(
        _ p0: Parser<T0>,
        _ p1: Parser<T1>,
        _ p2: Parser<T2>,
        _ p3: Parser<T3>
    ) -> Parser<T> where T == (T0, T1, T2, T3) {
        return P.tuple(p0, p1, p2).flatMap { vs in
            p3.map { v3 in (vs.0, vs.1, vs.2, v3) }
        }
    }
    
    /// The parser `tuple(p0, p1, p2, p3, p4)` applies the parsers `p0`, `p1`, `p2`, `p3`, and `p4`
    /// in sequence and returns the results in a tuple.
    public static func tuple<T0, T1, T2, T3, T4>(
        _ p0: Parser<T0>,
        _ p1: Parser<T1>,
        _ p2: Parser<T2>,
        _ p3: Parser<T3>,
        _ p4: Parser<T4>
    ) -> Parser<T> where T == (T0, T1, T2, T3, T4) {
        return P.tuple(p0, p1, p2, p3).flatMap { vs in
            p4.map { v4 in (vs.0, vs.1, vs.2, vs.3, v4) }
        }
    }
    
    /// The parser `tuple(p0, p1, p2, p3, p4, p5)` applies the parsers `p0`, `p1`, `p2`, `p3`, `p4`, and `p5`
    /// in sequence and returns the results in a tuple.
    public static func tuple<T0, T1, T2, T3, T4, T5>(
        _ p0: Parser<T0>,
        _ p1: Parser<T1>,
        _ p2: Parser<T2>,
        _ p3: Parser<T3>,
        _ p4: Parser<T4>,
        _ p5: Parser<T5>
    ) -> Parser<T> where T == (T0, T1, T2, T3, T4, T5) {
        return P.tuple(p0, p1, p2, p3, p4).flatMap { vs in
            p5.map { v5 in (vs.0, vs.1, vs.2, vs.3, vs.4, v5) }
        }
    }
    
    /// The parser `tuple(p0, p1, p2, p3, p4, p5, p6)` applies the parsers
    /// `p0`, `p1`, `p2`, `p3`, `p4`, `p5`, and `p6` in sequence and returns the results in a tuple.
    public static func tuple<T0, T1, T2, T3, T4, T5, T6>(
        _ p0: Parser<T0>,
        _ p1: Parser<T1>,
        _ p2: Parser<T2>,
        _ p3: Parser<T3>,
        _ p4: Parser<T4>,
        _ p5: Parser<T5>,
        _ p6: Parser<T6>
    ) -> Parser<T> where T == (T0, T1, T2, T3, T4, T5, T6) {
        return P.tuple(p0, p1, p2, p3, p4, p5).flatMap { vs in
            p6.map { v6 in (vs.0, vs.1, vs.2, vs.3, vs.4, vs.5, v6) }
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
    
    /// The parser `one(of: parsers)` is an optimized implementation of `p1 <|> p2 <|> ... <|> pn`,
    /// where `p1` ... `pn` are the parsers in the sequence `parsers`.
    public static func one<S: Sequence>(of parsers: S) -> Parser<T> where S.Element == Parser<T> {
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
            
            return .failure(errors, state)
        }
    }
    
    @available(*, deprecated, renamed: "one(of:)")
    public static func any<S: Sequence>(of parsers: S) -> Parser<T> where S.Element == Parser<T> {
        return one(of: parsers)
    }
    
    /// The parser `optional(p)` parses an optional occurrence of `p` as an option value.
    public static func optional<U>(_ p: Parser<U>) -> Parser<T> where T == U? {
        return p.map({ Optional($0) }) <|> .just(nil)
    }
    
    /// The parser `notEmpty(p)` behaves like `p`, except that it fails when `p` succeeds without changing the parser state.
    public static func notEmpty(_ p: Parser<T>) -> Parser<T> {
        return Parser { state in
            let reply = p.parse(state)
            if reply.result.isSuccess && reply.state == state {
                return .failure(reply.errors, state)
            }
            return reply
        }
    }
    
    /// The parser `one(p, label: label)` applies the parser `p`.
    /// If `p` does not change the parser state (usually because `p` failed),
    /// the errors are replaced with `.expected(label:)`.
    public static func one(_ p: Parser<T>, label: String) -> Parser<T> {
        return one(p, satisfying: { _ in true }, label: label)
    }
    
    /// The parser `one(p, satisfying: predicate, label: label)` applies the parser `p`.
    /// If the function `predicate` returns `false`, backtrack to the original parser state
    /// and fails with `.expected(label: label)`.
    /// If `p` does not change the parser state (usually because `p` failed),
    /// the errors are replaced with `.expected(label:)`.
    public static func one(
        _ p: Parser<T>,
        satisfying predicate: @escaping (T) -> Bool,
        label: String
    ) -> Parser<T> {
        return Parser { state in
            let reply = p.parse(state)
            if let value = reply.result.value, !predicate(value) {
                return .failure([.expected(label: label)], state)
            }
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
                return .failure(reply.errors, state)
            }
            return .failure([.nested(position: reply.state.position, errors: reply.errors)], state)
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
                    return .failure([.compound(label: label, position: pos, errors: errs)], state)
                default:
                    return .failure([.expected(label: label)], state)
                }
            } else {
                switch (reply.errors.count, reply.errors.first) {
                case let (1, .nested(pos, errs)):
                    return .failure([.compound(label: label, position: pos, errors: errs)], state)
                default:
                    let (pos, errs) = (reply.state.position, reply.errors)
                    return .failure([.compound(label: label, position: pos, errors: errs)], state)
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
            
            if case let .success(v, _) = reply.result {
                return .success(v, state)
            }
            
            if reply.state == state {
                return reply
            }
            
            if reply.errors.count == 1, case .nested = reply.errors[0] {
                return .failure(reply.errors, state)
            }
            return .failure([.nested(position: reply.state.position, errors: reply.errors)], state)
        }
    }
    
    /// `recursive({ placeholder in subject(placeholder) })` creates a recursive parser that forwards all calls
    /// to the parser `subject`. `placeholder` also forwards all calls to `subject`.
    /// It can be used to parse nested expressions like JSON.
    public static func recursive(_ body: (Parser<T>) -> Parser<T>) -> Parser<T> {
        return RecursiveParserGenerator().make(body)
    }
}

extension Parser where T == Void {
    /// The parser `endOfStream` only succeeds at the end of the input. It never consumes input.
    public static var endOfStream: Parser<Void> {
        return Parser { state in
            if state.stream.startIndex == state.stream.endIndex {
                return .success((), state)
            }
            return .failure([.expected(label: "end of stream")], state)
        }
    }
    
    /// The parser `follow(p)` succeeds if the parser `p` succeeds. Otherwise it fails with `.expected(label: label)`.
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
            return .failure([error], state)
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
            return .failure([error], state)
        }
    }
    
    /// The parser `skip(p)` skips over the result of `p`.
    public static func skip<U>(_ p: Parser<U>) -> Parser<Void> {
        return p.map({ _ in () })
    }
    
    /// The parser `updateUserInfo(f)` sets the user info to `f(u)`, where `u` is the current `UserInfo`.
    public static func updateUserInfo(
        _ transform: @escaping (inout UserInfo) -> Void
    ) -> Parser<Void> {
        return Parser { state in
            var state = state
            transform(&state.userInfo)
            return .success((), state)
        }
    }
    
    /// The parser `satisfyUserInfo(predicate, message: message)` succeeds if the function `predicate`
    /// returns `true` when applied to the current `UserInfo`, otherwise it fails.
    public static func satisfyUserInfo(
        _ predicate: @escaping (UserInfo) -> Bool,
        message: String
    ) -> Parser<Void> {
        return Parser { state in
            if predicate(state.userInfo) {
                return .success((), state)
            }
            return .failure([.generic(message: message)], state)
        }
    }
}

/// `RecursiveParserGenerator` is used to parse nested expressions like ASCIIPlist or JSON.
///
/// In this example, `placeholder` is a placeholder for `subject`. It can be nested inside dictionary or array.
///
///     let generator = RecursiveParserGenerator<ASCIIPlist>()
///     let placeholder = generator.placeholder
///     generator.subject = .any(of: [dictionary(placeholder), array(placeholder), string, data])
///     let plist = generator.make()
public class RecursiveParserGenerator<T> {
    private class ParserObject {
        var parse: (ParserState) -> ParserReply<T>
        
        init(_ parse: @escaping (ParserState) -> ParserReply<T>) {
            self.parse = parse
        }
    }
    
    private let subjectParser: ParserObject
    private let placeholderParser: ParserObject
    
    public init() {
        subjectParser = ParserObject { _ in
            preconditionFailure("a recursive parser was not initialized")
        }
        
        placeholderParser = ParserObject { [unowned subjectParser] in
            return subjectParser.parse($0)
        }
    }
    
    public func make(_ body: (_ placeholder: Parser<T>) -> Parser<T>) -> Parser<T> {
        subject = body(placeholder)
        return make()
    }
    
    public var subject: Parser<T> {
        get { Parser(subjectParser.parse) }
        set { subjectParser.parse = newValue.parse }
    }
    
    public var placeholder: Parser<T> {
        return Parser { [placeholderParser] in
            return placeholderParser.parse($0)
        }
    }
    
    public func make() -> Parser<T> {
        return Parser { [subjectParser] in
            return subjectParser.parse($0)
        }
    }
}
