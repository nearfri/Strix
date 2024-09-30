import Testing
import Foundation
@testable import Strix

@Suite struct NumberLiteralTests {
    @Test func integerPartValue() {
        var literal = NumberLiteral(
            string: "", sign: .plus, classification: .finite, notation: .decimal,
            integerPart: "100", fractionalPart: "", exponentPart: "")
        
        literal.notation = .decimal
        #expect(literal.integerPartValue == 100)
        
        literal.notation = .hexadecimal
        #expect(literal.integerPartValue == 0x100)
        
        literal.notation = .octal
        #expect(literal.integerPartValue == 0o100)
        
        literal.notation = .binary
        #expect(literal.integerPartValue == 0b100)
    }
    
    @Test func fractionalPartValue() {
        var literal = NumberLiteral(
            string: "", sign: .plus, classification: .finite, notation: .decimal,
            integerPart: "", fractionalPart: "001", exponentPart: "")
        
        literal.notation = .decimal
        #expect(literal.fractionalPartValue == 0.001)
        #expect(literal.fractionalPartValue == 1.0 / pow(10, 3))
        
        literal.notation = .hexadecimal
        #expect(literal.fractionalPartValue == 1.0 / pow(16, 3))
        
        literal.notation = .octal
        #expect(literal.fractionalPartValue == 1.0 / pow(8, 3))
        
        literal.notation = .binary
        #expect(literal.fractionalPartValue == 1.0 / pow(2, 3))
    }
    
    @Test func exponentPartValue() {
        var literal = NumberLiteral(
            string: "", sign: .plus, classification: .finite, notation: .decimal,
            integerPart: "", fractionalPart: "", exponentPart: "3")
        
        literal.notation = .decimal
        #expect(literal.exponentPartValue == 1000)
        
        literal.notation = .hexadecimal
        #expect(literal.exponentPartValue == 8)
        
        literal.exponentPart = "-3"
        literal.notation = .decimal
        #expect(literal.exponentPartValue == 1.0 / 1000)
        
        literal.notation = .hexadecimal
        #expect(literal.exponentPartValue == 1.0 / 8)
    }
    
    @Test func toValue_int() {
        var literal = NumberLiteral(
            string: "", sign: .none, classification: .finite, notation: .decimal,
            integerPart: "123", fractionalPart: "", exponentPart: "")
        
        #expect(literal.toValue(type: Int.self) == 123)
        
        literal.sign = .plus
        #expect(literal.toValue(type: Int.self) == 123)
        
        literal.sign = .minus
        #expect(literal.toValue(type: Int.self) == -123)
    }
    
    @Test func toValue_int_withExponent() {
        var literal = NumberLiteral(
            string: "", sign: .none, classification: .finite, notation: .decimal,
            integerPart: "123", fractionalPart: "", exponentPart: "3")
        
        #expect(literal.toValue(type: Int.self) == 123000)
        
        literal.sign = .plus
        #expect(literal.toValue(type: Int.self) == 123000)
        
        literal.sign = .minus
        #expect(literal.toValue(type: Int.self) == -123000)
        
        literal.exponentPart = "-3"
        #expect(literal.toValue(type: Int.self) == nil)
    }
    
    @Test func toValue_intOverflow() {
        var literal = NumberLiteral(
            string: "", sign: .plus, classification: .finite, notation: .decimal,
            integerPart: "255", fractionalPart: "", exponentPart: "")
        
        #expect(literal.toValue(type: UInt8.self) == 255)
        
        literal.integerPart = "256"
        #expect(literal.toValue(type: UInt8.self) == nil)
    }
    
    @Test func toValue_double() {
        var literal = NumberLiteral(
            string: "", sign: .none, classification: .finite, notation: .decimal,
            integerPart: "123", fractionalPart: "456", exponentPart: "")
        
        #expect(literal.toValue(type: Double.self) == 123.456)
        
        literal.sign = .plus
        #expect(literal.toValue(type: Double.self) == 123.456)
        
        literal.sign = .minus
        #expect(literal.toValue(type: Double.self) == -123.456)
    }
    
    @Test func toValue_double_withExponent() {
        var literal = NumberLiteral(
            string: "", sign: .none, classification: .finite, notation: .decimal,
            integerPart: "123", fractionalPart: "456", exponentPart: "3")
        
        #expect(literal.toValue(type: Double.self) == 123456)
        
        literal.sign = .plus
        #expect(literal.toValue(type: Double.self) == 123456)
        
        literal.sign = .minus
        #expect(literal.toValue(type: Double.self) == -123456)
        
        literal.exponentPart = "-3"
        #expect(literal.toValue(type: Double.self)! - -0.123456 < 0.000_001)
    }
    
    @Test func toNumber() {
        let literal = NumberLiteral(
            string: "", sign: .none, classification: .finite, notation: .decimal,
            integerPart: "123", fractionalPart: "456", exponentPart: "2")
        
        #expect(literal.toNumber() == 12345.6 as NSNumber)
    }
}
