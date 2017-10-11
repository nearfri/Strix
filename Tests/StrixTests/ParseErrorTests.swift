
import XCTest
@testable import Strix

class ParseErrorTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func test_baseError_description() {
        XCTAssertEqual(ParseError().description, "Unknown")
    }
    
    func test_expectedError_description() {
        XCTAssertEqual(ParseError.Expected("number").description, "Expected(number)")
    }
    
    func test_expectedError_compare() {
        XCTAssertEqual(ParseError.Expected("abc"), ParseError.Expected("abc"))
        XCTAssertNotEqual(ParseError.Expected("abc"), ParseError.Expected("def"))
        XCTAssertLessThan(ParseError.Expected("abc"), ParseError.Expected("def"))
    }
    
    func test_expectedStringError_description() {
        XCTAssertEqual(ParseError.ExpectedString("any string", case: .sensitive).description,
                       "ExpectedCaseSensitive(any string)")
        
        XCTAssertEqual(ParseError.ExpectedString("any string", case: .insensitive).description,
                       "ExpectedCaseInsensitive(any string)")
    }
    
    func test_expectedStringError_compare() {
        XCTAssertEqual(ParseError.ExpectedString("abc", case: .sensitive),
                       ParseError.ExpectedString("abc", case: .sensitive))
        
        XCTAssertEqual(ParseError.ExpectedString("abc", case: .insensitive),
                       ParseError.ExpectedString("abc", case: .insensitive))
        
        XCTAssertNotEqual(ParseError.ExpectedString("abc", case: .sensitive),
                          ParseError.ExpectedString("abc", case: .insensitive))
        
        XCTAssertNotEqual(ParseError.ExpectedString("abc", case: .sensitive),
                          ParseError.ExpectedString("def", case: .sensitive))
        
        XCTAssertLessThan(ParseError.ExpectedString("abc", case: .sensitive),
                          ParseError.ExpectedString("def", case: .sensitive))
        
        XCTAssertLessThan(ParseError.ExpectedString("abc", case: .insensitive),
                          ParseError.ExpectedString("def", case: .insensitive))
        
        XCTAssertLessThan(ParseError.ExpectedString("abc", case: .sensitive),
                          ParseError.ExpectedString("abc", case: .insensitive))
        
        XCTAssertLessThan(ParseError.ExpectedString("def", case: .sensitive),
                          ParseError.ExpectedString("abc", case: .insensitive))
        
        let insensitiveError = ParseError.ExpectedString("abc", case: .insensitive)
        let sensitiveError = ParseError.ExpectedString("def", case: .sensitive)
        XCTAssertFalse(insensitiveError < sensitiveError)
    }
    
    func test_unexpectedError_description() {
        XCTAssertEqual(ParseError.Unexpected("number").description, "Unexpected(number)")
    }
    
    func test_unexpectedError_compare() {
        XCTAssertEqual(ParseError.Unexpected("abc"), ParseError.Unexpected("abc"))
        XCTAssertNotEqual(ParseError.Unexpected("abc"), ParseError.Unexpected("def"))
        XCTAssertLessThan(ParseError.Unexpected("abc"), ParseError.Unexpected("def"))
    }
    
    func test_unexpectedStringError_compare() {
        XCTAssertEqual(ParseError.UnexpectedString("abc", case: .sensitive),
                       ParseError.UnexpectedString("abc", case: .sensitive))
        
        XCTAssertEqual(ParseError.UnexpectedString("abc", case: .insensitive),
                       ParseError.UnexpectedString("abc", case: .insensitive))
        
        XCTAssertNotEqual(ParseError.UnexpectedString("abc", case: .sensitive),
                          ParseError.UnexpectedString("abc", case: .insensitive))
        
        XCTAssertNotEqual(ParseError.UnexpectedString("abc", case: .sensitive),
                          ParseError.UnexpectedString("def", case: .sensitive))
        
        XCTAssertLessThan(ParseError.UnexpectedString("abc", case: .sensitive),
                          ParseError.UnexpectedString("def", case: .sensitive))
        
        XCTAssertLessThan(ParseError.UnexpectedString("abc", case: .insensitive),
                          ParseError.UnexpectedString("def", case: .insensitive))
        
        XCTAssertLessThan(ParseError.UnexpectedString("abc", case: .sensitive),
                          ParseError.UnexpectedString("abc", case: .insensitive))
        
        XCTAssertLessThan(ParseError.UnexpectedString("def", case: .sensitive),
                          ParseError.UnexpectedString("abc", case: .insensitive))
        
        let insensitiveError = ParseError.UnexpectedString("abc", case: .insensitive)
        let sensitiveError = ParseError.UnexpectedString("def", case: .sensitive)
        XCTAssertFalse(insensitiveError < sensitiveError)
    }
    
    func test_UnexpectedStringError_description() {
        XCTAssertEqual(ParseError.UnexpectedString("any string", case: .sensitive).description,
                       "UnexpectedCaseSensitive(any string)")
        
        XCTAssertEqual(ParseError.UnexpectedString("any string", case: .insensitive).description,
                       "UnexpectedCaseInsensitive(any string)")
    }
    
    func test_genericError_description() {
        XCTAssertEqual(ParseError.Generic(message: "just error").description,
                       "Generic(just error)")
    }
    
    func test_genericError_compare() {
        XCTAssertEqual(ParseError.Generic(message: "abc"), ParseError.Generic(message: "abc"))
        XCTAssertNotEqual(ParseError.Generic(message: "abc"), ParseError.Generic(message: "def"))
        XCTAssertLessThan(ParseError.Generic(message: "abc"), ParseError.Generic(message: "def"))
    }
    
    func test_nestedError_description() {
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
    
    func test_compoundError_description() {
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



