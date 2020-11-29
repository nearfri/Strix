import XCTest
@testable import StrixParsers

enum JSONSeed {
    static let menuJSONString = """
    {
        "menu": {
            "id": "menu-file",
            "value": "File",
            "superMenu": null,
            "isEnabled": false,
            "groupCount": 0,
            "height": 50.5,
            "hasItem": true,
            "itemCount": 3,
            "items": [
                {
                    "value": "New",
                    "onclick": "CreateNewDoc()"
                },
                {
                    "value": "Open",
                    "onclick": "OpenDoc()"
                },
                {
                    "value": "Close",
                    "onclick": "CloseDoc()"
                }
            ]
        }
    }
    """
    
    static let menuJSON: JSON = .object([
        "menu": .object([
            "id": .string("menu-file"),
            "value": .string("File"),
            "superMenu": .null,
            "isEnabled": .bool(false),
            "groupCount": .number(0),
            "height": .number(50.5),
            "hasItem": .bool(true),
            "itemCount": .number(3),
            "items": .array([
                .object(["value": .string("New"), "onclick": .string("CreateNewDoc()")]),
                .object(["value": .string("Open"), "onclick": .string("OpenDoc()")]),
                .object(["value": .string("Close"), "onclick": .string("CloseDoc()")])
            ])
        ])
    ])
}

final class JSONTests: XCTestCase {
    func test_initWithData() throws {
        // Given
        let data = JSONSeed.menuJSONString.data(using: .utf8)!
        
        // When
        let json = try JSON(data: data)
        
        // Then
        XCTAssertEqual(json, JSONSeed.menuJSON)
    }
    
    func test_initWithJSONObject() throws {
        // Given
        let data = JSONSeed.menuJSONString.data(using: .utf8)!
        let jsonObj = try JSONSerialization.jsonObject(with: data)
        
        // When
        let json = try JSON(jsonObject: jsonObj)
        
        // Then
        XCTAssertEqual(json, JSONSeed.menuJSON)
    }
    
    func test_dynamicMemberLookup() {
        XCTAssertEqual(JSONSeed.menuJSON.menu?.id?.stringValue, "menu-file")
        XCTAssertEqual(JSONSeed.menuJSON.menu?.isEnabled?.boolValue, false)
        XCTAssertEqual(JSONSeed.menuJSON.menu?.hasItem?.boolValue, true)
        XCTAssertEqual(JSONSeed.menuJSON.menu?.itemCount?.intValue, 3)
    }
    
    func test_initWithBoolLiteral() {
        XCTAssertEqual(true, JSON.bool(true))
        XCTAssertEqual(false, JSON.bool(false))
        XCTAssertNotEqual(true, JSON.bool(false))
    }
    
    func test_initWithIntegerLiteral() {
        XCTAssertEqual(3, JSON.number(3))
        XCTAssertNotEqual(3, JSON.number(4))
    }
    
    func test_initWithFloatLiteral() {
        XCTAssertEqual(3.2, JSON.number(3.2))
        XCTAssertNotEqual(3.2, JSON.number(4.5))
    }
    
    func test_initWithStringLiteral() {
        XCTAssertEqual("hello", JSON.string("hello"))
        XCTAssertNotEqual("hello", JSON.string("world"))
    }
    
    func test_initWithArrayLiteral() {
        XCTAssertEqual(["hello", 3], JSON.array([.string("hello"), .number(3)]))
        XCTAssertNotEqual([3, "hello"], JSON.array([.string("hello"), .number(3)]))
    }
    
    func test_initWithDictionaryLiteral() {
        XCTAssertEqual(
            ["name": "naver", "category": "IT"],
            JSON.object(["name": .string("naver"), "category": .string("IT")])
        )
    }
    
    func test_description_arrayType() {
        // Given
        let jsonString = """
        [
            1,
            2,
            3,
            4
        ]
        """
        
        let json: JSON = [1, 2, 3, 4]
        
        // When
        let jsonDescription = json.description
        
        // Then
        XCTAssertEqual(jsonDescription, jsonString)
    }
    
    func test_description_complexType() {
        // Dictionary 타입은 순서 유지가 안되므로 재정렬 후 비교.
        let actual = JSONSeed.menuJSON.description
            .replacingOccurrences(of: ",", with: "")
            .split(separator: "\n")
            .sorted()
        
        let expected = JSONSeed.menuJSONString
            .replacingOccurrences(of: ",", with: "")
            .split(separator: "\n")
            .sorted()
        
        XCTAssertEqual(actual, expected)
    }
}
