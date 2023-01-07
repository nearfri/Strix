import XCTest
@testable import StrixParsers

final class JSONParserTests: XCTestCase {
    let sut = JSONParser()
    
    func test_parse_null() {
        XCTAssertEqual(try sut.parse("null"), .null)
    }
    
    func test_parse_bool() {
        XCTAssertEqual(try sut.parse("true"), .bool(true))
        XCTAssertEqual(try sut.parse("false"), .bool(false))
    }
    
    func test_parse_number() {
        XCTAssertEqual(try sut.parse("567"), .number(567))
        XCTAssertEqual(try sut.parse("567.123"), .number(567.123))
    }
    
    func test_parse_string() throws {
        XCTAssertEqual(try sut.parse(#""This is a string""#), .string("This is a string"))
        
        XCTAssertEqual(try sut.parse(#""ab\"cd""#), .string("ab\"cd"))
        XCTAssertEqual(try sut.parse(#""ab\\cd""#), .string("ab\\cd"))
        XCTAssertEqual(try sut.parse(#""ab\/cd""#), .string("ab/cd"))
        XCTAssertEqual(try sut.parse(#""ab\bcd""#), .string("ab\u{0008}cd"))
        XCTAssertEqual(try sut.parse(#""ab\fcd""#), .string("ab\u{000C}cd"))
        XCTAssertEqual(try sut.parse(#""ab\ncd""#), .string("ab\ncd"))
        XCTAssertEqual(try sut.parse(#""ab\rcd""#), .string("ab\rcd"))
        XCTAssertEqual(try sut.parse(#""ab\tcd""#), .string("ab\tcd"))
        XCTAssertEqual(try sut.parse(#""ab\uD55Ccd""#), .string("ab한cd"))
        XCTAssertEqual(try sut.parse(#""ab\uad6dcd""#), .string("ab국cd"))
    }
    
    func test_parse_string_withoutQuote_error() {
        XCTAssertThrowsError(try sut.parse("abcd"))
    }
    
    func test_parse_array() throws {
        let jsonString = #"[null, true, 123, "abc"]"#
        let json = JSON.array([.null, .bool(true), .number(123), .string("abc")])
        XCTAssertEqual(try sut.parse(jsonString), json)
    }
    
    func test_parse_dictionary() throws {
        let jsonString = """
        {
            "optional": null,
            "boolean": true,
            "numeric": 123,
            "text": "abc"
        }
        """
        
        let json = JSON.dictionary([
            "optional": .null,
            "boolean": .bool(true),
            "numeric": .number(123),
            "text": .string("abc")
        ])
        
        XCTAssertEqual(try sut.parse(jsonString), json)
    }
    
    func test_parse_nestedValue() {
        let jsonString = """
        {
            "list": [
                {
                    "name": "Tim",
                    "age": 20
                }
            ]
        }
        """
        
        let json = JSON.dictionary([
            "list": .array([
                .dictionary([
                    "name": .string("Tim"),
                    "age": .number(20)
                ])
            ])
        ])
        
        XCTAssertEqual(try sut.parse(jsonString), json)
    }
    
    func test_parse_complex() throws {
        XCTAssertEqual(try sut.parse(JSONSeed.windowJSONString), JSONSeed.windowJSON)
    }
}
