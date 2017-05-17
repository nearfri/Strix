
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
        let str = "123456789"
        let offset = 5
        let pos = TextPosition(string: str, index: str.index(str.startIndex, offsetBy: offset))
        let underlyingErrors = [ParseError.Expected("alphabet")]
        let err = ParseResult<Void>.Error(position: pos, underlyingErrors: underlyingErrors)
        let sut = ParseResult<Void>.failure(err)
        let expectedDescription = "Failure: Error in 1:\(offset+1)\n"
            + "\(str)\n"
            + "     ^\n"
            + "Expecting: alphabet\n"
        XCTAssertEqual(sut.description, expectedDescription)
    }
}



