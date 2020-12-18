import XCTest
@testable import StrixParsers

final class String_Tests: XCTestCase {
    func test_addingBackslashEncoding() {
        XCTAssertEqual("ab\"cd".addingBackslashEncoding(), #"ab\"cd"#)
        XCTAssertEqual("ab\\cd".addingBackslashEncoding(), #"ab\cd"#)
        XCTAssertEqual("ab\\ncd".addingBackslashEncoding(), #"ab\ncd"#)
        XCTAssertEqual("ab\ncd".addingBackslashEncoding(), #"ab\ncd"#)
        XCTAssertEqual("ab\rcd".addingBackslashEncoding(), #"ab\rcd"#)
        XCTAssertEqual("ab\tcd".addingBackslashEncoding(), #"ab\tcd"#)
        XCTAssertEqual("ab\u{0008}cd".addingBackslashEncoding(), #"ab\bcd"#)
        XCTAssertEqual("ab\u{000C}cd".addingBackslashEncoding(), #"ab\fcd"#)
    }
}
