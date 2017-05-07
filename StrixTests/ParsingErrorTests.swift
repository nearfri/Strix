
import XCTest
@testable import Strix

class ParsingErrorTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func test_baseError() {
        XCTAssertEqual(ParsingError().description, "Unknown")
    }
    
    func test_expectedError() {
        XCTAssertEqual(ParsingError.Expected("number").description, "Expected(number)")
    }
    
    func test_expectedStringError() {
        XCTAssertEqual(ParsingError.ExpectedString("any string", case: .sensitive).description,
                       "ExpectedCaseSensitive(any string)")
        XCTAssertEqual(ParsingError.ExpectedString("any string", case: .insensitive).description,
                       "ExpectedCaseInsensitive(any string)")
    }
    
    func test_unexpectedError() {
        XCTAssertEqual(ParsingError.Unexpected("number").description, "Unexpected(number)")
    }
    
    func test_UnexpectedStringError() {
        XCTAssertEqual(ParsingError.UnexpectedString("any string", case: .sensitive).description,
                       "UnexpectedCaseSensitive(any string)")
        XCTAssertEqual(ParsingError.UnexpectedString("any string", case: .insensitive).description,
                       "UnexpectedCaseInsensitive(any string)")
    }
    
    func test_genericError() {
        XCTAssertEqual(ParsingError.Generic(message: "just error").description,
                       "Generic(just error)")
    }
    
    func test_nestedError() {
        let str = "abcd"
        let position = CharacterPosition(string: str, index: str.index(after: str.startIndex))
        let lineNumber = 1
        let columnNumber = 2
        let userInfo = ["infoKey": "infoValue"]
        let errs = [ParsingError.Expected("number"), ParsingError.Unexpected("number")]
        let expectedDesc = "Nested(\(lineNumber):\(columnNumber), "
            + "[Expected(number), Unexpected(number)])"
        let error = ParsingError.Nested(position: position, userInfo: userInfo, errors: errs)
        XCTAssertEqual(error.description, expectedDesc)
    }
    
    func test_compoundError() {
        let label = "custom label"
        let str = "abcd"
        let position = CharacterPosition(string: str, index: str.index(after: str.startIndex))
        let lineNumber = 1
        let columnNumber = 2
        let userInfo = ["infoKey": "infoValue"]
        let errs = [ParsingError.Expected("number"), ParsingError.Unexpected("number")]
        let expectedDesc = "Compound(\(label), \(lineNumber):\(columnNumber), "
            + "[Expected(number), Unexpected(number)])"
        let error = ParsingError.Compound(label: label, position: position,
                                         userInfo: userInfo, errors: errs)
        XCTAssertEqual(error.description, expectedDesc)
    }
}



