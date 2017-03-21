
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
    
    func test_whenSetProperties_incrementsStateTag() {
        let string = "Bar"
        let stream = CharacterStream(string: string)
        
        XCTAssertEqual(stream.stateTag, 0)
        
        stream.userInfo["info1"] = 10
        XCTAssertEqual(stream.stateTag, 1)
        
        stream.userInfo = ["info2": 20]
        XCTAssertEqual(stream.stateTag, 2)
        
        stream.name = "StreamName"
        XCTAssertEqual(stream.stateTag, 3)
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
    
    func test_matchesCharacter() {
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
    
    func test_matchesCharacterPredicate() {
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
        XCTAssertFalse(stream.matches("Bar1", case: .sensitive))
        XCTAssertFalse(stream.matches("Bad", case: .sensitive))
        XCTAssertFalse(stream.matches("bar", case: .sensitive))
        XCTAssertFalse(stream.matches("b", case: .sensitive))
        
        stream.seek(to: string.index(after: string.startIndex))
        XCTAssertTrue(stream.matches("ar", case: .sensitive))
        XCTAssertTrue(stream.matches("a", case: .sensitive))
        XCTAssertFalse(stream.matches("ar1", case: .sensitive))
        XCTAssertFalse(stream.matches("Ar", case: .sensitive))
        XCTAssertFalse(stream.matches("A", case: .sensitive))
        
        stream.seek(to: stream.endIndex)
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
        XCTAssertFalse(stream.matches("Bar1", case: .insensitive))
        XCTAssertFalse(stream.matches("Bad", case: .insensitive))
        
        stream.seek(to: string.index(after: string.startIndex))
        XCTAssertTrue(stream.matches("ar", case: .insensitive))
        XCTAssertTrue(stream.matches("Ar", case: .insensitive))
        XCTAssertTrue(stream.matches("a", case: .insensitive))
        XCTAssertTrue(stream.matches("A", case: .insensitive))
        XCTAssertFalse(stream.matches("ar1", case: .insensitive))
        
        stream.seek(to: stream.endIndex)
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
    
    func test_skip() {
        let string = "Bar"
        let stream = CharacterStream(string: string)
        
        XCTAssertEqual(stream.peek(), "B")
        
        stream.skip()
        XCTAssertEqual(stream.peek(), "a")
        
        stream.skip()
        XCTAssertEqual(stream.peek(), "r")
        
        XCTAssertNotEqual(stream.nextIndex, stream.endIndex)
        stream.skip()
        XCTAssertNil(stream.peek())
        
        XCTAssertEqual(stream.nextIndex, stream.endIndex)
        stream.skip()
        XCTAssertEqual(stream.nextIndex, stream.endIndex)
        XCTAssertNil(stream.peek())
    }
    
    func test_skipCharacter() {
        let string = "Bar"
        let stream = CharacterStream(string: string)
        XCTAssertTrue(stream.skip("B"))
        XCTAssertFalse(stream.skip("B"))
        XCTAssertTrue(stream.skip("a"))
        XCTAssertTrue(stream.skip("r"))
        XCTAssertTrue(stream.isAtEnd)
    }
    
    func test_skipCharacterPredicate() {
        let string = "Bar"
        let stream = CharacterStream(string: string)
        XCTAssertTrue(stream.skip({ $0 == "B" }))
        XCTAssertFalse(stream.skip({ $0 == "B" }))
        XCTAssertTrue(stream.skip({ $0 == "a" }))
        XCTAssertTrue(stream.skip({ $0 == "r" }))
        XCTAssertTrue(stream.isAtEnd)
    }
    
    func test_skipString_caseSensitive() {
        let string = "Bar"
        let stream = CharacterStream(string: string)
        
        XCTAssertFalse(stream.skip("bar", case: .sensitive))
        XCTAssertFalse(stream.skip("BaR", case: .sensitive))
        XCTAssertTrue(stream.skip("Bar", case: .sensitive))
        XCTAssertFalse(stream.skip("Bar", case: .sensitive))
        XCTAssertTrue(stream.isAtEnd)
        
        stream.seek(to: stream.startIndex)
        XCTAssertTrue(stream.skip("Ba", case: .sensitive))
        XCTAssertTrue(stream.skip("r", case: .sensitive))
        XCTAssertTrue(stream.isAtEnd)
        
        stream.seek(to: string.index(after: string.startIndex))
        XCTAssertFalse(stream.skip("Ar", case: .sensitive))
        XCTAssertFalse(stream.skip("A", case: .sensitive))
        XCTAssertTrue(stream.skip("ar", case: .sensitive))
        XCTAssertTrue(stream.isAtEnd)

        stream.seek(to: stream.endIndex)
        XCTAssertFalse(stream.skip("r", case: .sensitive))
        XCTAssertFalse(stream.skip(" ", case: .sensitive))
        XCTAssertFalse(stream.skip("\0", case: .sensitive))
    }
    
    func test_skipString_caseInsensitive() {
        let string = "Bar"
        let stream = CharacterStream(string: string)
        
        XCTAssertTrue(stream.skip("baR", case: .insensitive))
        XCTAssertTrue(stream.isAtEnd)
        
        stream.seek(to: stream.startIndex)
        XCTAssertTrue(stream.skip("bA", case: .insensitive))
        XCTAssertTrue(stream.skip("R", case: .insensitive))
        XCTAssertTrue(stream.isAtEnd)
        
        stream.seek(to: string.index(after: string.startIndex))
        XCTAssertTrue(stream.skip("Ar", case: .insensitive))
        XCTAssertTrue(stream.isAtEnd)
        
        stream.seek(to: stream.endIndex)
        XCTAssertFalse(stream.skip("r", case: .insensitive))
        XCTAssertFalse(stream.skip(" ", case: .insensitive))
        XCTAssertFalse(stream.skip("\0", case: .insensitive))
    }
    
    func test_read() {
        let string = "Bar"
        let stream = CharacterStream(string: string)
        
        XCTAssertEqual(stream.read(), "B")
        XCTAssertEqual(stream.read(), "a")
        XCTAssertEqual(stream.read(), "r")
        XCTAssertNil(stream.read())
    }
    
    func test_readFrom() {
        let string = "FooBar"
        let stream = CharacterStream(string: string)
        
        stream.seek(to: stream.endIndex)
        XCTAssertEqual(stream.read(from: stream.startIndex), "FooBar")
        XCTAssertEqual(stream.read(from: string.index(after: string.startIndex)), "ooBar")
        XCTAssertEqual(stream.read(from: stream.endIndex), "")
        
        let indexOfB = string.index(string.startIndex, offsetBy: 3)
        stream.seek(to: indexOfB)
        XCTAssertEqual(stream.peek(), "B")
        XCTAssertEqual(stream.read(from: stream.startIndex), "Foo")
        XCTAssertEqual(stream.read(from: string.index(after: string.startIndex)), "oo")
        XCTAssertEqual(stream.read(from: indexOfB), "")
        
        stream.seek(to: stream.startIndex)
        XCTAssertEqual(stream.read(from: stream.startIndex), "")
    }
}



