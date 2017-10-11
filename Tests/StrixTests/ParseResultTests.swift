
import XCTest
@testable import Strix

class ParseResultTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func test_getValue() {
        XCTAssertEqual(ParseResult.success(3).value, 3)
        
        let error = ParseResult<Void>.Error(position: CharacterStream(string: "").position,
                                            underlyingErrors: [])
        XCTAssertNil(ParseResult.failure(error).value)
    }
    
    func test_getError() {
        XCTAssertNil(ParseResult.success(3).error)
        
        let position = CharacterStream(string: "").position
        
        let underlyingErrors: [DummyError] = [
            DummyError.err0,
            DummyError.err1,
            DummyError.err2
        ]
        
        let error = ParseResult<Int>.Error(position: position, underlyingErrors: underlyingErrors)
        
        XCTAssertEqual(ParseResult.failure(error).error?.position, position)
        XCTAssertEqual(ParseResult.failure(error).error?.underlyingErrors as! [DummyError],
                       underlyingErrors)
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
        let expectedDescription = """
        Failure: Error in 1:\(offset+1)
        \(str)
             ^
        Expecting: alphabet
        
        """
        XCTAssertEqual(sut.description, expectedDescription)
    }
}



