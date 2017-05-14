
import XCTest
@testable import Strix

class TextPositionTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func test_compare() {
        let str0 = "abcd"
        let str1 = "efgh"
        
        let pos00 = TextPosition(string: str0, index: str0.startIndex)
        let pos01 = TextPosition(string: str0, index: str0.startIndex)
        let pos02 = TextPosition(string: str0, index: str0.index(str0.startIndex, offsetBy: 1))
        XCTAssertTrue(pos00 == pos01)
        XCTAssertTrue(pos00 < pos02)
        
        let pos10 = TextPosition(string: str1, index: str1.startIndex)
        XCTAssertFalse(pos00 == pos10)
        XCTAssertFalse(pos00 < pos10)
        XCTAssertFalse(pos00 > pos10)
    }
    
    func test_position() {
        let str = "abcd\nefgh\nijkl\n\nmnpq"
        
        for (column, i) in (0...4).enumerated() {
            let pos = TextPosition(string: str, index: str.index(str.startIndex, offsetBy: i))
            XCTAssertEqual(pos.lineNumber, 1)
            XCTAssertEqual(pos.columnNumber, column + 1)
            XCTAssertEqual(pos.substring, "abcd")
        }
        
        for (column, i) in (5...9).enumerated() {
            let pos = TextPosition(string: str, index: str.index(str.startIndex, offsetBy: i))
            XCTAssertEqual(pos.lineNumber, 2)
            XCTAssertEqual(pos.columnNumber, column + 1)
            XCTAssertEqual(pos.substring, "efgh")
        }
        
        for (column, i) in (10...14).enumerated() {
            let pos = TextPosition(string: str, index: str.index(str.startIndex, offsetBy: i))
            XCTAssertEqual(pos.lineNumber, 3)
            XCTAssertEqual(pos.columnNumber, column + 1)
            XCTAssertEqual(pos.substring, "ijkl")
        }
        
        for (column, i) in (15...15).enumerated() {
            let pos = TextPosition(string: str, index: str.index(str.startIndex, offsetBy: i))
            XCTAssertEqual(pos.lineNumber, 4)
            XCTAssertEqual(pos.columnNumber, column + 1)
            XCTAssertEqual(pos.substring, "")
        }
        
        for (column, i) in (16...20).enumerated() {
            let pos = TextPosition(string: str, index: str.index(str.startIndex, offsetBy: i))
            XCTAssertEqual(pos.lineNumber, 5)
            XCTAssertEqual(pos.columnNumber, column + 1)
            XCTAssertEqual(pos.substring, "mnpq")
        }
        
        XCTAssertEqual(str.index(str.startIndex, offsetBy: 20), str.endIndex)
    }
    
    func test_position_emptyString() {
        let str = ""
        let pos = TextPosition(string: str, index: str.startIndex)
        XCTAssertEqual(pos.lineNumber, 1)
        XCTAssertEqual(pos.columnNumber, 1)
        XCTAssertEqual(pos.substring, "")
    }
    
    func test_position_surroundedWithNewline() {
        let str = "\nabcd\nefgh\n"
        
        for (column, i) in (0...0).enumerated() {
            let pos = TextPosition(string: str, index: str.index(str.startIndex, offsetBy: i))
            XCTAssertEqual(pos.lineNumber, 1)
            XCTAssertEqual(pos.columnNumber, column + 1)
            XCTAssertEqual(pos.substring, "")
        }
        
        for (column, i) in (1...5).enumerated() {
            let pos = TextPosition(string: str, index: str.index(str.startIndex, offsetBy: i))
            XCTAssertEqual(pos.lineNumber, 2)
            XCTAssertEqual(pos.columnNumber, column + 1)
            XCTAssertEqual(pos.substring, "abcd")
        }
        
        for (column, i) in (6...11).enumerated() {
            let pos = TextPosition(string: str, index: str.index(str.startIndex, offsetBy: i))
            XCTAssertEqual(pos.lineNumber, 3)
            XCTAssertEqual(pos.columnNumber, column + 1)
            XCTAssertEqual(pos.substring, "efgh")
        }
        
        XCTAssertEqual(str.index(str.startIndex, offsetBy: 11), str.endIndex)
    }
    
    func test_position_surroundedWithNewlines() {
        let str = "\n\nabcd\n\n\n"
        
        for (column, i) in (0...0).enumerated() {
            let pos = TextPosition(string: str, index: str.index(str.startIndex, offsetBy: i))
            XCTAssertEqual(pos.lineNumber, 1)
            XCTAssertEqual(pos.columnNumber, column + 1)
            XCTAssertEqual(pos.substring, "")
        }
        
        for (column, i) in (1...1).enumerated() {
            let pos = TextPosition(string: str, index: str.index(str.startIndex, offsetBy: i))
            XCTAssertEqual(pos.lineNumber, 2)
            XCTAssertEqual(pos.columnNumber, column + 1)
            XCTAssertEqual(pos.substring, "")
        }
        
        for (column, i) in (2...6).enumerated() {
            let pos = TextPosition(string: str, index: str.index(str.startIndex, offsetBy: i))
            XCTAssertEqual(pos.lineNumber, 3)
            XCTAssertEqual(pos.columnNumber, column + 1)
            XCTAssertEqual(pos.substring, "abcd")
        }
        
        for (column, i) in (7...7).enumerated() {
            let pos = TextPosition(string: str, index: str.index(str.startIndex, offsetBy: i))
            XCTAssertEqual(pos.lineNumber, 4)
            XCTAssertEqual(pos.columnNumber, column + 1)
            XCTAssertEqual(pos.substring, "")
        }
        
        for (column, i) in (8...9).enumerated() {
            let pos = TextPosition(string: str, index: str.index(str.startIndex, offsetBy: i))
            XCTAssertEqual(pos.lineNumber, 5)
            XCTAssertEqual(pos.columnNumber, column + 1)
            XCTAssertEqual(pos.substring, "")
        }
        
        XCTAssertEqual(str.index(str.startIndex, offsetBy: 9), str.endIndex)
    }
    
    func test_columnMarker_normal() {
        let str = "1234567890"
        let cmk = "    ^"
        let column = 5
        let index = str.index(str.startIndex, offsetBy: column-1)
        XCTAssertEqual(str[index], "5")
        let pos = TextPosition(string: str, index: index)
        XCTAssertEqual(pos.columnMarker, cmk)
    }
    
    func test_columnMarker_startsWithTab() {
        let str = "\t234567890"
        let cmk = "\t   ^"
        let column = 5
        let index = str.index(str.startIndex, offsetBy: column-1)
        XCTAssertEqual(str[index], "5")
        let pos = TextPosition(string: str, index: index)
        XCTAssertEqual(pos.columnMarker, cmk)
    }
    
    func test_columnMarker_startsWithSpace() {
        let str = " 234567890"
        let cmk = "    ^"
        let column = 5
        let index = str.index(str.startIndex, offsetBy: column-1)
        XCTAssertEqual(str[index], "5")
        let pos = TextPosition(string: str, index: index)
        XCTAssertEqual(pos.columnMarker, cmk)
    }
    
    func test_columnMarker_startsWithControlCharacter() {
        let str = "\u{14}\u{15}34567890"
        //        "34567890"
        let cmk = "  ^"
        let column = 5
        let index = str.index(str.startIndex, offsetBy: column-1)
        XCTAssertEqual(str[index], "5")
        let pos = TextPosition(string: str, index: index)
        XCTAssertEqual(pos.columnMarker, cmk)
    }
    
    func test_columnMarker_startsWithHangul() {
        let str = "한글34567890"
        let column = 5
        let index = str.index(str.startIndex, offsetBy: column-1)
        XCTAssertEqual(str[index], "5")
        let pos = TextPosition(string: str, index: index)
        XCTAssertNil(pos.columnMarker)
    }
    
    func test_columnMarker_endsWithHangul() {
        let str = "1234567890한글"
        let cmk = "    ^"
        let column = 5
        let index = str.index(str.startIndex, offsetBy: column-1)
        XCTAssertEqual(str[index], "5")
        let pos = TextPosition(string: str, index: index)
        XCTAssertEqual(pos.columnMarker, cmk)
    }
    
    func test_columnMarker_emptyString() {
        let str = ""
        let cmk = "^"
        let index = str.startIndex
        let pos = TextPosition(string: str, index: index)
        XCTAssertEqual(pos.columnMarker, cmk)
    }
}



