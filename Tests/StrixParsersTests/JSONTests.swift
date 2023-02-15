import XCTest
@testable import StrixParsers

enum JSONSeed {
    struct Window: Codable, Equatable {
        struct Menu: Codable, Equatable {
            struct Item: Codable, Equatable {
                var value: String
                var onClick: String
            }
            
            let id: String
            var value: String
            var description: String?
            var isEnabled: Bool
            var groupCount: Int
            var height: Double
            var hasItem: Bool
            var itemCount: Int
            var items: [Item]
        }
        
        var menu: Menu
    }
    
    static let window = Window(
        menu: Window.Menu(
            id: "menu-file",
            value: "File",
            description: nil,
            isEnabled: false,
            groupCount: 0,
            height: 50.5,
            hasItem: true,
            itemCount: 3,
            items: [
                Window.Menu.Item(value: "New", onClick: "createNewDoc()"),
                Window.Menu.Item(value: "Open", onClick: "openDoc()"),
                Window.Menu.Item(value: "Close", onClick: "closeDoc()")
            ]
        )
    )
    
    static let windowJSONString = """
    {
        "menu": {
            "id": "menu-file",
            "value": "File",
            "description": null,
            "isEnabled": false,
            "groupCount": 0,
            "height": 50.5,
            "hasItem": true,
            "itemCount": 3,
            "items": [
                {
                    "value": "New",
                    "onClick": "createNewDoc()"
                },
                {
                    "value": "Open",
                    "onClick": "openDoc()"
                },
                {
                    "value": "Close",
                    "onClick": "closeDoc()"
                }
            ]
        }
    }
    """
    
    static let windowJSON: JSON = .dictionary([
        "menu": .dictionary([
            "id": .string("menu-file"),
            "value": .string("File"),
            "description": .null,
            "isEnabled": .bool(false),
            "groupCount": .number(0),
            "height": .number(50.5),
            "hasItem": .bool(true),
            "itemCount": .number(3),
            "items": .array([
                .dictionary(["value": .string("New"), "onClick": .string("createNewDoc()")]),
                .dictionary(["value": .string("Open"), "onClick": .string("openDoc()")]),
                .dictionary(["value": .string("Close"), "onClick": .string("closeDoc()")])
            ])
        ])
    ])
}

final class JSONTests: XCTestCase {
    func test_data() throws {
        // Given
        let json: JSON = JSONSeed.windowJSON
        
        // When
        let data = json.data()
        
        // Then
        XCTAssertEqual(try JSONDecoder().decode(JSONSeed.Window.self, from: data), JSONSeed.window)
    }
    
    func test_data_topLevelString() throws {
        // Given
        let json: JSON = "hello"
        
        // When
        let data = json.data()
        
        // Then
        XCTAssertEqual(data, Data("\"hello\"".utf8))
    }
    
    func test_jsonObject() throws {
        // Given
        let json: JSON = JSONSeed.windowJSON
        
        // When
        let jsonObject = json.jsonObject()
        
        // Then
        let data = try JSONSerialization.data(withJSONObject: jsonObject)
        XCTAssertEqual(try JSONDecoder().decode(JSONSeed.Window.self, from: data), JSONSeed.window)
    }
    
    func test_initWithData() throws {
        // Given
        let data = Data(JSONSeed.windowJSONString.utf8)
        
        // When
        let json = try JSON(data: data)
        
        // Then
        XCTAssertEqual(json, JSONSeed.windowJSON)
    }
    
    func test_initWithJSONObject() throws {
        // Given
        let data = JSONSeed.windowJSONString.data(using: .utf8)!
        let jsonObj = try JSONSerialization.jsonObject(with: data)
        
        // When
        let json = try JSON(jsonObject: jsonObj)
        
        // Then
        XCTAssertEqual(json, JSONSeed.windowJSON)
    }
    
    func test_dynamicMemberLookup_get() {
        XCTAssertEqual(JSONSeed.windowJSON.menu?.id?.stringValue, "menu-file")
        XCTAssertEqual(JSONSeed.windowJSON.menu?.isEnabled?.boolValue, false)
        XCTAssertEqual(JSONSeed.windowJSON.menu?.hasItem?.boolValue, true)
        XCTAssertEqual(JSONSeed.windowJSON.menu?.itemCount?.intValue, 3)
    }
    
    func test_dynamicMemberLookup_set() {
        var json = JSONSeed.windowJSON
        json.menu?.id = .string("hello")
        XCTAssertEqual(json.menu?.id, "hello")
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
        
        XCTAssertEqual([1, [1.1, nil as Double?]],
                       JSON.array([.number(1), JSON.array([.number(1.1), .null])]))
    }
    
    func test_initWithDictionaryLiteral() {
        XCTAssertEqual(
            ["name": "Bradley", "age": 25],
            JSON.dictionary(["name": .string("Bradley"), "age": .number(25)])
        )
        XCTAssertNotEqual(
            ["name": "Bradley", "age": 25],
            JSON.dictionary(["name": .string("Bradley"), "age": .string("25")])
        )
        
        XCTAssertEqual(["a": 1, "b": ["b.1": 1.1, "b.2": nil as Double?]],
                       JSON.dictionary(["a": .number(1),
                                        "b": JSON.dictionary(["b.1": .number(1.1), "b.2": .null])]))
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
        let actual = JSONSeed.windowJSON.description
            .replacingOccurrences(of: ",", with: "")
            .split(separator: "\n")
            .sorted()
        
        let expected = JSONSeed.windowJSONString
            .replacingOccurrences(of: ",", with: "")
            .split(separator: "\n")
            .sorted()
        
        XCTAssertEqual(actual, expected)
    }
}
