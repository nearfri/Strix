
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

private struct ValueCollector<Value, Separator>: ValueHandling, SeparatorHandling {
    var result: [Value] = []
    mutating func valueOccurred(_ value: Value) {
        result.append(value)
    }
    func separatorOccurred(_ separator: Separator) {}
}

private struct ValueIgnorer<Value, Separator>: ValueHandling, SeparatorHandling {
    var result: Void { return () }
    func valueOccurred(_ value: Value) {}
    func separatorOccurred(_ separator: Separator) {}
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

// MARK: -

public func array<T>(_ parser: Parser<T>, count: Int) -> Parser<[T]> {
    return array(parser, count: count, makeHandler: ValueCollector<T, Void>.init)
}

public func skipArray<T>(_ parser: Parser<T>, count: Int) -> Parser<Void> {
    return array(parser, count: count, makeHandler: ValueIgnorer<T, Void>.init)
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

// MARK: -

public func many<T>(_ repeatedParser: Parser<T>, atLeastOne: Bool = false) -> Parser<[T]> {
    return many(first: repeatedParser, repeating: repeatedParser, atLeastOne: atLeastOne)
}

public func skipMany<T>(_ repeatedParser: Parser<T>, atLeastOne: Bool = false) -> Parser<Void> {
    return skipMany(first: repeatedParser, repeating: repeatedParser, atLeastOne: atLeastOne)
}

public func many<T>(
    first firstParser: Parser<T>, repeating repeatedParser: Parser<T>,
    atLeastOne: Bool = false) -> Parser<[T]> {
    
    return many(first: firstParser, repeating: repeatedParser,
                atLeastOne: atLeastOne, makeHandler: ValueCollector<T, Void>.init)
}

public func skipMany<T>(
    first firstParser: Parser<T>, repeating repeatedParser: Parser<T>,
    atLeastOne: Bool = false) -> Parser<Void> {
    
    return many(first: firstParser, repeating: repeatedParser,
                atLeastOne: atLeastOne, makeHandler: ValueIgnorer<T, Void>.init)
}

public func many<T, Handler: ValueHandling>(
    first firstParser: Parser<T>, repeating repeatedParser: Parser<T>, atLeastOne: Bool,
    makeHandler: @escaping () -> Handler) -> Parser<Handler.Result> where Handler.Value == T {
    
    return Parser { stream in
        var handler = makeHandler()
        var errors: [Error] = []
        
        func parse(with p: Parser<T>, successIfNoChangeFailure: Bool) -> Reply<Handler.Result>? {
            let stateTag: Int = stream.stateTag
            switch p.parse(stream) {
            case let .success(v, e):
                handler.valueOccurred(v)
                errors = e
                return nil
            case let .failure(e) where stateTag == stream.stateTag && successIfNoChangeFailure:
                return .success(handler.result, errors + e)
            case let .failure(e):
                return .failure(e)
            case let .fatalFailure(e):
                return .fatalFailure(stateTag != stream.stateTag ? e : errors + e)
            }
        }
        
        if let reply = parse(with: firstParser, successIfNoChangeFailure: !atLeastOne) {
            return reply
        }
        
        while true {
            let stateTag = stream.stateTag
            if let reply = parse(with: repeatedParser, successIfNoChangeFailure: true) {
                return reply
            }
            precondition(stateTag != stream.stateTag, infiniteLoopErrorMessage)
        }
    }
}

// MARK: -

public func many<T1, T2>(
    _ parser: Parser<T1>, separator: Parser<T2>, atLeastOne: Bool = false,
    allowEndBySeparator: Bool = false) -> Parser<[T1]> {
    
    return many(parser, separator: separator,
                atLeastOne: atLeastOne, allowEndBySeparator: allowEndBySeparator,
                makeHandler: ValueCollector<T1, T2>.init)
}

public func skipMany<T1, T2>(
    _ parser: Parser<T1>, separator: Parser<T2>, atLeastOne: Bool = false,
    allowEndBySeparator: Bool = false) -> Parser<Void> {
    
    return many(parser, separator: separator,
                atLeastOne: atLeastOne, allowEndBySeparator: allowEndBySeparator,
                makeHandler: ValueIgnorer<T1, T2>.init)
}

public func many<T1, T2, Handler: ValueHandling & SeparatorHandling>(
    _ parser: Parser<T1>, separator: Parser<T2>, atLeastOne: Bool,
    allowEndBySeparator: Bool, makeHandler: @escaping () -> Handler
    ) -> Parser<Handler.Result> where Handler.Value == T1, Handler.Separator == T2 {
    
    return Parser { stream in
        var handler = makeHandler()
        var errors: [Error] = []
        var valueCount = 0
        
        while true {
            let stateTag = stream.stateTag
            switch parser.parse(stream) {
            case let .success(v, e):
                precondition(stateTag != stream.stateTag, infiniteLoopErrorMessage)
                handler.valueOccurred(v)
                errors = e
                valueCount += 1
            case let .failure(e) where stateTag == stream.stateTag:
                let satisfiesAtLeastOne = !atLeastOne || valueCount > 0
                if satisfiesAtLeastOne && (allowEndBySeparator || valueCount == 0) {
                    return .success(handler.result, errors + e)
                }
                return .failure(errors + e)
            case let .failure(e):
                return .failure(e)
            case let .fatalFailure(e):
                return .fatalFailure(stateTag != stream.stateTag ? e : errors + e)
            }
            
            let sepStateTag = stream.stateTag
            switch separator.parse(stream) {
            case let .success(v, e):
                precondition(sepStateTag != stream.stateTag, infiniteLoopErrorMessage)
                handler.separatorOccurred(v)
                errors = e
            case let .failure(e) where sepStateTag == stream.stateTag:
                return .success(handler.result, errors + e)
            case let .failure(e):
                return .failure(e)
            case let .fatalFailure(e):
                return .fatalFailure(sepStateTag != stream.stateTag ? e : errors + e)
            }
        }
    }
}

// MARK: -

private var infiniteLoopErrorMessage: String = """
The combinator 'many' was applied to a parser that succeeds \
without consuming input and without changing the parser state in any other way. \
(If no exception had been raised, the combinator likely would have \
entered an infinite loop.)
"""



