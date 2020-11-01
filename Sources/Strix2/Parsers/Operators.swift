import Foundation

infix operator <|> : AdditionPrecedence     // alternative
infix operator *> : AdditionPrecedence      // discard first
infix operator <* : AdditionPrecedence      // discard second
infix operator <?> : AdditionPrecedence     // one with label
infix operator <??> : AdditionPrecedence    // attempt with label

extension Parser {
    /// `lhs <|> rhs` is equivalent to `laternative(lhs, rhs)`.
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
    
    /// `p <?> label` is equivalent to `one(p, label: label)`.
    public static func <?> (p: Parser<T>, label: String) -> Parser<T> {
        return one(p, label: label)
    }
    
    /// `p <??> label` is equivalent to `attempt(p, label: label)`.
    public static func <??> (p: Parser<T>, label: String) -> Parser<T> {
        return attempt(p, label: label)
    }
}
