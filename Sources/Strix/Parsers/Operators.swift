import Foundation

infix operator <|> : AdditionPrecedence     // alternative
infix operator *> : AdditionPrecedence      // discard first
infix operator <* : AdditionPrecedence      // discard second
infix operator <?> : AdditionPrecedence     // one with label
infix operator <!> : AdditionPrecedence     // print

extension Parser {
    /// `lhs <|> rhs` is equivalent to `alternative(lhs, rhs)`.
    public static func <|> (lhs: Parser<T>, rhs: Parser<T>) -> Parser<T> {
        return alternative(lhs, rhs)
    }
    
    /// `lhs *> rhs` is equivalent to `discardFirst(lhs, rhs)`.
    public static func *> <U>(lhs: Parser<U>, rhs: Parser<T>) -> Parser<T> {
        return discardFirst(lhs, rhs)
    }
    
    /// `lhs <* rhs` is equivalent to `discardSecond(lhs, rhs)`.
    public static func <* <U>(lhs: Parser<T>, rhs: Parser<U>) -> Parser<T> {
        return discardSecond(lhs, rhs)
    }
    
    /// `p <?> label` is equivalent to `p.label(label)`.
    public static func <?> (p: Parser<T>, label: String) -> Parser<T> {
        return p.label(label)
    }
    
    /// `p <!> label` is equivalent to `p.print(label)`.
    public static func <!> (p: Parser<T>, label: String) -> Parser<T> {
        return p.print(label)
    }
}
