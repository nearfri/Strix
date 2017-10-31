
import XCTest
@testable import Strix

class NumbersTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func test_numberComponents_success() {
        let allOptions: NumberComponents.ParseOptions = [
            .allowSign, .allowNaN, .allowInfinity, .allowAllNotations,
            .allowFraction, .allowExponent, .allowUnderscores
        ]
        let p = numberComponents(options: allOptions)
        
        var components = NumberComponents(
            string: "-0x12_32.c_6p4_5", sign: .minus, classification: .finite,
            notation: .hexadecimal, integer: "1232", fraction: "c6", exponent: "45")
        checkSuccess(p.run("-0x12_32.c_6p4_5abc"), components)
        
        components = NumberComponents(
            string: "nan", sign: .none, classification: .nan,
            notation: .decimal, integer: nil, fraction: nil, exponent: nil)
        checkSuccess(p.run("nan"), components)
        
        components = NumberComponents(
            string: "inf", sign: .none, classification: .infinity,
            notation: .decimal, integer: nil, fraction: nil, exponent: nil)
        checkSuccess(p.run("inf"), components)
        
        components = NumberComponents(
            string: "-infinity", sign: .minus, classification: .infinity,
            notation: .decimal, integer: nil, fraction: nil, exponent: nil)
        checkSuccess(p.run("-infinity"), components)
        
