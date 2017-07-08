
// MARK: - Value and separator handlers

public protocol ValueHandling {
    associatedtype Value
    associatedtype Result
    
    var result: Result { get }
    mutating func valueOccurred(_ value: Value)
}

public protocol SeparatorHandling {
    associatedtype Separator
    
    mutating func separatorOccurred(_ separator: Separator)
}

private struct ValueCollector<Value>: ValueHandling {
    var result: [Value] = []
    mutating func valueOccurred(_ value: Value) {
        result.append(value)
    }
}

private struct ValueIgnorer<Value>: ValueHandling {
    var result: Void { return () }
    func valueOccurred(_ value: Value) {}
}

// MARK: - Parsing sequences

public func tuple<T1, T2>(_ p1: Parser<T1>, _ p2: Parser<T2>) -> Parser<(T1, T2)> {
    return pipe(p1, p2) { ($0, $1) }
}

public func tuple<T1, T2, T3>(
    _ p1: Parser<T1>, _ p2: Parser<T2>, _ p3: Parser<T3>) -> Parser<(T1, T2, T3)> {
    
    return pipe(p1, p2, p3) { ($0, $1, $2) }
}

public func tuple<T1, T2, T3, T4>(
    _ p1: Parser<T1>, _ p2: Parser<T2>, _ p3: Parser<T3>,
    _ p4: Parser<T4>) -> Parser<(T1, T2, T3, T4)> {
    
    return pipe(p1, p2, p3, p4) { ($0, $1, $2, $3) }
}

public func tuple<T1, T2, T3, T4, T5>(
    _ p1: Parser<T1>, _ p2: Parser<T2>, _ p3: Parser<T3>,
    _ p4: Parser<T4>, _ p5: Parser<T5>) -> Parser<(T1, T2, T3, T4, T5)> {
    
    return pipe(p1, p2, p3, p4, p5) { ($0, $1, $2, $3, $4) }
}

public func array<T>(_ parser: Parser<T>, count: Int) -> Parser<[T]> {
    return array(parser, count: count, makeHandler: ValueCollector.init)
}

public func skipArray<T>(_ parser: Parser<T>, count: Int) -> Parser<Void> {
    return array(parser, count: count, makeHandler: ValueIgnorer.init)
}

private func array<T, H: ValueHandling>(
    _ parser: Parser<T>, count: Int,
    makeHandler: @escaping () -> H) -> Parser<H.Result> where H.Value == T {
    
    return Parser { stream in
        var lastReply: Reply<T>? = nil
        var handler = makeHandler()
        var errors: [Error] = []
        for _ in 0..<count {
            let stateTag = stream.stateTag
            let reply = parser.parse(stream)
            lastReply = reply
            errors = stateTag != stream.stateTag ? reply.errors : errors + reply.errors
            if case let .success(v, _) = reply {
                handler.valueOccurred(v)
            } else {
                break
            }
        }
        switch lastReply {
        case nil, .success?:
            return .success(handler.result, errors)
        case .failure?:
            return .failure(errors)
        case .fatalFailure?:
            return .fatalFailure(errors)
        }
    }
}



