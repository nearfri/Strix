
infix operator >>- : AdditionPrecedence
infix operator |>> : AdditionPrecedence
infix operator ^>> : AdditionPrecedence
infix operator >>% : AdditionPrecedence
infix operator >>! : AdditionPrecedence
infix operator !>> : AdditionPrecedence
infix operator !>>! : AdditionPrecedence
infix operator <|> : AdditionPrecedence
infix operator <?> : AdditionPrecedence
infix operator <??> : AdditionPrecedence

// MARK: - Pure

public func pure<T>(_ reply: Reply<T>) -> Parser<T> {
    return Parser { _ in reply }
}

public func pure<T>(_ v: T) -> Parser<T> {
    return Parser { _ in .success(v, []) }
}

// MARK: - Chaining and piping parsers

public func >>- <T1, T2>(p: Parser<T1>, f: @escaping (T1) -> Parser<T2>) -> Parser<T2> {
    return p.flatMap(f)
}

public func |>> <T1, T2>(p: Parser<T1>, f: @escaping (T1) -> T2) -> Parser<T2> {
    return p.map(f)
}

public func ^>> <T1, T2>(p: Parser<T1>, f: @escaping (T1) -> Reply<T2>) -> Parser<T2> {
    return p >>- { a in pure(f(a)) }
}

public func >>% <T1, T2>(p: Parser<T1>, x: T2) -> Parser<T2> {
    return p >>- { _ in pure(x) }
}

public func >>! <T1, T2>(p1: Parser<T1>, p2: Parser<T2>) -> Parser<T2> {
    return p1 >>- { _ in p2 }
}

public func !>> <T1, T2>(p1: Parser<T1>, p2: Parser<T2>) -> Parser<T1> {
    return p1 >>- { a in p2 >>% a }
}

public func !>>! <T1, T2>(p1: Parser<T1>, p2: Parser<T2>) -> Parser<(T1, T2)> {
    return p1 >>- { a in p2 >>- { b in pure((a, b)) } }
}

public func between<T1, T2, T3>(open: Parser<T1>, close: Parser<T2>,
                    parser: Parser<T3>) -> Parser<T3> {
    return open >>! parser !>> close
}

public func pipe<T1, T2, T3>(_ p1: Parser<T1>, _ p2: Parser<T2>,
                 _ f: @escaping (T1, T2) -> T3) -> Parser<T3> {
    return p1 >>- { v1 in p2 >>- { v2 in pure(f(v1, v2)) } }
}

public func pipe<T1, T2, T3, T4>(_ p1: Parser<T1>, _ p2: Parser<T2>, _ p3: Parser<T3>,
                 _ f: @escaping (T1, T2, T3) -> T4) -> Parser<T4> {
    return p1 >>- { v1 in p2 >>- { v2 in p3 >>- { v3 in pure(f(v1, v2, v3)) } } }
}

public func pipe<T1, T2, T3, T4, T5>(_ p1: Parser<T1>, _ p2: Parser<T2>, _ p3: Parser<T3>,
                 _ p4: Parser<T4>, _ f: @escaping (T1, T2, T3, T4) -> T5) -> Parser<T5> {
    return p1 >>- { v1 in p2 >>- { v2 in p3 >>- { v3 in p4 >>- { v4 in
        pure(f(v1, v2, v3, v4)) } } } }
}

public func pipe<T1, T2, T3, T4, T5, T6>(_ p1: Parser<T1>, _ p2: Parser<T2>,
                 _ p3: Parser<T3>, _ p4: Parser<T4>, _ p5: Parser<T5>,
                 _ f: @escaping (T1, T2, T3, T4, T5) -> T6) -> Parser<T6> {
    return p1 >>- { v1 in p2 >>- { v2 in p3 >>- { v3 in p4 >>- { v4 in p5 >>- { v5 in
        pure(f(v1, v2, v3, v4, v5)) } } } } }
}

// MARK: - Parsing alternatives and recovering from errors

public func <|> <T>(p1: Parser<T>, p2: Parser<T>) -> Parser<T> {
    return Parser { stream in
        let stateTag = stream.stateTag
        let reply = p1.parse(stream)
        guard case let .failure(e) = reply, stateTag == stream.stateTag else {
            return reply
        }
        let reply2 = p2.parse(stream)
        return stateTag == stream.stateTag && !e.isEmpty ? reply2.prepending(e) : reply2
    }
}

public func choice<T, S: Sequence>(_ ps: S) -> Parser<T> where S.Iterator.Element == Parser<T> {
    return Parser { stream in
        let stateTag = stream.stateTag
        var reply: Reply<T> = .failure([])
        var errors: [Error] = []
        for p in ps {
            guard case let .failure(e) = reply, stateTag == stream.stateTag else { break }
            errors += e
            reply = p.parse(stream)
        }
        if stateTag == stream.stateTag {
            reply.errors = errors + reply.errors
        }
        return reply
    }
}

public func optional<T>(_ p: Parser<T>) -> Parser<T?> {
    return p |>> Optional.init <|> pure(nil)
}

public func skipOptional<T>(_ p: Parser<T>) -> Parser<Void> {
    return p >>% () <|> pure(())
}

