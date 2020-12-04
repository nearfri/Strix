import XCTest
@testable import StrixParsers

final class ASCIIPlistParserTests: XCTestCase {
    typealias DictionaryEntry = ASCIIPlist.DictionaryEntry
    
    let sut = ASCIIPlistParser()
    
    func test_parse_string() {
        XCTAssertEqual(try sut.parse(#""This is a string""#), .string("This is a string"))
        
        XCTAssertEqual(try sut.parse(#""ab\"cd""#), .string("ab\"cd"))
        XCTAssertEqual(try sut.parse(#""ab\\cd""#), .string("ab\\cd"))
        XCTAssertEqual(try sut.parse(#""ab\/cd""#), .string("ab/cd"))
        XCTAssertEqual(try sut.parse(#""ab\bcd""#), .string("ab\u{0008}cd"))
        XCTAssertEqual(try sut.parse(#""ab\fcd""#), .string("ab\u{000C}cd"))
        XCTAssertEqual(try sut.parse(#""ab\ncd""#), .string("ab\ncd"))
        XCTAssertEqual(try sut.parse(#""ab\rcd""#), .string("ab\rcd"))
        XCTAssertEqual(try sut.parse(#""ab\tcd""#), .string("ab\tcd"))
    }
    
    func test_parse_quoteOmittedASCIIWord() {
        XCTAssertEqual(try sut.parse("hello"), .string("hello"))
        XCTAssertEqual(try sut.parse("1564"), .string("1564"))
    }
    
    func test_data() {
        XCTAssertEqual(try sut.parse("<0123456789abcdef>"),
                       .data(Data([0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef])))
        
        XCTAssertEqual(try sut.parse("<0fbd777f 1c2735ae>"),
                       .data(Data([0x0f, 0xbd, 0x77, 0x7f, 0x1c, 0x27, 0x35, 0xae])))
        
        XCTAssertEqual(try sut.parse("<>"), .data(Data()))
    }
    
    func test_array() {
        let plistString = #"("San Francisco", "New York", "Seoul")"#
        
        let plist = ASCIIPlist.array([
            .string("San Francisco"), .string("New York"), .string("Seoul")
        ])
        
        XCTAssertEqual(try sut.parse(plistString), plist)
    }
    
    func test_array_endBySeparator() {
        let plistString = #"("San Francisco", "New York", )"#
        
        let plist = ASCIIPlist.array([
            .string("San Francisco"), .string("New York")
        ])
        
        XCTAssertEqual(try sut.parse(plistString), plist)
    }
    
    func test_dictionary() {
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
        
        XCTAssertEqual(try sut.parse(plistString), plist)
    }
    
    func test_dictionary_withoutCurlyBracesAtRoot() {
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
        
        XCTAssertEqual(try sut.parse(plistString), plist)
    }
    
    func test_parse_comment_beforeString_ignore() {
        let plistString = """
        /* comment */
        "hello"
        """
        
        XCTAssertEqual(try sut.parse(plistString), .string("hello"))
    }
    
    func test_parse_manyComment_beforeString_ignore() {
        let plistString = """
        /* comment */
        /* comment */
        "hello"
        """
        
        XCTAssertEqual(try sut.parse(plistString), .string("hello"))
    }
    
    func test_parse_comment_afterString_ignore() {
        let plistString = """
        "hello"
        /* comment */
        """
        
        XCTAssertEqual(try sut.parse(plistString), .string("hello"))
    }
    
    func test_parse_manyComment_afterString_ignore() {
        let plistString = """
        "hello"
        /* comment */
        /* comment */
        """
        
        XCTAssertEqual(try sut.parse(plistString), .string("hello"))
    }
    
    func test_parse_comment_beforeData_ignore() {
        let plistString = """
        /* comment */
        <0f>
        """
        
        XCTAssertEqual(try sut.parse(plistString), .data(Data([0x0f])))
    }
    
    func test_parse_comment_afterData_ignore() {
        let plistString = """
        <0f>
        /* comment */
        """
        
        XCTAssertEqual(try sut.parse(plistString), .data(Data([0x0f])))
    }
    
    func test_parse_comment_beforeArray_ignore() {
        let plistString = """
        /* comment */
        ("Seoul")
        """
        
        XCTAssertEqual(try sut.parse(plistString), .array([.string("Seoul")]))
    }
    
    func test_parse_comment_afterArray_ignore() {
        let plistString = """
        ("Seoul")
        /* comment */
        """
        
        XCTAssertEqual(try sut.parse(plistString), .array([.string("Seoul")]))
    }
    
    func test_parse_comment_insideArray_ignore() {
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
        
        XCTAssertEqual(try sut.parse(plistString), plist)
    }
    
    func test_parse_comment_beforeDictionary_ignore() {
        let plistString = """
        /* comment */
        {
            Animal = "pig";
        }
        """
        
        XCTAssertEqual(try sut.parse(plistString), .dictionary([
            DictionaryEntry(comment: nil, key: "Animal", value: .string("pig"))
        ]))
    }
    
    func test_parse_comment_afterDictionary_ignore() {
        let plistString = """
        {
            Animal = "pig";
        }
        /* comment */
        """
        
        XCTAssertEqual(try sut.parse(plistString), .dictionary([
            DictionaryEntry(comment: nil, key: "Animal", value: .string("pig"))
        ]))
    }
    
    func test_parse_comment_beforeDictionaryKey_take() {
        let plistString = """
        {
            /* comment */
            Animal = "pig";
        }
        """
        
        XCTAssertEqual(try sut.parse(plistString), .dictionary([
            DictionaryEntry(comment: "comment", key: "Animal", value: .string("pig"))
        ]))
    }
    
    func test_parse_comment_withoutCurlyBracesAtRoot_beforeDictionaryKey_take() {
        let plistString = """
        /* comment */
        Animal = "pig";
        """
        
        XCTAssertEqual(try sut.parse(plistString), .dictionary([
            DictionaryEntry(comment: "comment", key: "Animal", value: .string("pig"))
        ]))
    }
    
    func test_parse_manyComment_beforeDictionaryKey_takeLastOne() {
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
        
        XCTAssertEqual(try sut.parse(plistString), .dictionary([
            DictionaryEntry(comment: "comment2", key: "Animal", value: .string("pig")),
            DictionaryEntry(comment: "comment4", key: "City", value: .string("Seoul"))
        ]))
    }
    
    func test_parse_comment_withoutFollowingPair_ignore() {
        let plistString = """
        {
            Animal = "pig";
            /* comment */
        }
        """
        
        XCTAssertEqual(try sut.parse(plistString), .dictionary([
            DictionaryEntry(comment: nil, key: "Animal", value: .string("pig"))
        ]))
    }
    
    func test_parse_comment_withoutCurlyBracesAtRoot_withoutFollowingPair_ignore() {
        let plistString = """
        Animal = "pig";
        /* comment */
        """
        
        XCTAssertEqual(try sut.parse(plistString), .dictionary([
            DictionaryEntry(comment: nil, key: "Animal", value: .string("pig"))
        ]))
    }
    
    func test_parse_comment_insideDictionaryEntry_ignore() {
        let plistString = """
        {
            Animal /* comment */ = /* comment */ "pig" /* comment */ ;
        }
        """
        
        XCTAssertEqual(try sut.parse(plistString), .dictionary([
            DictionaryEntry(comment: nil, key: "Animal", value: .string("pig"))
        ]))
    }
}
