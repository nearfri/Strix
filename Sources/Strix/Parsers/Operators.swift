import Foundation

infix operator <|> : AdditionPrecedence     // alternative
infix operator *> : AdditionPrecedence      // discard first
infix operator <* : AdditionPrecedence      // discard second
infix operator <?> : AdditionPrecedence     // one with label
infix operator <!> : AdditionPrecedence     // print

extension Parser {
    /// This operator is equivalent to ``alternative(_:_:)``.
    public static func <|> (lhs: Parser<T>, rhs: Parser<T>) -> Parser<T> {
        return alternative(lhs, rhs)
    }
    
    /// This operator is equivalent to ``discardFirst(_:_:)``.
    public static func *> <U>(lhs: Parser<U>, rhs: Parser<T>) -> Parser<T> {
        return discardFirst(lhs, rhs)
    }
    
    /// This operator is equivalent to ``discardSecond(_:_:)``.
    public static func <* <U>(lhs: Parser<T>, rhs: Parser<U>) -> Parser<T> {
        return discardSecond(lhs, rhs)
    }
    
    /// This operator is equivalent to ``label(_:)``.
    public static func <?> (p: Parser<T>, label: String) -> Parser<T> {
        return p.label(label)
    }
    
    /// This operator is equivalent to ``print(_:to:)`` with `nil` output stream.
    public static func <!> (p: Parser<T>, label: String) -> Parser<T> {
        return p.print(label)
    }
}
