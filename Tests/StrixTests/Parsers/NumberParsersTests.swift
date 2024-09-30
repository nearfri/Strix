import Testing
@testable import Strix

@Suite struct NumberParsersTests {
    private func literal(options: NumberParseOptions) -> Parser<NumberLiteral> {
        return .numberLiteral(options: options)
    }
    
    @Test func numberLiteral_sign() throws {
        let options: NumberParseOptions = [.allowSign]
        let p = literal(options: options)
        
        try #expect(p.run("1").sign == .none)
        try #expect(p.run("+1").sign == .plus)
        try #expect(p.run("-1").sign == .minus)
    }
    
    @Test func numberLiteral_nan() throws {
        let options: NumberParseOptions = [.allowSign, .allowNaN, .allowInfinity]
        let p = literal(options: options)
        
        try #expect(p.run("nan").classification == .nan)
        try #expect(p.run("+nan").classification == .nan)
        try #expect(p.run("-nan").classification == .nan)
    }
    
    @Test func numberLiteral_infinity() throws {
        let options: NumberParseOptions = [.allowNaN, .allowInfinity]
        let p = literal(options: options)
        
        try #expect(p.run("inf").classification == .infinity)
        try #expect(p.run("infinity").classification == .infinity)
        try #expect(p.run("infinity").string == "infinity")
    }

    @Test func numberLiteral_finite() throws {
        let options: NumberParseOptions = [.allowNaN, .allowInfinity]
        let p = literal(options: options)
        
        try #expect(p.run("7").classification == .finite)
    }
    
    @Test func numberLiteral_notation() throws {
        let options: NumberParseOptions = [.allowAllNotations]
        let p = literal(options: options)
        
        try #expect(p.run("1").notation == .decimal)
        try #expect(p.run("0x1").notation == .hexadecimal)
        try #expect(p.run("0X1").notation == .hexadecimal)
        try #expect(p.run("0o1").notation == .octal)
        try #expect(p.run("0O1").notation == .octal)
        try #expect(p.run("0b1").notation == .binary)
        try #expect(p.run("0B1").notation == .binary)
    }
    
    @Test func numberLiteral_integerPart() throws {
        try #expect(literal(options: []).run("123.4").integerPart == "123")
        try #expect(literal(options: []).run("0x123.4").integerPart == "0")
        try #expect(literal(options: []).run("0o123.4").integerPart == "0")
        try #expect(literal(options: []).run("0b123.4").integerPart == "0")
        
        try #expect(literal(options: [.allowHexadecimal]).run("0x12F.4").integerPart == "12F")
        try #expect(literal(options: [.allowOctal]).run("0o12F.4").integerPart == "12")
        try #expect(literal(options: [.allowBinary]).run("0b12F.4").integerPart == "1")
    }
    
    @Test func numberLiteral_fractionalPart() throws {
        let options: NumberParseOptions = [.allowFraction]
        let p = literal(options: options)
        
        try #expect(p.run("12.34").fractionalPart == "34")
        try #expect(p.run("12.34z").fractionalPart == "34")
        try #expect(p.run(".34").fractionalPart == "34")
        try #expect(p.run("34").fractionalPart == "")
        try #expect(p.run("12.").fractionalPart == "")
        try #expect(p.run("12.").string == "12.")
    }
    
    @Test func numberLiteral_exponentPart() throws {
        let options: NumberParseOptions = [.allowHexadecimal, .allowExponent]
        let p = literal(options: options)
        
        try #expect(p.run("12e10").exponentPart == "10")
        try #expect(p.run("12e+10").exponentPart == "+10")
        try #expect(p.run("12e-10").exponentPart == "-10")
        
        try #expect(p.run("0x12p10").exponentPart == "10")
        try #expect(p.run("0x12p+10").exponentPart == "+10")
        try #expect(p.run("0x12p-10").exponentPart == "-10")
    }
    
    @Test func numberLiteral_underscore() throws {
        try #expect(literal(options: []).run("1_2_3").integerPart == "1")
        try #expect(literal(options: [.allowUnderscore]).run("1_2_3").integerPart == "123")
    }
    
    @Test func numberLiteral_composition() throws {
        let options: NumberParseOptions = [
            .allowSign, .allowAllNotations, .allowFraction, .allowExponent, .allowUnderscore
        ]
        let p = literal(options: options)
        
        let expectedLiteral = NumberLiteral(
            string: "-0x12_32.c_6p4_5", sign: .minus, classification: .finite,
            notation: .hexadecimal, integerPart: "1232", fractionalPart: "c6", exponentPart: "45"
        )
        let actualLiteral = try p.run("-0x12_32.c_6p4_5abc")
        
        #expect(actualLiteral == expectedLiteral)
    }
    
    @Test func int() throws {
        let p = Parser.int()
        try #expect(p.run("12345") == 12345)
        try #expect(p.run("+12345") == 12345)
        try #expect(p.run("-12345") == -12345)
    }
    
    @Test func int_allowUnderscore() throws {
        let p = Parser.int(allowUnderscore: true)
        try #expect(p.run("12_345") == 12345)
        try #expect(p.run("+12_345") == 12345)
        try #expect(p.run("-12_345") == -12345)
    }
    
    @Test func uint() throws {
        let p = Parser.uint()
        try #expect(p.run("12345") == 12345)
        try #expect(p.run("+12345") == 12345)
        #expect(throws: RunError.self, performing: {
            try p.run("-12345")
        })
    }
    
    @Test func double() throws {
        let p = Parser.double()
        try #expect(p.run("123456") == 123456)
        try #expect(p.run("123.456") == 123.456)
        try #expect(p.run("-123.456e5") == -12345600)
    }
}