        components = NumberComponents(
            string: "inf", sign: .none, classification: .infinity,
            notation: .decimal, integer: nil, fraction: nil, exponent: nil)
        checkSuccess(p.run("information"), components)
    }
    
    func test_numberComponents_whenNotADigit_nextIndexIsAtStart() {
        let p = numberComponents(options: .defaultFloatingPoint)
        
        var stream = CharacterStream(string: "indoor")
        checkFailure(p.parse(stream))
        XCTAssertEqual(stream.nextIndex, stream.startIndex)
        
        stream = CharacterStream(string: "-minus")
        checkFailure(p.parse(stream))
        XCTAssertEqual(stream.nextIndex, stream.startIndex)
        
        stream = CharacterStream(string: "+plus")
        checkFailure(p.parse(stream))
        XCTAssertEqual(stream.nextIndex, stream.startIndex)
    }
    
    func test_numberComponents_whenInvalidExponent_nextIndexIsAfterExponentSymbol() {
        let p = numberComponents(options: .defaultFloatingPoint)
        
        let stream = CharacterStream(string: "12.3ea")
        checkFailure(p.parse(stream))
        XCTAssertEqual(stream.nextIndex, stream.string.index(of: "a"))
    }
    
    func test_floatingPoint_decimal() {
        let p = floatingPoint()
        
        checkSuccess(p.run("0"), 0.0)
        checkSuccess(p.run("-0"), 0.0)
        checkSuccess(p.run("+0"), 0.0)
        
        checkSuccess(p.run("123"), 123.0)
        checkSuccess(p.run("-123"), -123.0)
        checkSuccess(p.run("+123"), 123.0)
        
        checkSuccess(p.run("123.0"), 123.0)
        checkSuccess(p.run("-123.0"), -123.0)
        checkSuccess(p.run("+123.0"), 123.0)
        
        checkSuccess(p.run("123.456"), 123.456)
        checkSuccess(p.run("123.45600"), 123.456)
        checkSuccess(p.run("00123.456"), 123.456)
        
        checkSuccess(p.run("12345e2"), 12345e2)
        checkSuccess(p.run("1234.5e2"), 1234.5e2)
        checkSuccess(p.run("1234.5e-2"), 1234.5e-2)
        checkSuccess(p.run("1234.5e+2"), 1234.5e2)
        
        checkFailure(p.run("1234.5e"))
        checkFailure(p.run("1234.5ea"))
    }
    
    func test_floatingPoint_hexadecimal() {
        let p = floatingPoint()
        
        checkSuccess(p.run("0x1c.6"), 0x1c.6p0)
        checkSuccess(p.run("0x1C.6"), 0x1c.6p0)
        checkSuccess(p.run("0X1C.6"), 0x1c.6p0)
        
        checkSuccess(p.run("-0x1c.6"), -0x1c.6p0)
        checkSuccess(p.run("+0x1c.6"), 0x1c.6p0)
    }
    
    func test_floatingPoint_octal() {
        let p = floatingPoint()
        
        checkSuccess(p.run("0o21"), 0o21)
        checkSuccess(p.run("0o123.456"), 83.58984375)
    }
    
    func test_floatingPoint_binary() {
        let p = floatingPoint()
        
        checkSuccess(p.run("0b10001"), 0b10001)
        checkSuccess(p.run("0b101.010"), 5.25)
    }
    
    func test_floatingPoint_underscores() {
        let p = floatingPoint(allowUnderscores: true)
        
        checkSuccess(floatingPoint().run("1_000_000.000_000_1"), 1.0)
        
        checkSuccess(p.run("1_000_000.000_000_1"), 1_000_000.000_000_1)
        checkSuccess(p.run("-1_000_000.000_000_1"), -1_000_000.000_000_1)
        checkSuccess(p.run("+1_000_000.000_000_1"), 1_000_000.000_000_1)
        
        checkSuccess(p.run("0x1_000_000.000_000_1"), 0x1_000_000.000_000_1p0)
        checkSuccess(p.run("0x1_000_000.000_000_1p3"), 0x1_000_000.000_000_1p3)
        checkSuccess(p.run("-0x1_000_000.000_000_1p3"), -0x1_000_000.000_000_1p3)
        checkSuccess(p.run("+0x1_000_000.000_000_1p3"), 0x1_000_000.000_000_1p3)
        
        checkSuccess(p.run("1_00_"), 100.0)
        checkFailure(p.run("_1_00"))
    }
    
    func test_floatingPoint_NaN() {
        let p = floatingPoint()
        
        XCTAssertEqual(p.run("NaN").value?.isNaN, true)
        XCTAssertEqual(p.run("nan").value?.isNaN, true)
        XCTAssertEqual(p.run("nan").value?.sign, FloatingPointSign.plus)
        XCTAssertEqual(p.run("-nan").value?.isNaN, true)
        XCTAssertEqual(p.run("-nan").value?.sign, FloatingPointSign.minus)
        XCTAssertEqual(p.run("+nan").value?.isNaN, true)
        XCTAssertEqual(p.run("+nan").value?.sign, FloatingPointSign.plus)
        
        XCTAssertEqual(p.run("nano").value?.isNaN, true)
        checkFailure(p.run("NotaNumber"))
    }
    
    func test_floatingPoint_Infinity() {
        let p = floatingPoint()
        
        checkSuccess(p.run("inf"), Double.infinity)
        checkSuccess(p.run("infinity"), Double.infinity)
        checkSuccess(p.run("INFINITY"), Double.infinity)
        checkSuccess(p.run("-inf"), -Double.infinity)
        checkSuccess(p.run("+inf"), Double.infinity)
        
        checkSuccess(p.run("information"), Double.infinity)
        checkFailure(p.run("integer"))
    }
    
    func test_floatingPoint_overflow() {
        let p = floatingPoint()
        
        checkFailure(p.run("12345678901234567890"))
    }
    
    func test_integer_decimal() {
        let p = integer()
        
        checkSuccess(p.run("0"), 0)
        checkSuccess(p.run("-0"), 0)
        checkSuccess(p.run("+0"), 0)
        
        checkSuccess(p.run("123"), 123)
        checkSuccess(p.run("-123"), -123)
        checkSuccess(p.run("+123"), 123)
        
        checkSuccess(p.run("123.0"), 123)
        checkSuccess(p.run("-123.0"), -123)
        checkSuccess(p.run("+123.0"), 123)
        
        checkSuccess(p.run("123.456"), 123)
        checkSuccess(p.run("00123.456"), 123)
    }
    
    func test_integer_hexadecimal() {
        let p = integer()
        
        checkSuccess(p.run("0x1c"), 0x1c)
        checkSuccess(p.run("0x1C"), 0x1c)
        checkSuccess(p.run("0X1C"), 0x1c)
        
        checkSuccess(p.run("-0x1c"), -0x1c)
        checkSuccess(p.run("+0x1c"), 0x1c)
        
        checkSuccess(p.run("0x1c.6"), 0x1c)
        checkSuccess(p.run("0x1C.6"), 0x1c)
        checkSuccess(p.run("0X1C.6"), 0x1c)
    }
    
    func test_integer_octal() {
        let p = integer()
        
        checkSuccess(p.run("0o21"), 0o21)
        checkSuccess(p.run("-0o21"), -0o21)
    }
    
    func test_integer_binary() {
        let p = integer()
        
        checkSuccess(p.run("0b10001"), 0b10001)
        checkSuccess(p.run("-0b10001"), -0b10001)
    }
    
    func test_integer_exponent() {
        let p = integer(allowExponent: true)
        
        checkSuccess(integer().run("100e3"), 100)
        
        checkSuccess(p.run("100e3"), 100_000)
        checkSuccess(p.run("-100e3"), -100_000)
        
        checkSuccess(p.run("100e-1"), 10)
        checkSuccess(p.run("100e+3"), 100_000)
        
        checkSuccess(p.run("-100e-1"), -10)
        checkSuccess(p.run("-100e+3"), -100_000)
        
        checkFailure(p.run("100e-3"))   // overflow
        checkFailure(p.run("100e+30"))  // overflow
    }
    
    func test_integer_underscores() {
        let p = integer(allowUnderscores: true)
        
        checkSuccess(integer().run("1_000_000"), 1)
        
        checkSuccess(p.run("1_000_000"), 1_000_000)
        checkSuccess(p.run("-1_000_000"), -1_000_000)
        checkSuccess(p.run("+1_000_000"), 1_000_000)
        
        checkSuccess(p.run("0x1_000_000"), 0x1_000_000)
        checkSuccess(p.run("-0x1_000_000"), -0x1_000_000)
        checkSuccess(p.run("+0x1_000_000"), 0x1_000_000)
        
        checkSuccess(p.run("1_00_"), 100)
        checkFailure(p.run("_1_00"))
    }
    
    func test_integer_overflow() {
        checkFailure(integer().run("12345678901234567890"))
    }
    
    func test_floatingPoint_whenSuccess_nextIndexIsAfterNumber() {
        let p = floatingPoint()
        
        var stream = CharacterStream(string: "9.7-inch tablet")
        checkSuccess(p.parse(stream), 9.7)
        XCTAssertEqual(stream.nextIndex, stream.string.index(of: "-"))
        
        stream = CharacterStream(string: "infinity loop")
        checkSuccess(p.parse(stream), Double.infinity)
        XCTAssertEqual(stream.nextIndex, stream.string.index(of: " "))
        
        stream = CharacterStream(string: "nand memory")
        XCTAssertTrue(p.parse(stream).value?.isNaN ?? false)
        XCTAssertEqual(stream.nextIndex, stream.string.index(of: "d"))
    }
    
    func test_integer_whenSuccess_nextIndexIsAfterNumber() {
        let p = integer()
        
        var stream = CharacterStream(string: "13-inch notebook")
        checkSuccess(p.parse(stream), 13)
        XCTAssertEqual(stream.nextIndex, stream.string.index(of: "-"))
        
        stream = CharacterStream(string: "9.7-inch tablet")
        checkSuccess(p.parse(stream), 9)
        XCTAssertEqual(stream.nextIndex, stream.string.index(of: "."))
    }
    
    func test_floatingPoint_whenOverflow_nextIndexIsAtStart() {
        let p = floatingPoint()
        
        let stream = CharacterStream(string: "12345678901234567890")
        checkFatalFailure(p.parse(stream))
        XCTAssertEqual(stream.nextIndex, stream.startIndex)
    }
    
    func test_integer_whenOverflow_nextIndexIsAtStart() {
        let p = integer()
        
        let stream = CharacterStream(string: "12345678901234567890")
        checkFatalFailure(p.parse(stream))
        XCTAssertEqual(stream.nextIndex, stream.startIndex)
    }
}



