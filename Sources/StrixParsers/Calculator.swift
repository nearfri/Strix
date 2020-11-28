import Foundation
import Strix2

public struct Calculator {
    private let prattParser: PrattParser<Double>
    private let tokenizer: Parser<Token>
    
    public init() {
        prattParser = PrattParserGenerator().prattParser
        tokenizer = TokenizerGenerator().tokenizer
    }
    
    public func calculate(_ expression: String) throws -> Double {
        return try prattParser.parse(expression, with: tokenizer)
    }
    
    public func callAsFunction(_ expression: String) throws -> Double {
        return try calculate(expression)
    }
}

private struct TokenizerGenerator {
    var tokenizer: Parser<Token> {
        return ws *> .any(of: [number, name, singleOperator, end])
    }
    
    private var ws: Parser<[Character]> {
        return .many(.whitespace)
    }
    
    private var number: Parser<Token> {
        let numberOptions: NumberParseOptions = [.allowFraction, .allowExponent]
        let numberLiteral = Parser.numberLiteral(options: numberOptions)
        return numberLiteral.map({ Token(type: .number, value: $0.string) })
    }
    
    private var name: Parser<Token> {
        let first = Parser.asciiLetter <|> .character("_")
        let repeating = Parser.asciiLetter <|> .decimalDigit <|> .character("_")
        let identifier = Parser.many(first: first, repeating: repeating, minCount: 1)
        return identifier.map({ Token(type: .name, value: String($0)) })
    }
    
    private var singleOperator: Parser<Token> {
        return Parser.any(of: "^*/%+-(),").map({ Token(type: .operator, value: String($0)) })
    }
    
    private var end: Parser<Token> {
        return Parser.endOfStream.map({ Token(type: .end) })
    }
}

private struct PrattParserGenerator {
    let prattParser: PrattParser<Double>
    
    init() {
        prattParser = PrattParser()
        addNormalOperators()
        addFunctionOperators()
    }
    
    private func addNormalOperators() {
        prattParser.addDenotation(for: .end, bindingPower: 0) { (left, _, _) -> Double in
            return left
        }
        
        prattParser.addDenotation(for: .number) { (token, parser) -> Double in
            guard let number = Double(token.value) else {
                throw ParseError.generic(message: "\(token.value) is outside the allowable range")
            }
            return number
        }
        
        addOperator("^", bp: 140) { (left, token, parser) -> Double in
            let right = try parser.expression(withRightBindingPower: 139)
            return pow(left, right)
        }
        addOperator("+") { (token, parser) -> Double in
            return try parser.expression(withRightBindingPower: 130)
        }
        addOperator("-") { (token, parser) -> Double in
            return try -parser.expression(withRightBindingPower: 130)
        }
        addOperator("*", bp: 120) { (left, token, parser) -> Double in
            return try left * parser.expression(withRightBindingPower: 120)
        }
        addOperator("/", bp: 120) { (left, token, parser) -> Double in
            return try left / parser.expression(withRightBindingPower: 120)
        }
        addOperator("%", bp: 120) { (left, token, parser) -> Double in
            let right = try parser.expression(withRightBindingPower: 120)
            return left.truncatingRemainder(dividingBy: right)
        }
        addOperator("+", bp: 110) { (left, token, parser) -> Double in
            return try left + parser.expression(withRightBindingPower: 110)
        }
        addOperator("-", bp: 110) { (left, token, parser) -> Double in
            return try left - parser.expression(withRightBindingPower: 110)
        }
        addOperator(")", bp: 0) { (left, token, parser) -> Double in
            return left
        }
        addOperator("(") { (token, parser) -> Double in
            let expr = try parser.expression(withRightBindingPower: 0)
            guard parser.nextToken.value == ")" else {
                throw ParseError.expectedString(string: ")", caseSensitive: true)
            }
            try parser.advance()
            return expr
        }
    }
    
    private func addFunctionOperators() {
        addOperator(",", bp: 0) { (left, token, parser) -> Double in
            return left
        }
        
        addFunction1("sin", compute: sin)
        addFunction1("cos", compute: cos)
        addFunction1("tan", compute: tan)
        addFunction1("exp", compute: exp)
        addFunction1("log", compute: log)
        addFunction1("sqrt", compute: sqrt)
        addFunction2("pow", compute: pow)
    }
    
    private func addOperator(_ value: String, exp: @escaping NullDenotation<Double>.Expression) {
        let token = Token(type: .operator, value: value)
        prattParser.addDenotation(for: token, expression: exp)
    }
    
    private func addOperator(_ value: String,
                             bp: Int,
                             exp: @escaping LeftDenotation<Double>.Expression
    ) {
        let token = Token(type: .operator, value: value)
        prattParser.addDenotation(for: token, bindingPower: bp, expression: exp)
    }
    
    private func addFunction1(_ value: String, compute: @escaping (Double) throws -> Double) {
        addFunction(value) { (params) -> Double in
            guard params.count == 1 else {
                throw ParseError.generic(message: "\"\(value)\" function take exactly one argument")
            }
            return try compute(params[0])
        }
    }
    
    private func addFunction2(_ value: String,
                              compute: @escaping (Double, Double) throws -> Double
    ) {
        addFunction(value) { (params) -> Double in
            guard params.count == 2 else {
                throw ParseError.generic(message: "\"\(value)\" function take exactly two argument")
            }
            return try compute(params[0], params[1])
        }
    }
    
    private func addFunction(_ value: String, compute: @escaping ([Double]) throws -> Double) {
        let token = Token(type: .name, value: value)
        prattParser.addDenotation(for: token) { (token, parser) -> Double in
            guard parser.nextToken.value == "(" else {
                throw ParseError.expectedString(string: "(", caseSensitive: true)
            }
            try parser.advance()
            
            var params: [Double] = []
            if parser.nextToken.value != ")" {
                while true {
                    let param = try parser.expression(withRightBindingPower: 0)
                    params.append(param)
                    guard parser.nextToken.value == "," else {
                        break
                    }
                    try parser.advance()
                }
            }
            let expr = try compute(params)
            
            guard parser.nextToken.value == ")" else {
                throw ParseError.expectedString(string: ")", caseSensitive: true)
            }
            try parser.advance()
            
            return expr
        }
    }
}
