import Foundation

public struct Parser<T> {
    public let parse: (ParserState) -> ParserReply<T>
    
    /// Create an instance with the given parse function.
    public init(_ parse: @escaping (ParserState) -> ParserReply<T>) {
        self.parse = parse
    }
    
    /// The parser `p.map(f)` applies the parser `p` and returns the result of the function application `f(x)`,
    /// where `x` is the result returned by  `p`.
    public func map<U>(_ transform: @escaping (T) throws(ParseError) -> U) -> Parser<U> {
        return Parser<U> { state -> ParserReply<U> in
            return parse(state).map(transform)
        }
    }
    
    /// The parser `p.map(f)` applies the parser `p` and returns the result of the function application `f(x, str)`,
    /// where `x` is the result returned by  `p` and `str` is the substring skipped over by `p`.
    public func map<U>(_ transform: @escaping (T, Substring) throws(ParseError) -> U) -> Parser<U> {
        return Parser<U> { state in
            let stream = state.stream
            let reply = parse(state)
            let newStream = reply.state.stream
            
            // TODO: Using FullTypedThrows
            // https://forums.swift.org/t/where-is-fulltypedthrows/72346
            return reply.map { value throws(ParseError) in
                try transform(value, stream[stream.startIndex..<newStream.startIndex])
            }
        }
    }
    
    /// The parser `p.flatMap(f)` first applies the parser `p` to the input,
    /// then applies the function `f` to the result returned by `p` and finally applies the parser returned by `f` to the input.
    public func flatMap<U>(_ transform: @escaping (T) -> Parser<U>) -> Parser<U> {
        return Parser<U> { state -> ParserReply<U> in
            let reply = parse(state)
            switch reply.result {
            case .success(let v, _):
                return transform(v)
                    .parse(reply.state)
                    .compareStateAndPrependingErrors(of: reply)
            case .failure(let errors):
                return .failure(errors, reply.state)
            }
        }
    }
    
    /// The parser `p.flatMap(f)` first applies the parser `p` to the input,
    /// then applies the function `f` to the result returned by `p` and the substring skipped over by `p`
    /// and finally applies the parser returned by `f` to the input.
    public func flatMap<U>(_ transform: @escaping (T, Substring) -> Parser<U>) -> Parser<U> {
        return Parser<U> { state -> ParserReply<U> in
            let stream = state.stream
            let reply = parse(state)
            let newStream = reply.state.stream
            
            switch reply.result {
            case .success(let v, _):
                return transform(v, stream[stream.startIndex..<newStream.startIndex])
                    .parse(reply.state)
                    .compareStateAndPrependingErrors(of: reply)
            case .failure(let errors):
                return .failure(errors, reply.state)
            }
        }
    }
    
    /// The parser `p.label(label)` applies the parser `p`.
    /// If `p` does not change the parser state (usually because `p` failed),
    /// the errors are replaced with `.expected(label:)`.
    public func label(_ label: String) -> Parser<T> {
        return satisfying(label, { _ in true })
    }
    
    /// The parser `p.satisfying(label, predicate)` applies the parser `p`.
    /// If the function `predicate` returns `false`, backtrack to the original parser state
    /// and fails with `.expected(label: label)`.
    /// If `p` does not change the parser state (usually because `p` failed),
    /// the errors are replaced with `.expected(label:)`.
    public func satisfying(_ label: String, _ predicate: @escaping (T) -> Bool) -> Parser<T> {
        return Parser { state in
            let reply = parse(state)
            if let value = reply.result.value, !predicate(value) {
                return .failure([.expected(label: label)], state)
            }
            return reply.state != state ? reply : reply.withErrors([.expected(label: label)])
        }
    }
    
    /// The parser `p.print(label)` prints log messages before and after applying the parser `p`.
    public func print(_ label: String, to output: TextOutputStream? = nil) -> Parser<T> {
        let write: (String) -> Void = {
            if var output = output {
                return { output.write($0) }
            }
            return { Swift.print($0, terminator: "") }
        }()
        
        func print(state: ParserState, message: String) {
            let position = TextPosition(string: state.stream.base, index: state.position)
            let character = state.stream.first.map({ "\"\($0)\"" }) ?? "EOS"
            write("(\(position.line):\(position.column):\(character)): ")
            write("\(label): ")
            write(message + "\n")
        }
        
        return Parser { state in
            print(state: state, message: "enter")
            let reply = parse(state)
            print(state: reply.state, message: "leave: \(reply.result)")
            return reply
        }
    }
    
    /// `p.run(str)` runs the parser `p` on the content of the string `str`.
    public func run(_ input: String) throws(RunError) -> T {
        let initialState = ParserState(stream: input[...])
        
        let reply = parse(initialState)
        
        switch reply.result {
        case .success(let value, _):
            return value
        case .failure(let errors):
            throw RunError(input: input, position: reply.state.position, underlyingErrors: errors)
        }
    }
    
    /// `p(str)` runs the parser `p` on the content of the string `str`.
    public func callAsFunction(_ input: String) throws(RunError) -> T {
        return try run(input)
    }
    
    /// `p.parse(&state)` parses with changing the `state` and returns the result in type of a `ParserResult`.
    public func parse(_ state: inout ParserState) -> ParserResult<T> {
        let reply = parse(state)
        state = reply.state
        return reply.result
    }
}
