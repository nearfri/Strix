
import XCTest
@testable import Strix

class ParsingResultTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func test_description_success() {
        let value = "hello world"
        let sut = ParsingResult.success(value)
        XCTAssertEqual(sut.description, "Success: \(value)")
    }
    
    func test_description_failure() {
        let str = "abcdefghi"
        let offset = 5
        let pos = CharacterPosition(string: str, index: str.index(str.startIndex, offsetBy: offset))
        let underlyingErrors = [
            ParsingError.Expected("number")
        ]
        let err = ParsingResult<Void>.Error(position: pos, underlyingErrors: underlyingErrors)
        let sut = ParsingResult<Void>.failure(err)
        let expectedDescription = "Failure: Error in 1:\(offset+1)\n"
            + "\(str)\n"
            + "     ^\n"
            + "Expecting: number"
        XCTAssertEqual(sut.description, expectedDescription)
    }
}



