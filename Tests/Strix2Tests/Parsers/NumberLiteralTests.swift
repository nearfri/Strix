import XCTest
@testable import Strix2

final class NumberLiteralTests: XCTestCase {
    func test_integerPartValue() {
        var literal = NumberLiteral(
            string: "", sign: .plus, classification: .finite, notation: .decimal,
            integerPart: "100", fractionalPart: nil, exponentPart: nil)
        
        literal.notation = .decimal
        XCTAssertEqual(literal.integerPartValue, 100)
        
        literal.notation = .hexadecimal
        XCTAssertEqual(literal.integerPartValue, 0x100)
        
        literal.notation = .octal
        XCTAssertEqual(literal.integerPartValue, 0o100)
        
        literal.notation = .binary
        XCTAssertEqual(literal.integerPartValue, 0b100)
    }
    
    func test_fractionalPartValue() {
        var literal = NumberLiteral(
            string: "", sign: .plus, classification: .finite, notation: .decimal,
            integerPart: nil, fractionalPart: "001", exponentPart: nil)
        
        literal.notation = .decimal
        XCTAssertEqual(literal.fractionalPartValue, 0.001)
        XCTAssertEqual(literal.fractionalPartValue, 1.0 / pow(10, 3))
        
        literal.notation = .hexadecimal
        XCTAssertEqual(literal.fractionalPartValue, 1.0 / pow(16, 3))
        
        literal.notation = .octal
        XCTAssertEqual(literal.fractionalPartValue, 1.0 / pow(8, 3))
        
        literal.notation = .binary
        XCTAssertEqual(literal.fractionalPartValue, 1.0 / pow(2, 3))
    }
    
    func test_exponentPartValue() {
        var literal = NumberLiteral(
            string: "", sign: .plus, classification: .finite, notation: .decimal,
            integerPart: nil, fractionalPart: nil, exponentPart: "3")
        
        literal.notation = .decimal
        XCTAssertEqual(literal.exponentPartValue, 1000)
        
        literal.notation = .hexadecimal
        XCTAssertEqual(literal.exponentPartValue, 8)
        
        literal.exponentPart = "-3"
        literal.notation = .decimal
        XCTAssertEqual(literal.exponentPartValue, 1.0 / 1000)
        
        literal.notation = .hexadecimal
        XCTAssertEqual(literal.exponentPartValue, 1.0 / 8)
    }
    
    func test_toValue_int() {
        var literal = NumberLiteral(
            string: "", sign: .none, classification: .finite, notation: .decimal,
            integerPart: "123", fractionalPart: nil, exponentPart: nil)
        
        XCTAssertEqual(literal.toValue(type: Int.self), 123)
        
        literal.sign = .plus
        XCTAssertEqual(literal.toValue(type: Int.self), 123)
        
        literal.sign = .minus
        XCTAssertEqual(literal.toValue(type: Int.self), -123)
    }
    
    func test_toValue_int_withExponent() {
        var literal = NumberLiteral(
            string: "", sign: .none, classification: .finite, notation: .decimal,
            integerPart: "123", fractionalPart: nil, exponentPart: "3")
        
        XCTAssertEqual(literal.toValue(type: Int.self), 123000)
        
        literal.sign = .plus
        XCTAssertEqual(literal.toValue(type: Int.self), 123000)
        
        literal.sign = .minus
        XCTAssertEqual(literal.toValue(type: Int.self), -123000)
        
        literal.exponentPart = "-3"
        XCTAssertNil(literal.toValue(type: Int.self))
    }
    
    func test_toValue_intOverflow() {
        var literal = NumberLiteral(
            string: "", sign: .plus, classification: .finite, notation: .decimal,
            integerPart: "255", fractionalPart: nil, exponentPart: nil)
        
        XCTAssertEqual(literal.toValue(type: UInt8.self), 255)
        
        literal.integerPart = "256"
        XCTAssertNil(literal.toValue(type: UInt8.self))
    }
    
    func test_toValue_double() {
        var literal = NumberLiteral(
            string: "", sign: .none, classification: .finite, notation: .decimal,
            integerPart: "123", fractionalPart: "456", exponentPart: nil)
        
        XCTAssertEqual(literal.toValue(type: Double.self), 123.456)
        
        literal.sign = .plus
        XCTAssertEqual(literal.toValue(type: Double.self), 123.456)
        
        literal.sign = .minus
        XCTAssertEqual(literal.toValue(type: Double.self), -123.456)
    }
    
    func test_toValue_double_withExponent() {
        var literal = NumberLiteral(
            string: "", sign: .none, classification: .finite, notation: .decimal,
            integerPart: "123", fractionalPart: "456", exponentPart: "3")
        
        XCTAssertEqual(literal.toValue(type: Double.self), 123456)
        
        literal.sign = .plus
        XCTAssertEqual(literal.toValue(type: Double.self), 123456)
        
        literal.sign = .minus
        XCTAssertEqual(literal.toValue(type: Double.self), -123456)
        
        literal.exponentPart = "-3"
        XCTAssertEqual(literal.toValue(type: Double.self)!, -0.123456, accuracy: 0.0000000001)
    }
    
    func test_toNumber() {
        let literal = NumberLiteral(
            string: "", sign: .none, classification: .finite, notation: .decimal,
            integerPart: "123", fractionalPart: "456", exponentPart: "2")
        
        XCTAssertEqual(literal.toNumber(), 12345.6 as NSNumber)
    }
}

