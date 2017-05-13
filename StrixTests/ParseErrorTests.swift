
import XCTest
@testable import Strix

class ParseErrorTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func test_baseError() {
        XCTAssertEqual(ParseError().description, "Unknown")
    }
    
    func test_expectedError() {
        XCTAssertEqual(ParseError.Expected("number").description, "Expected(number)")
    }
    
    func test_expectedStringError() {
        XCTAssertEqual(ParseError.ExpectedString("any string", case: .sensitive).description,
                       "ExpectedCaseSensitive(any string)")
        XCTAssertEqual(ParseError.ExpectedString("any string", case: .insensitive).description,
                       "ExpectedCaseInsensitive(any string)")
    }
    
    func test_unexpectedError() {
        XCTAssertEqual(ParseError.Unexpected("number").description, "Unexpected(number)")
    }
    
    func test_UnexpectedStringError() {
        XCTAssertEqual(ParseError.UnexpectedString("any string", case: .sensitive).description,
                       "UnexpectedCaseSensitive(any string)")
        XCTAssertEqual(ParseError.UnexpectedString("any string", case: .insensitive).description,
                       "UnexpectedCaseInsensitive(any string)")
    }
    
    func test_genericError() {
        XCTAssertEqual(ParseError.Generic(message: "just error").description,
                       "Generic(just error)")
    }
    
    func test_nestedError() {
        let str = "abcd"
        let position = TextPosition(string: str, index: str.index(after: str.startIndex))
        let lineNumber = 1
        let columnNumber = 2
        let userInfo = ["infoKey": "infoValue"]
        let errs = [ParseError.Expected("number"), ParseError.Unexpected("number")]
        let expectedDesc = "Nested(\(lineNumber):\(columnNumber), "
            + "[Expected(number), Unexpected(number)])"
        let error = ParseError.Nested(position: position, userInfo: userInfo, errors: errs)
        XCTAssertEqual(error.description, expectedDesc)
    }
    
    func test_compoundError() {
        let label = "custom label"
        let str = "abcd"
        let position = TextPosition(string: str, index: str.index(after: str.startIndex))
        let lineNumber = 1
        let columnNumber = 2
        let userInfo = ["infoKey": "infoValue"]
        let errs = [ParseError.Expected("number"), ParseError.Unexpected("number")]
        let expectedDesc = "Compound(\(label), \(lineNumber):\(columnNumber), "
            + "[Expected(number), Unexpected(number)])"
        let error = ParseError.Compound(label: label, position: position,
                                         userInfo: userInfo, errors: errs)
        XCTAssertEqual(error.description, expectedDesc)
    }
}



