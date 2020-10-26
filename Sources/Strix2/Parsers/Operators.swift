import Foundation

infix operator <|> : AdditionPrecedence // alternative
infix operator *> : AdditionPrecedence  // discard left
infix operator <* : AdditionPrecedence  // discard right

extension Parser {
    public static func <|> (lhs: Parser<T>, rhs: Parser<T>) -> Parser<T> {
        return alternative(lhs, rhs)
    }
    
    public static func *> <U>(lhs: Parser<U>, rhs: Parser<T>) -> Parser<T> {
        return discardLeft(lhs, rhs)
    }
    
    public static func <* <U>(lhs: Parser<T>, rhs: Parser<U>) -> Parser<T> {
        return discardRight(lhs, rhs)
    }
}
