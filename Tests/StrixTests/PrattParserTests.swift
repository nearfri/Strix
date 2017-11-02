
import XCTest
@testable import Strix

class PrattParserTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func test_token_equatable() {
        XCTAssertEqual(Token(type: .number, value: "1"), Token(type: .number, value: "1"))
        XCTAssertEqual(Token(type: .number, value: "2"), Token(type: .number, value: "2"))
        XCTAssertEqual(Token(type: .string, value: "1"), Token(type: .string, value: "1"))
        
        XCTAssertNotEqual(Token(type: .number, value: "1"), Token(type: .number, value: "2"))
        XCTAssertNotEqual(Token(type: .number, value: "1"), Token(type: .string, value: "1"))
    }
    
    func test_token_hashable() {
        XCTAssertEqual(Token(type: .number, value: "1").hashValue,
                       Token(type: .number, value: "1").hashValue)
        XCTAssertEqual(Token(type: .number, value: "2").hashValue,
                       Token(type: .number, value: "2").hashValue)
        XCTAssertEqual(Token(type: .string, value: "1").hashValue,
                       Token(type: .string, value: "1").hashValue)
        
        XCTAssertNotEqual(Token(type: .number, value: "1").hashValue,
                          Token(type: .number, value: "2").hashValue)
        XCTAssertNotEqual(Token(type: .number, value: "1").hashValue,
                          Token(type: .string, value: "1").hashValue)
    }
    
    func test_prattParser_parseTokens() {
        let p = calculatorPrattParser()
        let tokens: [Token] = [
            Token(type: .number, value: "1"),
            Token(type: .operator, value: "+"),
            Token(type: .number, value: "2")
        ]
        checkSuccess(p.parse(tokens: tokens), 3.0)
    }
    
    func test_prattParser_calculator() {
        let p = calculator()
        
        checkSuccess(p.run("123"), 123.0)
        checkSuccess(p.run("-123"), -123.0)
        checkSuccess(p.run("3 + 4 * 2"), 3 + 4 * 2)
        checkSuccess(p.run("1 + 10 % 3"), Double(1 + 10 % 3))
        checkSuccess(p.run("3 + 4 ^ 6 * 8 + 2"), 3 + pow(4, 6) * 8 + 2)
        checkSuccess(p.run("9 * -(4 - 2)"), 9 * -(4 - 2))
        checkSuccess(p.run("+2*pow(+3 * (+2 + -4) ^ +4, 3) / -2"),
                     2 * pow(3 * pow(2-4, 4), 3) / -2)
    }
    
    func test_prattParser_whenUnknownNullDenotation_returnFailure() {
        let p = calculator()
        checkFailure(p.run("*123"))
    }
    
    func test_prattParser_whenUnknownLeftDenotation_returnFailure() {
        let p = calculator()
        checkFailure(p.run("3 ! 4"))
    }
    
    func test_prattParser_whenTokenizerFailure_returnFailure() {
        let p = calculator()
        checkFailure(p.parse(CharacterStream(string: "12.0e")))
    }
    
    func test_prattParser_whenTokenizerFatalFailure_returnFatalFailure() {
        let p = calculator()
        checkFatalFailure(p.parse(CharacterStream(string: "#")))
    }
    
    func test_prattParser_whenExpressionThrowError_returnFatalFailure() {
        let p = calculator()
        checkFatalFailure(p.parse(CharacterStream(string: "1 : 2")))
    }
}

func calculator() -> Parser<Double> {
    let tokenizer = calculatorTokenizer()
    let prattParser = calculatorPrattParser()
    
    return Parser { (stream) in
        return prattParser.parse(stream, with: tokenizer)
    }
}

