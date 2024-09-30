import Testing
import Strix
@testable import StrixParsers

@Suite struct JSONParserTests {
    private let sut = JSONParser()
    
    @Test func parse_null() throws {
        try #expect(sut.parse("null") == .null)
    }
    
    @Test func parse_bool() throws {
        try #expect(sut.parse("true") == .bool(true))
        try #expect(sut.parse("false") == .bool(false))
    }
    
    @Test func parse_number() throws {
        try #expect(sut.parse("567") == .number(567))
        try #expect(sut.parse("567.123") == .number(567.123))
    }
    
    @Test func parse_string() throws {
        try #expect(sut.parse(#""This is a string""#) == .string("This is a string"))
        
        try #expect(sut.parse(#""ab\"cd""#) == .string("ab\"cd"))
        try #expect(sut.parse(#""ab\\cd""#) == .string("ab\\cd"))
        try #expect(sut.parse(#""ab\/cd""#) == .string("ab/cd"))
        try #expect(sut.parse(#""ab\bcd""#) == .string("ab\u{0008}cd"))
        try #expect(sut.parse(#""ab\fcd""#) == .string("ab\u{000C}cd"))
        try #expect(sut.parse(#""ab\ncd""#) == .string("ab\ncd"))
        try #expect(sut.parse(#""ab\rcd""#) == .string("ab\rcd"))
        try #expect(sut.parse(#""ab\tcd""#) == .string("ab\tcd"))
        try #expect(sut.parse(#""ab\uD55Ccd""#) == .string("ab한cd"))
        try #expect(sut.parse(#""ab\uad6dcd""#) == .string("ab국cd"))
    }
    
    @Test func parse_string_withoutQuote_error() {
        #expect(throws: RunError.self, performing: {
            try sut.parse("abcd")
        })
    }
    
    @Test func parse_array() throws {
        let jsonString = #"[null, true, 123, "abc"]"#
        let json = JSON.array([.null, .bool(true), .number(123), .string("abc")])
        try #expect(sut.parse(jsonString) == json)
    }
    
    @Test func parse_dictionary() throws {
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
        
        try #expect(sut.parse(jsonString) == json)
    }
    
    @Test func parse_nestedValue() throws {
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
        
        try #expect(sut.parse(jsonString) == json)
    }
    
    @Test func parse_complex() throws {
        try #expect(sut.parse(JSONFixture.windowJSONString) == JSONFixture.windowJSON)
    }
}
