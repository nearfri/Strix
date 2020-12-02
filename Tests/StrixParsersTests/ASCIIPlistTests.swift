import XCTest
@testable import StrixParsers

private typealias DictionaryEntry = ASCIIPlist.DictionaryEntry

private enum Seed {
    static let plist: ASCIIPlist = .dictionary([
        DictionaryEntry(comment: "String value", key: "Greeting", value: .string(
            "Hello\nWorld"
        )),
        DictionaryEntry(comment: "Data value", key: "Binaries", value: .data(Data([
            0x0f, 0xbd, 0x77, 0xf7, 0x1c, 0x27, 0x35, 0xae
        ]))),
        DictionaryEntry(comment: "Array values", key: "Cities", value: .array([
            .string("San Francisco"), .string("New York"), .string("Seoul")
        ])),
        DictionaryEntry(comment: "Dictionary values", key: "AnimalSmells", value: .dictionary([
            DictionaryEntry(key: "pig", value: .string("piggish")),
            DictionaryEntry(key: "lamb", value: .string("lambish")),
        ]))
    ])
    
    static let plistString: String = """
    /* String value */
    "Greeting" = "Hello\\nWorld";
    
    /* Data value */
    "Binaries" = <0fbd77f71c2735ae>;
    
    /* Array values */
    "Cities" = (
        "San Francisco",
        "New York",
        "Seoul"
    );
    
    /* Dictionary values */
    "AnimalSmells" = {
        "pig" = "piggish";
        "lamb" = "lambish";
    };
    """
}

final class ASCIIPlistTests: XCTestCase {
    func test_description() {
        XCTAssertEqual(Seed.plist.description, Seed.plistString)
    }
}
