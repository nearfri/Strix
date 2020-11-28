import XCTest
@testable import StrixParsers

final class CalculatorTests: XCTestCase {
    let sut: Calculator = .init()
    
    func test_calculate() throws {
        XCTAssertEqual(try sut("123"), 123.0)
        XCTAssertEqual(try sut("-123"), -123.0)
        XCTAssertEqual(try sut("3 + 4 * 2"), 3 + 4 * 2)
        XCTAssertEqual(try sut("1 + 10 % 3"), Double(1 + 10 % 3))
        XCTAssertEqual(try sut("3 + 4 ^ 6 * 8 + 2"), 3 + pow(4, 6) * 8 + 2)
        XCTAssertEqual(try sut("9 * -(4 - 2)"), 9 * -(4 - 2))
        XCTAssertEqual(try sut("+2*pow(+3 * (+2 + -4) ^ +4, 3) / -2"),
                       2 * pow(3 * pow(2-4, 4), 3) / -2)
    }
    
    func test_calculate_unknownNullDenotation_throwError() {
        XCTAssertThrowsError(try sut("*123"))
    }
    
    func test_calculate_tokenizerFailure_throwError() {
        XCTAssertThrowsError(try sut("12.0e"))
        XCTAssertThrowsError(try sut("#"))
    }
}
