import Testing
import Foundation
import Strix
@testable import StrixParsers

@Suite struct ASCIIPlistParserTests {
    typealias DictionaryEntry = ASCIIPlist.DictionaryEntry
    
    let sut = ASCIIPlistParser()
    
    @Test(arguments: [
        (#""This is a string""#, "This is a string"),
        (#""ab\"cd""#, "ab\"cd"),
        (#""ab\\cd""#, "ab\\cd"),
        (#""ab\/cd""#, "ab/cd"),
        (#""ab\bcd""#, "ab\u{0008}cd"),
        (#""ab\fcd""#, "ab\u{000C}cd"),
        (#""ab\ncd""#, "ab\ncd"),
        (#""ab\rcd""#, "ab\rcd"),
        (#""ab\tcd""#, "ab\tcd"),
    ] as [(String, String)])
    func parse_string(input: String, expected: String) throws {
        try #expect(sut.parse(input) == .string(expected))
    }
    
    @Test func parse_quoteOmittedASCIIWord() throws {
        try #expect(sut.parse("hello") == .string("hello"))
        try #expect(sut.parse("1564") == .string("1564"))
    }
    
    @Test(arguments: [
        ("<0123456789abcdef>", Data([0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef])),
        ("<0fbd777f 1c2735ae>", Data([0x0f, 0xbd, 0x77, 0x7f, 0x1c, 0x27, 0x35, 0xae])),
        ("<>", Data()),
    ] as [(String, Data)])
    func data(input: String, expected: Data) throws {
        try #expect(sut.parse(input) == .data(expected))
    }
    
    @Test func data_countIsOdd_throwError() {
        #expect(throws: RunError.self, performing: {
            try sut.parse("<012>")
        })
    }
    
    @Test func array() throws {
        let plistString = #"("San Francisco", "New York", "Seoul")"#
        
        let plist = ASCIIPlist.array([
            .string("San Francisco"), .string("New York"), .string("Seoul")
        ])
        
        try #expect(sut.parse(plistString) == plist)
    }
    
    @Test func array_endBySeparator() throws {
        let plistString = #"("San Francisco", "New York", )"#
        
        let plist = ASCIIPlist.array([
            .string("San Francisco"), .string("New York")
        ])
        
        try #expect(sut.parse(plistString) == plist)
    }
    
    @Test func dictionary() throws {
        let plistString = """
            {
                Animals = (pig, lamb, worm);
                AnimalSmells = { pig = piggish; lamb = lambish; worm = wormy; };
                AnimalColors = { pig = pink; lamb = black; worm = pink; };
            }
            """
        
        let plist = ASCIIPlist.dictionary([
            DictionaryEntry(key: "Animals", value: .array([
                .string("pig"), .string("lamb"), .string("worm")
            ])),
            DictionaryEntry(key: "AnimalSmells", value: .dictionary([
                DictionaryEntry(key: "pig", value: .string("piggish")),
                DictionaryEntry(key: "lamb", value: .string("lambish")),
                DictionaryEntry(key: "worm", value: .string("wormy")),
            ])),
            DictionaryEntry(key: "AnimalColors", value: .dictionary([
                DictionaryEntry(key: "pig", value: .string("pink")),
                DictionaryEntry(key: "lamb", value: .string("black")),
                DictionaryEntry(key: "worm", value: .string("pink")),
            ])),
        ])
        
        try #expect(sut.parse(plistString) == plist)
    }
    
    @Test func dictionary_withoutCurlyBracesAtRoot() throws {
        let plistString = """
            Animals = (pig, lamb, worm);
            AnimalSmells = { pig = piggish; lamb = lambish; worm = wormy; };
            AnimalColors = { pig = pink; lamb = black; worm = pink; };
            """
        
        let plist = ASCIIPlist.dictionary([
            DictionaryEntry(key: "Animals", value: .array([
                .string("pig"), .string("lamb"), .string("worm")
            ])),
            DictionaryEntry(key: "AnimalSmells", value: .dictionary([
                DictionaryEntry(key: "pig", value: .string("piggish")),
                DictionaryEntry(key: "lamb", value: .string("lambish")),
                DictionaryEntry(key: "worm", value: .string("wormy")),
            ])),
            DictionaryEntry(key: "AnimalColors", value: .dictionary([
                DictionaryEntry(key: "pig", value: .string("pink")),
                DictionaryEntry(key: "lamb", value: .string("black")),
                DictionaryEntry(key: "worm", value: .string("pink")),
            ])),
        ])
        
        try #expect(sut.parse(plistString) == plist)
    }
    
    @Test func parse_comment_beforeString_ignore() throws {
        let plistString = """
            /* comment */
            "hello"
            """
        
        try #expect(sut.parse(plistString) == .string("hello"))
    }
    
    @Test func parse_manyComment_beforeString_ignore() throws {
        let plistString = """
            /* comment */
            /* comment */
            "hello"
            """
        
        try #expect(sut.parse(plistString) == .string("hello"))
    }
    
    @Test func parse_comment_afterString_ignore() throws {
        let plistString = """
            "hello"
            /* comment */
            """
        
        try #expect(sut.parse(plistString) == .string("hello"))
    }
    
    @Test func parse_manyComment_afterString_ignore() throws {
        let plistString = """
            "hello"
            /* comment */
            /* comment */
            """
        
        try #expect(sut.parse(plistString) == .string("hello"))
    }
    
    @Test func parse_comment_beforeData_ignore() throws {
        let plistString = """
            /* comment */
            <0f>
            """
        
        try #expect(sut.parse(plistString) == .data(Data([0x0f])))
    }
    
    @Test func parse_comment_afterData_ignore() throws {
        let plistString = """
            <0f>
            /* comment */
            """
        
        try #expect(sut.parse(plistString) == .data(Data([0x0f])))
    }
    
    @Test func parse_comment_beforeArray_ignore() throws {
        let plistString = """
            /* comment */
            ("Seoul")
            """
        
        try #expect(sut.parse(plistString) == .array([.string("Seoul")]))
    }
    
    @Test func parse_comment_afterArray_ignore() throws {
        let plistString = """
            ("Seoul")
            /* comment */
            """
        
        try #expect(sut.parse(plistString) == .array([.string("Seoul")]))
    }
    
    @Test func parse_comment_insideArray_ignore() throws {
        let plistString = """
            (
                /* comment */ "San Francisco" /* comment */,
                /* comment */ "New York" /* comment */,
                /* comment */ /* comment */ "Seoul" /* comment */ /* comment */
            )
            """
        
        let plist = ASCIIPlist.array([
            .string("San Francisco"), .string("New York"), .string("Seoul")
        ])
        
        try #expect(sut.parse(plistString) == plist)
    }
    
    @Test func parse_comment_beforeDictionary_ignore() throws {
        let plistString = """
            /* comment */
            {
                Animal = "pig";
            }
            """
        
        try #expect(sut.parse(plistString) == .dictionary([
            DictionaryEntry(comment: nil, key: "Animal", value: .string("pig"))
        ]))
    }
    
    @Test func parse_comment_afterDictionary_ignore() throws {
        let plistString = """
            {
                Animal = "pig";
            }
            /* comment */
            """
        
        try #expect(sut.parse(plistString) == .dictionary([
            DictionaryEntry(comment: nil, key: "Animal", value: .string("pig"))
        ]))
    }
    
    @Test func parse_comment_beforeDictionaryKey_take() throws {
        let plistString = """
            {
                /* comment */
                Animal = "pig";
            }
            """
        
        try #expect(sut.parse(plistString) == .dictionary([
            DictionaryEntry(comment: "comment", key: "Animal", value: .string("pig"))
        ]))
    }
    
    @Test func parse_slashComment_beforeDictionaryKey_take() throws {
        let plistString = """
            {
                // comment
                Animal = "pig";
            }
            """
        
        try #expect(sut.parse(plistString) == .dictionary([
            DictionaryEntry(comment: "comment", key: "Animal", value: .string("pig"))
        ]))
    }
    
    @Test func parse_comment_withoutCurlyBracesAtRoot_beforeDictionaryKey_take() throws {
        let plistString = """
            /* comment */
            Animal = "pig";
            """
        
        try #expect(sut.parse(plistString) == .dictionary([
            DictionaryEntry(comment: "comment", key: "Animal", value: .string("pig"))
        ]))
    }
    
    @Test func parse_manyComment_beforeDictionaryKey_takeLastOne() throws {
        let plistString = """
            {
                /* comment1 */
                /* comment2 */
                Animal = "pig";
                
                /* comment3 */
                /* comment4 */
                City = "Seoul";
            }
            """
        
        try #expect(sut.parse(plistString) == .dictionary([
            DictionaryEntry(comment: "comment2", key: "Animal", value: .string("pig")),
            DictionaryEntry(comment: "comment4", key: "City", value: .string("Seoul"))
        ]))
    }
    
    @Test func parse_comment_withoutFollowingPair_ignore() throws {
        let plistString = """
            {
                Animal = "pig";
                /* comment */
            }
            """
        
        try #expect(sut.parse(plistString) == .dictionary([
            DictionaryEntry(comment: nil, key: "Animal", value: .string("pig"))
        ]))
    }
    
    @Test func parse_comment_withoutCurlyBracesAtRoot_withoutFollowingPair_ignore() throws {
        let plistString = """
            Animal = "pig";
            /* comment */
            """
        
        try #expect(sut.parse(plistString) == .dictionary([
            DictionaryEntry(comment: nil, key: "Animal", value: .string("pig"))
        ]))
    }
    
    @Test func parse_comment_insideDictionaryEntry_ignore() throws {
        let plistString = """
            {
                Animal /* comment */ = /* comment */ "pig" /* comment */ ;
            }
            """
        
        try #expect(sut.parse(plistString) == .dictionary([
            DictionaryEntry(comment: nil, key: "Animal", value: .string("pig"))
        ]))
    }
    
    @Test func parse_comment_only() throws {
        try #expect(sut.parse("( /* comment */ )") == .array([]))
        try #expect(sut.parse("{ /* comment */ }") == .dictionary([]))
        try #expect(sut.parse("/* comment */") == .dictionary([]))
        try #expect(sut.parse("// comment") == .dictionary([]))
    }
    
    @Test func parse_comment_notCompleted_throwError() throws {
        #expect(throws: RunError.self, performing: {
            try sut.parse("/* comment ")
        })
    }
    
    @Test func parse_empty() throws {
        try #expect(sut.parse(" ") == .dictionary([]))
        try #expect(sut.parse("") == .dictionary([]))
    }
}
