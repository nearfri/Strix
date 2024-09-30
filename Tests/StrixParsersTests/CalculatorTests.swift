import Testing
import Foundation
@testable import StrixParsers

@Suite struct CalculatorTests {
    private let sut: Calculator = .init()
    
    @Test(arguments: [
        ("123", 123.0),
        ("-123", -123.0),
        ("3 + 4 * 2", 3 + 4 * 2),
        ("1 + 10 % 3", Double(1 + 10 % 3)),
        ("3 + 4 ^ 6 * 8 + 2", 3.0 + pow(4, 6) * 8 + 2),
        ("9 * -(4 - 2)", 9 * -(4 - 2)),
        ("+2*pow(+3 * (+2 + -4) ^ +4, 3) / -2", 2 * pow(3 * pow(2-4, 4), 3) / -2),
    ] as [(String, Double)])
    func calculate(input: String, expected: Double) throws {
        try #expect(sut(input) == expected)
    }
    
    @Test func calculate_unknownNullDenotation_throwError() {
        #expect(throws: Error.self, performing: {
            try sut("*123")
        })
    }
    
    @Test func calculate_tokenizerFailure_throwError() {
        #expect(throws: Error.self, performing: {
            try sut("12.0e")
        })
        
        #expect(throws: Error.self, performing: {
            try sut("#")
        })
    }
}