public func attempt<T>(_ p: Parser<T>) -> Parser<T> {
    return Parser { (stream) in
        let state = stream.state
        let reply = p.parse(stream)
        if case .success = reply { return reply }
        
        if state.tag == stream.stateTag {
            return .failure(reply.errors)
        }
        let nestedError = extractOrMakeNestedError(from: reply.errors, stream: stream)
        stream.backtrack(to: state)
        return .failure([nestedError])
    }
}

// MARK: - Conditional parsing and looking ahead

public func notEmpty<T>(_ p: Parser<T>) -> Parser<T> {
    return Parser { (stream) in
        let stateTag = stream.stateTag
        let reply = p.parse(stream)
        if case let .success(_, e) = reply, stateTag == stream.stateTag {
            return .failure(e)
        }
        return reply
    }
}

public func followed<T>(by p: Parser<T>, errorLabel: String? = nil) -> Parser<Void> {
    return Parser { (stream) in
        let state = stream.state
        let reply = p.parse(stream)
        if state.tag != stream.stateTag {
            stream.backtrack(to: state)
        }
        if case .success = reply {
            return .success((), [])
        }
        return .failure(errorLabel.map({ [ParseError.Expected($0)] }) ?? [])
    }
}

public func notFollowed<T>(by p: Parser<T>, errorLabel: String? = nil) -> Parser<Void> {
    return Parser { (stream) in
        let state = stream.state
        let reply = p.parse(stream)
        if state.tag != stream.stateTag {
            stream.backtrack(to: state)
        }
        if case .success = reply {
            return .failure(errorLabel.map({ [ParseError.Unexpected($0)] }) ?? [])
        }
        return .success((), [])
    }
}

public func lookAhead<T>(_ p: Parser<T>) -> Parser<T> {
    return Parser { (stream) in
        let state = stream.state
        let reply = p.parse(stream)
        if case let .success(v, _) = reply {
            if state.tag != stream.stateTag {
                stream.backtrack(to: state)
            }
            return .success(v, [])
        }
        if state.tag == stream.stateTag {
            return .failure(reply.errors)
        }
        let nestedError = extractOrMakeNestedError(from: reply.errors, stream: stream)
        stream.backtrack(to: state)
        return .failure([nestedError])
    }
}

// MARK: - Customizing error messages

public func <?> <T>(p: Parser<T>, errorLabel: String) -> Parser<T> {
    return Parser { (stream) in
        let stateTag = stream.stateTag
        var reply = p.parse(stream)
        if stateTag == stream.stateTag {
            reply.errors = [ParseError.Expected(errorLabel)]
        }
        return reply
    }
}

public func <??> <T>(p: Parser<T>, errorLabel: String) -> Parser<T> {
    return Parser { (stream) in
        let state = stream.state
        var reply = p.parse(stream)
        if case let .success(v, e) = reply {
            return .success(v, state.tag == stream.stateTag ? [ParseError.Expected(errorLabel)] : e)
        }
        
        if state.tag == stream.stateTag {
            if let error = extractAndMakeCompoundError(from: reply.errors, label: errorLabel) {
                reply.errors = [error]
            } else {
                reply.errors = [ParseError.Expected(errorLabel)]
            }
            return reply
        }
        
        let compoundError: ParseError.Compound
        if let error = extractAndMakeCompoundError(from: reply.errors, label: errorLabel) {
            compoundError = error
        } else {
            compoundError = ParseError.Compound(label: errorLabel, position: stream.position,
                                                userInfo: stream.userInfo, errors: reply.errors)
        }
        stream.backtrack(to: state)
        // state가 바뀌었던 걸 backtrack 한거라 fatalFailure를 리턴해서 일반적인 파싱은 더 이상 진행하지 않도록 한다
        return .fatalFailure([compoundError])
    }
}

public func fail<T>(_ message: String) -> Parser<T> {
    return pure(.failure([ParseError.Generic(message: message)]))
}

public func failFatally<T>(_ message: String) -> Parser<T> {
    return pure(.fatalFailure([ParseError.Generic(message: message)]))
}

// MARK: - Helper functions

private func extractSingleError<E: ParseError>(from errors: [Error]) -> E? {
    if errors.count == 1, let error = errors[0] as? E {
        return error
    }
    return nil
}

private func extractOrMakeNestedError(from errors: [Error],
                                      stream: CharacterStream) -> ParseError.Nested {
    if let error: ParseError.Nested = extractSingleError(from: errors) {
        return error
    }
    return ParseError.Nested(position: stream.position, userInfo: stream.userInfo, errors: errors)
}

private func extractAndMakeCompoundError(from errors: [Error],
                                         label: String) -> ParseError.Compound? {
    if let error: ParseError.Compound = extractSingleError(from: errors) {
        return ParseError.Compound(label: label, position: error.position,
                                   userInfo: error.userInfo, errors: error.errors)
    } else if let error: ParseError.Nested = extractSingleError(from: errors) {
        return ParseError.Compound(label: label, position: error.position,
                                   userInfo: error.userInfo, errors: error.errors)
    }
    return nil
}