private func calculatorTokenizer() -> Parser<Token> {
    let ws = skipWhitespaces()
    
    let end = endOfStream() >>| { Token(type: .end) }
    
    let numberOptions: NumberComponents.ParseOptions = [
        .allowFraction, .allowExponent
    ]
    let number = numberComponents(options: numberOptions)
        !>> ws >>| { Token(type: .number, value: $0.string!) }
    
    let singleOperator = any(of: "^*/%+-(),")
        >>| { Token(type: .operator, value: String($0)) }
    
    let name: Parser<Token> = {
        let firstIdentifierChar = { (c: Character) -> Bool in
            return isASCIILetter(c) || c == "_"
        }
        let identifierChar = { (c: Character) -> Bool in
            return isASCIILetter(c) || isDecimalDigit(c) || c == "_"
        }
        return manyCharacters(minCount: 1, first: firstIdentifierChar, while: identifierChar)
            >>| { Token(type: .name, value: String($0)) }
    }()
    
    let operatorForTest = any(of: "!:") >>| { Token(type: .operator, value: String($0)) }
    let errorForTest: Parser<Token> = failFatally("invalid character")
    
    return ws >>! choice([number, name, singleOperator, end, operatorForTest, errorForTest])
}

private func calculatorPrattParser() -> PrattParser<Double> {
    let prattParser: PrattParser<Double> = PrattParser()
    addNormalOperators(to: prattParser)
    addFunctionOperators(to: prattParser)
    addTestOperator(to: prattParser)
    return prattParser
}

private func addTestOperator(to prattParser: PrattParser<Double>) {
    let token = Token(type: .operator, value: ":")
    prattParser.addDenotation(for: token, bindingPower: 120) { (left, tok, parser) -> Double in
        throw DummyError.err0
    }
}

private func addNormalOperators(to prattParser: PrattParser<Double>) {
    func addOperator(_ value: String, exp: @escaping NullDenotation<Double>.Expression) {
        let token = Token(type: .operator, value: value)
        prattParser.addDenotation(for: token, expression: exp)
    }
    
    func addOperator(_ value: String, bp: Int, exp: @escaping LeftDenotation<Double>.Expression) {
        let token = Token(type: .operator, value: value)
        prattParser.addDenotation(for: token, bindingPower: bp, expression: exp)
    }
    
    prattParser.addDenotation(for: .end, bindingPower: 0) { (left, _, _) -> Double in
        return left
    }
    prattParser.addDenotation(for: .number) { (token, parser) -> Double in
        guard let number = Double(token.value) else {
            throw ParseError.Generic(message: "\(token.value) is outside the allowable range")
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
            throw ParseError.ExpectedString(")", case: .sensitive)
        }
        try parser.advance()
        return expr
    }
}

private func addFunctionOperators(to prattParser: PrattParser<Double>) {
    func addOperator(_ value: String, bp: Int, exp: @escaping LeftDenotation<Double>.Expression) {
        let token = Token(type: .operator, value: value)
        prattParser.addDenotation(for: token, bindingPower: bp, expression: exp)
    }
    
    addOperator(",", bp: 0) { (left, token, parser) -> Double in
        return left
    }
    
    func addFunction(_ value: String, compute: @escaping ([Double]) throws -> Double) {
        let token = Token(type: .name, value: value)
        prattParser.addDenotation(for: token) { (token, parser) -> Double in
            guard parser.nextToken.value == "(" else {
                throw ParseError.ExpectedString("(", case: .sensitive)
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
                throw ParseError.ExpectedString(")", case: .sensitive)
            }
            try parser.advance()
            
            return expr
        }
    }
    
    func addFunction1(_ value: String, compute: @escaping (Double) throws -> Double) {
        addFunction(value) { (params) -> Double in
            guard params.count == 1 else {
                throw ParseError.Generic(message: "\"\(value)\" function take exactly one argument")
            }
            return try compute(params[0])
        }
    }
    
    func addFunction2(_ value: String, compute: @escaping (Double, Double) throws -> Double) {
        addFunction(value) { (params) -> Double in
            guard params.count == 2 else {
                throw ParseError.Generic(message: "\"\(value)\" function take exactly two argument")
            }
            return try compute(params[0], params[1])
        }
    }
    
    addFunction1("sin", compute: sin)
    addFunction1("cos", compute: cos)
    addFunction1("tan", compute: tan)
    addFunction1("exp", compute: exp)
    addFunction1("log", compute: log)
    addFunction1("sqrt", compute: sqrt)
    addFunction2("pow", compute: pow)
}



