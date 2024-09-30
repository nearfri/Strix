import Testing
import Foundation
@testable import StrixParsers

enum JSONFixture {
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

@Suite struct JSONTests {
    @Test func data() throws {
        // Given
        let json: JSON = JSONFixture.windowJSON
        
        // When
        let data = json.data()
        
        // Then
        try #expect(JSONDecoder().decode(JSONFixture.Window.self, from: data) == JSONFixture.window)
    }
    
    @Test func data_topLevelString() throws {
        // Given
        let json: JSON = "hello"
        
        // When
        let data = json.data()
        
        // Then
        #expect(data == Data("\"hello\"".utf8))
    }
    
    @Test func jsonObject() throws {
        // Given
        let json: JSON = JSONFixture.windowJSON
        
        // When
        let jsonObject = json.jsonObject()
        
        // Then
        let data = try JSONSerialization.data(withJSONObject: jsonObject)
        try #expect(JSONDecoder().decode(JSONFixture.Window.self, from: data) == JSONFixture.window)
    }
    
    @Test func initWithData() throws {
        // Given
        let data = Data(JSONFixture.windowJSONString.utf8)
        
        // When
        let json = try JSON(data: data)
        
        // Then
        #expect(json == JSONFixture.windowJSON)
    }
    
    @Test func initWithJSONObject() throws {
        // Given
        let data = JSONFixture.windowJSONString.data(using: .utf8)!
        let jsonObj = try JSONSerialization.jsonObject(with: data)
        
        // When
        let json = try JSON(jsonObject: jsonObj)
        
        // Then
        #expect(json == JSONFixture.windowJSON)
    }
    
    @Test func dynamicMemberLookup_get() {
        #expect(JSONFixture.windowJSON.menu?.id?.stringValue == "menu-file")
        #expect(JSONFixture.windowJSON.menu?.isEnabled?.boolValue == false)
        #expect(JSONFixture.windowJSON.menu?.hasItem?.boolValue == true)
        #expect(JSONFixture.windowJSON.menu?.itemCount?.intValue == 3)
    }
    
    @Test func dynamicMemberLookup_set() {
        var json = JSONFixture.windowJSON
        json.menu?.id = .string("hello")
        #expect(json.menu?.id == "hello")
    }
    
    @Test func initWithBoolLiteral() {
        #expect(true == JSON.bool(true))
        #expect(false == JSON.bool(false))
    }
    
    @Test func initWithIntegerLiteral() {
        #expect(3 == JSON.number(3))
    }
    
    @Test func initWithFloatLiteral() {
        #expect(3.2 == JSON.number(3.2))
    }
    
    @Test func initWithStringLiteral() {
        #expect("hello" == JSON.string("hello"))
    }
    
    @Test func initWithArrayLiteral() {
        #expect(["hello", 3] == JSON.array([.string("hello"), .number(3)]))
        
        #expect([1, [1.1, nil as Double?]]
                == JSON.array([.number(1), JSON.array([.number(1.1), .null])]))
    }
    
    @Test func initWithDictionaryLiteral() {
        #expect(
            ["name": "Bradley", "age": 25]
            == JSON.dictionary(["name": .string("Bradley"), "age": .number(25)])
        )
        
        #expect(["a": 1, "b": ["b.1": 1.1, "b.2": nil as Double?]]
                == JSON.dictionary(["a": .number(1),
                                    "b": JSON.dictionary(["b.1": .number(1.1), "b.2": .null])]))
    }
    
    @Test func description_arrayType() {
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
        #expect(jsonDescription == jsonString)
    }
    
    @Test func description_complexType() {
        // Dictionary 타입은 순서 유지가 안되므로 재정렬 후 비교.
        let actual = JSONFixture.windowJSON.description
            .replacingOccurrences(of: ",", with: "")
            .split(separator: "\n")
            .sorted()
        
        let expected = JSONFixture.windowJSONString
            .replacingOccurrences(of: ",", with: "")
            .split(separator: "\n")
            .sorted()
        
        #expect(actual == expected)
    }
}
