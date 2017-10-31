
import XCTest
@testable import Strix

class NumberComponentsTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func test_integerValue() {
        var components = NumberComponents()
        
        // decimal
        components.notation = .decimal
        components.integer = "123"
        XCTAssertEqual(components.integerValue, 123)
        
        components.integer = "123A"
        XCTAssertNil(components.integerValue)
        
        components.integer = ""
        XCTAssertNil(components.integerValue)
        
        components.integer = nil
        XCTAssertNil(components.integerValue)
        
        // hexadecimal
        components.notation = .hexadecimal
        components.integer = "123"
        XCTAssertEqual(components.integerValue, 0x123)
        
        components.integer = "123A"
        XCTAssertEqual(components.integerValue, 0x123A)
        
        components.integer = "123G"
        XCTAssertNil(components.integerValue)
        
        // octal
        components.notation = .octal
        components.integer = "123"
        XCTAssertEqual(components.integerValue, 0o123)
        
        components.integer = "1238"
        XCTAssertNil(components.integerValue)
        
        // binary
        components.notation = .binary
        components.integer = "101"
        XCTAssertEqual(components.integerValue, 0b101)
        
        components.integer = "12"
        XCTAssertNil(components.integerValue)
    }
    
    func test_fractionValue() {
        var components = NumberComponents()
        
        // decimal
        components.notation = .decimal
        components.fraction = "123"
        XCTAssertEqual(components.fractionValue, 0.123)
        
        components.fraction = "12300"
        XCTAssertEqual(components.fractionValue, 0.123)
        
        components.fraction = "00123"
        XCTAssertEqual(components.fractionValue, 0.00123)
        
        components.fraction = "123A"
        XCTAssertNil(components.fractionValue)
        
        components.fraction = ""
        XCTAssertNil(components.fractionValue)
        
        components.fraction = nil
        XCTAssertNil(components.fractionValue)
        
        // hexadecimal
        components.notation = .hexadecimal
        components.fraction = "123"
        XCTAssertEqual(components.fractionValue, 0x0.123p0) // 0.071044921875
        
        components.fraction = "12300"
        XCTAssertEqual(components.fractionValue, 0x0.123p0)
        
        components.fraction = "00123"
        XCTAssertEqual(components.fractionValue, 0x0.00123p0)
        
        components.fraction = "123A"
        XCTAssertEqual(components.fractionValue, 0x0.123Ap0) // 0.071197509765625
        
        components.fraction = "123G"
        XCTAssertNil(components.integerValue)
        
        // octal
        components.notation = .octal
        components.fraction = "123"
        let octal123 = (1.0 / 8) + (2.0 / (8*8)) + (3.0 / (8*8*8)) // 0.162109375
        XCTAssertEqual(components.fractionValue, octal123)
        
        components.fraction = "1238"
        XCTAssertNil(components.fractionValue)
        
        // binary
        components.notation = .binary
        components.fraction = "101"
        let binary101 = (1.0 / 2) + (0.0 / (2*2)) + (1.0 / (2*2*2)) // 0.625
        XCTAssertEqual(components.fractionValue, binary101)
        
        components.fraction = "12"
        XCTAssertNil(components.fractionValue)
    }
    
    func test_significandValue() {
        var components = NumberComponents()
        
        // decimal
        components.notation = .decimal
        components.integer = "123"
        components.fraction = "456"
        XCTAssertEqual(components.significandValue, 123.456)
        
        components.integer = "123"
        components.fraction = nil
        XCTAssertEqual(components.significandValue, 123.0)
        
        components.integer = nil
        components.fraction = "123"
        XCTAssertEqual(components.significandValue, 0.123)
        
        components.integer = nil
        components.fraction = nil
        XCTAssertNil(components.significandValue)
        
        // hexadecimal
        components.notation = .hexadecimal
        components.integer = "123"
        components.fraction = "456"
        XCTAssertEqual(components.significandValue, 0x123.456p0)
        
        // octal
        components.notation = .octal
        components.integer = "123"
        components.fraction = "456"
        let octal123456 = Double(0o123) + (4.0 / 8) + (5.0 / (8*8)) + (6.0 / (8*8*8))
        XCTAssertEqual(components.significandValue, octal123456)
        
        // binary
        components.notation = .binary
        components.integer = "101"
        components.fraction = "010"
        let binary101010 = Double(0b101) + (0.0 / 2) + (1.0 / (2*2)) + (0.0 / (2*2*2))
        XCTAssertEqual(components.significandValue, binary101010)
    }
    
    func test_exponentValue() {
        var components = NumberComponents()
        
        // decimal
        components.notation = .decimal
        components.exponent = "123"
        XCTAssertEqual(components.exponentValue, pow(10, 123))
        
        components.exponent = "+123"
        XCTAssertEqual(components.exponentValue, pow(10, 123))
        
        components.exponent = "-123"
        XCTAssertEqual(components.exponentValue, pow(10, -123))
        
        components.exponent = ""
        XCTAssertNil(components.exponentValue)
        
        components.exponent = nil
        XCTAssertNil(components.exponentValue)
        
        // hexadecimal
        components.notation = .hexadecimal
        components.exponent = "123"
        XCTAssertEqual(components.exponentValue, pow(2, 123))
        
        components.exponent = "+123"
        XCTAssertEqual(components.exponentValue, pow(2, 123))
        
        components.exponent = "-123"
        XCTAssertEqual(components.exponentValue, pow(2, -123))
        
        // octal
        components.notation = .octal
        components.exponent = "123"
        XCTAssertNil(components.exponentValue)
        
        // binary
        components.notation = .binary
        components.exponent = "123"
        XCTAssertNil(components.exponentValue)
    }
}




