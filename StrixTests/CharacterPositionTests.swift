
import XCTest
@testable import Strix

class CharacterPositionTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func test_compare() {
        let str0 = "abcd"
        let str1 = "efgh"
        
        let pos00 = CharacterPosition(string: str0, index: str0.startIndex)
        let pos01 = CharacterPosition(string: str0, index: str0.startIndex)
        let pos02 = CharacterPosition(string: str0, index: str0.index(str0.startIndex, offsetBy: 1))
        XCTAssertTrue(pos00 == pos01)
        XCTAssertTrue(pos00 < pos02)
        
        let pos10 = CharacterPosition(string: str1, index: str1.startIndex)
        XCTAssertFalse(pos00 == pos10)
        XCTAssertFalse(pos00 < pos10)
        XCTAssertFalse(pos00 > pos10)
    }
    
    func test_position() {
        let str = "abcd\nefgh\nijkl\n\nmnpq"
        
        for (column, i) in (0...4).enumerated() {
            let pos = CharacterPosition(string: str, index: str.index(str.startIndex, offsetBy: i))
            XCTAssertEqual(pos.line, 0)
            XCTAssertEqual(pos.column, column)
            XCTAssertEqual(pos.substring, "abcd")
        }
        
        for (column, i) in (5...9).enumerated() {
            let pos = CharacterPosition(string: str, index: str.index(str.startIndex, offsetBy: i))
            XCTAssertEqual(pos.line, 1)
            XCTAssertEqual(pos.column, column)
            XCTAssertEqual(pos.substring, "efgh")
        }
        
        for (column, i) in (10...14).enumerated() {
            let pos = CharacterPosition(string: str, index: str.index(str.startIndex, offsetBy: i))
            XCTAssertEqual(pos.line, 2)
            XCTAssertEqual(pos.column, column)
            XCTAssertEqual(pos.substring, "ijkl")
        }
        
        for (column, i) in (15...15).enumerated() {
            let pos = CharacterPosition(string: str, index: str.index(str.startIndex, offsetBy: i))
            XCTAssertEqual(pos.line, 3)
            XCTAssertEqual(pos.column, column)
            XCTAssertEqual(pos.substring, "")
        }
        
        for (column, i) in (16...20).enumerated() {
            let pos = CharacterPosition(string: str, index: str.index(str.startIndex, offsetBy: i))
            XCTAssertEqual(pos.line, 4)
            XCTAssertEqual(pos.column, column)
            XCTAssertEqual(pos.substring, "mnpq")
        }
        
        XCTAssertEqual(str.index(str.startIndex, offsetBy: 20), str.endIndex)
    }
    
    func test_position_surroundedWithNewline() {
        let str = "\nabcd\nefgh\n"
        
        for (column, i) in (0...0).enumerated() {
            let pos = CharacterPosition(string: str, index: str.index(str.startIndex, offsetBy: i))
            XCTAssertEqual(pos.line, 0)
            XCTAssertEqual(pos.column, column)
            XCTAssertEqual(pos.substring, "")
        }
        
        for (column, i) in (1...5).enumerated() {
            let pos = CharacterPosition(string: str, index: str.index(str.startIndex, offsetBy: i))
            XCTAssertEqual(pos.line, 1)
            XCTAssertEqual(pos.column, column)
            XCTAssertEqual(pos.substring, "abcd")
        }
        
        for (column, i) in (6...11).enumerated() {
            let pos = CharacterPosition(string: str, index: str.index(str.startIndex, offsetBy: i))
            XCTAssertEqual(pos.line, 2)
            XCTAssertEqual(pos.column, column)
            XCTAssertEqual(pos.substring, "efgh")
        }
        
        XCTAssertEqual(str.index(str.startIndex, offsetBy: 11), str.endIndex)
    }
    
    func test_position_surroundedWithNewlines() {
        let str = "\n\nabcd\n\n\n"
        
        for (column, i) in (0...0).enumerated() {
            let pos = CharacterPosition(string: str, index: str.index(str.startIndex, offsetBy: i))
            XCTAssertEqual(pos.line, 0)
            XCTAssertEqual(pos.column, column)
            XCTAssertEqual(pos.substring, "")
        }
        
        for (column, i) in (1...1).enumerated() {
            let pos = CharacterPosition(string: str, index: str.index(str.startIndex, offsetBy: i))
            XCTAssertEqual(pos.line, 1)
            XCTAssertEqual(pos.column, column)
            XCTAssertEqual(pos.substring, "")
        }
        
        for (column, i) in (2...6).enumerated() {
            let pos = CharacterPosition(string: str, index: str.index(str.startIndex, offsetBy: i))
            XCTAssertEqual(pos.line, 2)
            XCTAssertEqual(pos.column, column)
            XCTAssertEqual(pos.substring, "abcd")
        }
        
        for (column, i) in (7...7).enumerated() {
            let pos = CharacterPosition(string: str, index: str.index(str.startIndex, offsetBy: i))
            XCTAssertEqual(pos.line, 3)
            XCTAssertEqual(pos.column, column)
            XCTAssertEqual(pos.substring, "")
        }
        
        for (column, i) in (8...9).enumerated() {
            let pos = CharacterPosition(string: str, index: str.index(str.startIndex, offsetBy: i))
            XCTAssertEqual(pos.line, 4)
            XCTAssertEqual(pos.column, column)
            XCTAssertEqual(pos.substring, "")
        }
        
        XCTAssertEqual(str.index(str.startIndex, offsetBy: 9), str.endIndex)
    }
}



