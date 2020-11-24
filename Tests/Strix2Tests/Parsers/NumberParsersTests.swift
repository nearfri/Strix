import XCTest
@testable import Strix2

final class NumberParsersTests: XCTestCase {
    func literal(options: NumberParseOptions) -> Parser<NumberLiteral> {
        return .numberLiteral(options: options)
    }
    
    func test_numberLiteral_sign() {
        let options: NumberParseOptions = [.allowSign]
        let p = literal(options: options)
        
        XCTAssertEqual(try p.run("1").sign, .none)
        XCTAssertEqual(try p.run("+1").sign, .plus)
        XCTAssertEqual(try p.run("-1").sign, .minus)
    }
    
    func test_numberLiteral_nan() {
        let options: NumberParseOptions = [.allowSign, .allowNaN, .allowInfinity]
        let p = literal(options: options)
        
        XCTAssertEqual(try p.run("nan").classification, .nan)
        XCTAssertEqual(try p.run("+nan").classification, .nan)
        XCTAssertEqual(try p.run("-nan").classification, .nan)
    }
    
    func test_numberLiteral_infinity() {
        let options: NumberParseOptions = [.allowNaN, .allowInfinity]
        let p = literal(options: options)
        
        XCTAssertEqual(try p.run("inf").classification, .infinity)
        XCTAssertEqual(try p.run("infinity").classification, .infinity)
        XCTAssertEqual(try p.run("infinity").string, "infinity")
    }

    func test_numberLiteral_finite() {
        let options: NumberParseOptions = [.allowNaN, .allowInfinity]
        let p = literal(options: options)
        
        XCTAssertEqual(try p.run("7").classification, .finite)
    }
    
    func test_numberLiteral_notation() {
        let options: NumberParseOptions = [.allowAllNotations]
        let p = literal(options: options)
        
        XCTAssertEqual(try p.run("1").notation, .decimal)
        XCTAssertEqual(try p.run("0x1").notation, .hexadecimal)
        XCTAssertEqual(try p.run("0X1").notation, .hexadecimal)
        XCTAssertEqual(try p.run("0o1").notation, .octal)
        XCTAssertEqual(try p.run("0O1").notation, .octal)
        XCTAssertEqual(try p.run("0b1").notation, .binary)
        XCTAssertEqual(try p.run("0B1").notation, .binary)
    }
    
    func test_numberLiteral_integerPart() {
        XCTAssertEqual(try literal(options: []).run("123.4").integerPart, "123")
        XCTAssertEqual(try literal(options: []).run("0x123.4").integerPart, "0")
        XCTAssertEqual(try literal(options: []).run("0o123.4").integerPart, "0")
        XCTAssertEqual(try literal(options: []).run("0b123.4").integerPart, "0")
        
        XCTAssertEqual(try literal(options: [.allowHexadecimal]).run("0x12F.4").integerPart, "12F")
        XCTAssertEqual(try literal(options: [.allowOctal]).run("0o12F.4").integerPart, "12")
        XCTAssertEqual(try literal(options: [.allowBinary]).run("0b12F.4").integerPart, "1")
    }
    
    func test_numberLiteral_fractionalPart() {
        let options: NumberParseOptions = [.allowFraction]
        let p = literal(options: options)
        
        XCTAssertEqual(try p.run("12.34").fractionalPart, "34")
        XCTAssertEqual(try p.run("12.34z").fractionalPart, "34")
        XCTAssertEqual(try p.run(".34").fractionalPart, "34")
        XCTAssertEqual(try p.run("34").fractionalPart, nil)
        XCTAssertEqual(try p.run("12.").fractionalPart, nil)
        XCTAssertEqual(try p.run("12.").string, "12.")
    }
    
    func test_numberLiteral_exponentPart() {
        let options: NumberParseOptions = [.allowHexadecimal, .allowExponent]
        let p = literal(options: options)
        
        XCTAssertEqual(try p.run("12e10").exponentPart, "10")
        XCTAssertEqual(try p.run("12e+10").exponentPart, "+10")
        XCTAssertEqual(try p.run("12e-10").exponentPart, "-10")
        
        XCTAssertEqual(try p.run("0x12p10").exponentPart, "10")
        XCTAssertEqual(try p.run("0x12p+10").exponentPart, "+10")
        XCTAssertEqual(try p.run("0x12p-10").exponentPart, "-10")
    }
    
    func test_numberLiteral_underscore() {
        XCTAssertEqual(try literal(options: []).run("1_2_3").integerPart, "1")
        XCTAssertEqual(try literal(options: [.allowUnderscore]).run("1_2_3").integerPart, "123")
    }
    
    func test_numberLiteral_composition() throws {
        let options: NumberParseOptions = [
            .allowSign, .allowAllNotations, .allowFraction, .allowExponent, .allowUnderscore
        ]
        let p = literal(options: options)
        
        let expectedLiteral = NumberLiteral(
            string: "-0x12_32.c_6p4_5", sign: .minus, classification: .finite,
            notation: .hexadecimal, integerPart: "1232", fractionalPart: "c6", exponentPart: "45"
        )
        let actualLiteral = try p.run("-0x12_32.c_6p4_5abc")
        
        XCTAssertEqual(actualLiteral, expectedLiteral)
    }
    
    func test_int() {
        let p = Parser.int()
        XCTAssertEqual(try p.run("12345"), 12345)
        XCTAssertEqual(try p.run("+12345"), 12345)
        XCTAssertEqual(try p.run("-12345"), -12345)
    }
    
    func test_int_allowUnderscore() {
        let p = Parser.int(allowUnderscore: true)
        XCTAssertEqual(try p.run("12_345"), 12345)
        XCTAssertEqual(try p.run("+12_345"), 12345)
        XCTAssertEqual(try p.run("-12_345"), -12345)
    }
    
    func test_uint() {
        let p = Parser.uint()
        XCTAssertEqual(try p.run("12345"), 12345)
        XCTAssertEqual(try p.run("+12345"), 12345)
        XCTAssertThrowsError(try p.run("-12345"))
    }
    
    func test_double() {
        let p = Parser.double()
        XCTAssertEqual(try p.run("123456"), 123456)
        XCTAssertEqual(try p.run("123.456"), 123.456)
        XCTAssertEqual(try p.run("-123.456e5"), -12345600)
    }
}
