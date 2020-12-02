import XCTest
@testable import StrixParsers

final class String_Tests: XCTestCase {
    func test_addingBackslashEncoding() {
        XCTAssertEqual("abc\ndef".addingBackslashEncoding(), "abc\\ndef")
        XCTAssertEqual("abc\tdef".addingBackslashEncoding(), "abc\\tdef")
        XCTAssertEqual("abc\ndef\t".addingBackslashEncoding(), "abc\\ndef\\t")
    }
}
