
import XCTest
@testable import Strix

class ParseResultTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func test_description_success() {
        let value = "hello world"
        let sut = ParseResult.success(value)
        XCTAssertEqual(sut.description, "Success: \(value)")
    }
    
    func test_description_failure() {
        let str = "abcdefghi"
        let offset = 5
        let pos = TextPosition(string: str, index: str.index(str.startIndex, offsetBy: offset))
        let underlyingErrors = [
            ParseError.Expected("number")
        ]
        let err = ParseResult<Void>.Error(position: pos, underlyingErrors: underlyingErrors)
        let sut = ParseResult<Void>.failure(err)
        let expectedDescription = "Failure: Error in 1:\(offset+1)\n"
            + "\(str)\n"
            + "     ^\n"
            + "Expecting: number"
//        XCTAssertEqual(sut.description, expectedDescription)
    }
}



