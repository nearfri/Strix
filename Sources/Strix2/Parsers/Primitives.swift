import Foundation

extension Parser {
    public static func just(_ v: T) -> Parser<T> {
        return Parser { state in .success(v, state) }
    }
    
    public static func fail(message: String) -> Parser<T> {
        return Parser { state in .failure(state, [.generic(message: message)]) }
    }
    
    public static func discardFirst<U>(_ lhs: Parser<U>, _ rhs: Parser<T>) -> Parser<T> {
        return tuple(lhs, rhs).map({ $0.1 })
    }
    
    public static func discardSecond<U>(_ lhs: Parser<T>, _ rhs: Parser<U>) -> Parser<T> {
        return tuple(lhs, rhs).map({ $0.0 })
    }
    
    public static func tuple<T1, T2>(_ p1: Parser<T1>, _ p2: Parser<T2>) -> Parser<(T1, T2)> {
        return p1.flatMap { v1 in p2.map { v2 in (v1, v2) } }
    }
    
    public static func tuple<T1, T2, T3>(
        _ p1: Parser<T1>,
        _ p2: Parser<T2>,
        _ p3: Parser<T3>
    ) -> Parser<(T1, T2, T3)> {
        return p1.flatMap { v1 in p2.flatMap { v2 in p3.map { v3 in (v1, v2, v3) } } }
    }
    
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

    public static func alternative(_ lhs: Parser<T>, _ rhs: Parser<T>) -> Parser<T> {
        return Parser { state in
            let reply = lhs.parse(state)
            
            if reply.result.isSuccess || reply.state != state {
                return reply
            }
            
            return rhs.parse(state).compareStateAndPrependingErrors(of: reply)
        }
    }
    
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
}
