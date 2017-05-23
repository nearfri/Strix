
infix operator >>- : AdditionPrecedence
infix operator |>> : AdditionPrecedence
infix operator ^>> : AdditionPrecedence
infix operator >>% : AdditionPrecedence
infix operator >>! : AdditionPrecedence
infix operator !>> : AdditionPrecedence
infix operator !>>! : AdditionPrecedence
infix operator <|> : AdditionPrecedence

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
        guard stateTag == stream.stateTag, case let .failure(e) = reply else {
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
            guard stateTag == stream.stateTag, case let .failure(e) = reply else { break }
            errors += e
            reply = p.parse(stream)
        }
        if stateTag == stream.stateTag {
            reply.errors = errors + reply.errors
        }
        return reply
    }
}



