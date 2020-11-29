import XCTest
@testable import StrixParsers

final class JSONParserTests: XCTestCase {
    func test_parse() throws {
        // Given
        let parser = JSONParser()
        
        // When
        let json = try parser.parse(JSONSeed.menuJSONString)
        
        // Then
        XCTAssertEqual(json, JSONSeed.menuJSON)
    }
}
