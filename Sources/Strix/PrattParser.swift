
public enum TokenType: Int {
    case end
    case number
    case string
    case `operator`
    case name
    case comment
}

public struct Token: Hashable {
    public var type: TokenType
    public var value: String
    
    public init(type: TokenType, value: String = "") {
        self.type = type
        self.value = value
    }
}

public protocol TokenHandling {
    
}

public struct NullDenotation<T>: TokenHandling {
    public typealias Expression = (_ token: Token, _ parser: PrattParser<T>) throws -> T
    
    public let expression: Expression
    
    public init(expression: @escaping Expression) {
        self.expression = expression
    }
}

public struct LeftDenotation<T>: TokenHandling {
    public typealias Expression =
        (_ leftValue: T, _ token: Token, _ parser: PrattParser<T>) throws -> T
    
    public let bindingPower: Int
    public let expression: Expression
    
    public init(bindingPower: Int, expression: @escaping Expression) {
        self.bindingPower = bindingPower
        self.expression = expression
    }
}

private class DenotationGroup<Denotation: TokenHandling> {
    var denotations: [String: Denotation] = [:]
    var commonDenotation: Denotation?
    
    subscript(token: Token) -> Denotation? {
        return denotations[token.value] ?? commonDenotation
    }
}

public final class PrattParser<T> {
    private var nullDenotationGroups: [TokenType: DenotationGroup<NullDenotation<T>>] = [:]
    private var leftDenotationGroups: [TokenType: DenotationGroup<LeftDenotation<T>>] = [:]
    
    public private(set) var nextToken: Token = Token(type: .end)
    public private(set) var advance: () throws -> Void = {}
    
    public init() {}
    
    public func parse<S: Sequence>(tokens: S) -> Reply<T> where S.Element == Token {
        let tokens = AnyIterator(tokens.makeIterator())
        advance = {
            if let token = tokens.next() {
                self.nextToken = token
            } else if self.nextToken.type != .end {
                self.nextToken = Token(type: .end)
            }
        }
        
        return parse()
    }
    
    public func parse(_ stream: CharacterStream, with tokenizer: Parser<Token>) -> Reply<T> {
        advance = {
            switch tokenizer.parse(stream) {
            case let .success(token, _):
                self.nextToken = token
            case let .failure(e):
                throw Error.tokenizerFailure(e)
            }
        }
        
        return parse()
    }
    
    private func parse() -> Reply<T> {
        defer {
            nextToken = Token(type: .end)
            advance = {}
        }
        
        do {
            try advance()
            let ret = try expression(withRightBindingPower: 0)
            return .success(ret, [])
        } catch Error.tokenizerFailure(let e) {
            return .failure(e)
        } catch Error.denotationNotFound(let e) {
            return .failure([e])
        } catch {
            return .failure([error])
        }
    }
    
    public func expression(withRightBindingPower rightBindingPower: Int) throws -> T {
        let token = nextToken
        let nud = try nullDenotation(for: token)
        try advance()
        var leftValue = try nud.expression(token, self)
        while true {
            let token = nextToken
            let led = try leftDenotation(for: token)
            guard rightBindingPower < led.bindingPower else {
                break
            }
            try advance()
            leftValue = try led.expression(leftValue, token, self)
        }
        return leftValue
    }
}

extension PrattParser {
    public func add(denotation: NullDenotation<T>, for token: Token) {
        let group = denotationGroup(for: token.type, in: &nullDenotationGroups)
        group.denotations[token.value] = denotation
    }
    
    public func add(denotation: NullDenotation<T>, for tokenType: TokenType) {
        let group = denotationGroup(for: tokenType, in: &nullDenotationGroups)
        group.commonDenotation = denotation
    }
    
    public func addDenotation(
        for token: Token, expression: @escaping NullDenotation<T>.Expression) {
        
        add(denotation: NullDenotation<T>(expression: expression), for: token)
    }
    
    public func addDenotation(
        for tokenType: TokenType, expression: @escaping NullDenotation<T>.Expression) {
        
        add(denotation: NullDenotation<T>(expression: expression), for: tokenType)
    }
    
    public func add(denotation: LeftDenotation<T>, for token: Token) {
        let group = denotationGroup(for: token.type, in: &leftDenotationGroups)
        group.denotations[token.value] = denotation
    }
    
    public func add(denotation: LeftDenotation<T>, for tokenType: TokenType) {
        let group = denotationGroup(for: tokenType, in: &leftDenotationGroups)
        group.commonDenotation = denotation
    }
    
    public func addDenotation(
        for token: Token, bindingPower: Int,
        expression: @escaping LeftDenotation<T>.Expression) {
        
        let denotation = LeftDenotation<T>(bindingPower: bindingPower, expression: expression)
        add(denotation: denotation, for: token)
    }
    
    public func addDenotation(
        for tokenType: TokenType, bindingPower: Int,
        expression: @escaping LeftDenotation<T>.Expression) {
        
        let denotation = LeftDenotation<T>(bindingPower: bindingPower, expression: expression)
        add(denotation: denotation, for: tokenType)
    }
}

extension PrattParser {
    private func nullDenotation(for token: Token) throws -> NullDenotation<T> {
        guard let result: NullDenotation = denotation(for: token, in: nullDenotationGroups) else {
            let message = "could not find the null denotation for \(token)"
            throw Error.denotationNotFound(ParseError.Generic(message: message))
        }
        return result
    }
    
    private func leftDenotation(for token: Token) throws -> LeftDenotation<T> {
        guard let result: LeftDenotation = denotation(for: token, in: leftDenotationGroups) else {
            let message = "could not find the left denotation for \(token)"
            throw Error.denotationNotFound(ParseError.Generic(message: message))
        }
        return result
    }
    
    private func denotation<Denotation>(
        for token: Token,
        in groups: [TokenType: DenotationGroup<Denotation>]) -> Denotation? {
        
        return groups[token.type]?[token]
    }
    
    private func denotationGroup<Denotation>(
        for type: TokenType,
        in groups: inout [TokenType: DenotationGroup<Denotation>]) -> DenotationGroup<Denotation> {
        
        let result: DenotationGroup<Denotation>
        if let group = groups[type] {
            result = group
        } else {
            result = DenotationGroup<Denotation>()
            groups[type] = result
        }
        return result
    }
}

extension PrattParser {
    private enum Error: Swift.Error {
        case tokenizerFailure([Swift.Error])
        case denotationNotFound(Swift.Error)
    }
}



