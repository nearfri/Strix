
import XCTest
@testable import Strix

class CharacterStreamTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func test_init_whenGivenBounds() {
        let string = "Bar"
        let bounds = string.startIndex..<string.index(before: string.endIndex)
        let stream = CharacterStream(string: string, bounds: bounds)
        XCTAssertEqual(stream.string, string)
        XCTAssertEqual(stream.startIndex, bounds.lowerBound)
        XCTAssertEqual(stream.endIndex, bounds.upperBound)
        XCTAssertEqual(stream.nextIndex, bounds.lowerBound)
    }
    
    func test_init_whenNotGivenBounds() {
        let string = "Bar"
        let stream = CharacterStream(string: string)
        XCTAssertEqual(stream.string, string)
        XCTAssertEqual(stream.startIndex, string.startIndex)
        XCTAssertEqual(stream.endIndex, string.endIndex)
        XCTAssertEqual(stream.nextIndex, string.startIndex)
    }
    
    func test_seek() {
        let string = "Foo"
        let stream = CharacterStream(string: string)
        
        stream.seek(to: stream.endIndex)
        XCTAssertEqual(stream.nextIndex, stream.endIndex)
        XCTAssertTrue(stream.isAtEnd)
        
        stream.seek(to: stream.startIndex)
        XCTAssertEqual(stream.nextIndex, stream.startIndex)
        XCTAssertTrue(stream.isAtStart)
        
        let anyIndex = string.index(after: string.startIndex)
        stream.seek(to: anyIndex)
        XCTAssertEqual(stream.nextIndex, anyIndex)
    }
    
    func test_peek() {
        let string = "Bar"
        let stream = CharacterStream(string: string)
        
        XCTAssertEqual(stream.peek(), "B")
        
        stream.seek(to: string.index(after: string.startIndex))
        XCTAssertEqual(stream.peek(), "a")
        
        stream.seek(to: stream.endIndex)
        XCTAssertNil(stream.peek())
    }
    
    func test_peekOffset() {
        let string = "Bar"
        let stream = CharacterStream(string: string)
        
        XCTAssertNil(stream.peek(offset: -1))
        XCTAssertNil(stream.peek(offset: -2))
        XCTAssertEqual(stream.peek(offset: 0), "B")
        XCTAssertEqual(stream.peek(offset: 1), "a")
        XCTAssertEqual(stream.peek(offset: 2), "r")
        XCTAssertNil(stream.peek(offset: 3))
        XCTAssertNil(stream.peek(offset: 4))
        
        stream.seek(to: stream.endIndex)
        XCTAssertNil(stream.peek(offset: -5))
        XCTAssertNil(stream.peek(offset: -4))
        XCTAssertEqual(stream.peek(offset: -3), "B")
        XCTAssertEqual(stream.peek(offset: -2), "a")
        XCTAssertEqual(stream.peek(offset: -1), "r")
        XCTAssertNil(stream.peek(offset: 0))
        XCTAssertNil(stream.peek(offset: 1))
    }
    
    func test_matchesChar() {
        let string = "Bar"
        let stream = CharacterStream(string: string)
        
        XCTAssertTrue(stream.matches("B"))
        XCTAssertFalse(stream.matches("a"))
        
        stream.seek(to: string.index(after: string.startIndex))
        XCTAssertTrue(stream.matches("a"))
        
        stream.seek(to: string.index(before: string.endIndex))
        XCTAssertTrue(stream.matches("r"))
        
        stream.seek(to: stream.endIndex)
        XCTAssertFalse(stream.matches("r"))
    }
    
    func test_matchesCharPredicate() {
        let string = "Bar"
        let stream = CharacterStream(string: string)
        
        stream.seek(to: stream.startIndex)
        XCTAssertTrue(stream.matches({ $0 == "B" }))
        XCTAssertFalse(stream.matches({ $0 == "a" }))
        
        stream.seek(to: string.index(after: string.startIndex))
        XCTAssertTrue(stream.matches({ $0 == "a" }))
        XCTAssertTrue(stream.matches({ $0 != "B" }))
        XCTAssertFalse(stream.matches({ $0 == "B" }))
        
        stream.seek(to: string.index(before: string.endIndex))
        XCTAssertTrue(stream.matches({ $0 == "r" }))
        XCTAssertFalse(stream.matches({ $0 == "a" }))
        
        stream.seek(to: stream.endIndex)
        XCTAssertFalse(stream.matches({ _ in
            XCTFail("should not be called")
            return true
        }))
    }
    
    func test_matchesString_caseSensitive() {
        let string = "Bar"
        let stream = CharacterStream(string: string)
        
        XCTAssertTrue(stream.matches("Bar", case: .sensitive))
        XCTAssertTrue(stream.matches("B", case: .sensitive))
        XCTAssertTrue(stream.matches("", case: .sensitive))
        XCTAssertFalse(stream.matches("Bar1", case: .sensitive))
        XCTAssertFalse(stream.matches("Bad", case: .sensitive))
        XCTAssertFalse(stream.matches("bar", case: .sensitive))
        XCTAssertFalse(stream.matches("b", case: .sensitive))
        
        stream.seek(to: string.index(after: string.startIndex))
        XCTAssertTrue(stream.matches("ar", case: .sensitive))
        XCTAssertTrue(stream.matches("a", case: .sensitive))
        XCTAssertTrue(stream.matches("", case: .sensitive))
        XCTAssertFalse(stream.matches("ar1", case: .sensitive))
        XCTAssertFalse(stream.matches("Ar", case: .sensitive))
        XCTAssertFalse(stream.matches("A", case: .sensitive))
        
        stream.seek(to: stream.endIndex)
        XCTAssertTrue(stream.matches("", case: .sensitive))
        XCTAssertFalse(stream.matches("r", case: .sensitive))
        XCTAssertFalse(stream.matches(" ", case: .sensitive))
        XCTAssertFalse(stream.matches("\0", case: .sensitive))
    }
    
    func test_matchesString_caseInsensitive() {
        let string = "Bar"
        let stream = CharacterStream(string: string)
        
        XCTAssertTrue(stream.matches("Bar", case: .insensitive))
        XCTAssertTrue(stream.matches("bar", case: .insensitive))
        XCTAssertTrue(stream.matches("bAR", case: .insensitive))
        XCTAssertTrue(stream.matches("B", case: .insensitive))
        XCTAssertTrue(stream.matches("b", case: .insensitive))
        XCTAssertTrue(stream.matches("", case: .insensitive))
        XCTAssertFalse(stream.matches("Bar1", case: .insensitive))
        XCTAssertFalse(stream.matches("Bad", case: .insensitive))
        
        stream.seek(to: string.index(after: string.startIndex))
        XCTAssertTrue(stream.matches("ar", case: .insensitive))
        XCTAssertTrue(stream.matches("Ar", case: .insensitive))
        XCTAssertTrue(stream.matches("a", case: .insensitive))
        XCTAssertTrue(stream.matches("A", case: .insensitive))
        XCTAssertTrue(stream.matches("", case: .insensitive))
        XCTAssertFalse(stream.matches("ar1", case: .insensitive))
        
        stream.seek(to: stream.endIndex)
        XCTAssertTrue(stream.matches("", case: .insensitive))
        XCTAssertFalse(stream.matches("r", case: .insensitive))
        XCTAssertFalse(stream.matches(" ", case: .insensitive))
        XCTAssertFalse(stream.matches("\0", case: .insensitive))
    }
    
    func test_matches_regex() {
        let string = "FooBarSwift3"
        let stream = CharacterStream(string: string)
        
        XCTAssertNil(stream.matches(try! NSRegularExpression(pattern: "^a[a-zA-Z]+", options: [])))
        
        let regex = try! NSRegularExpression(pattern: "a[a-zA-Z]+", options: [])
        if let checkingResult = stream.matches(regex) {
            let matchedStr = (string as NSString).substring(with: checkingResult.range) as String
            XCTAssertEqual(matchedStr, "arSwift")
        } else {
            XCTFail("regex not matched")
        }
    }
}



