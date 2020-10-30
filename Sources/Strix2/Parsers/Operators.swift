import Foundation

infix operator <|> : AdditionPrecedence // alternative
infix operator *> : AdditionPrecedence  // discard first
infix operator <* : AdditionPrecedence  // discard second

extension Parser {
    public static func <|> (lhs: Parser<T>, rhs: Parser<T>) -> Parser<T> {
        return alternative(lhs, rhs)
    }
    
    public static func *> <U>(lhs: Parser<U>, rhs: Parser<T>) -> Parser<T> {
        return discardFirst(lhs, rhs)
    }
    
    public static func <* <U>(lhs: Parser<T>, rhs: Parser<U>) -> Parser<T> {
        return discardSecond(lhs, rhs)
    }
}
