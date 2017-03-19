
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
        let string = "Foo"
        let bounds = string.startIndex..<string.index(before: string.endIndex)
        let stream = CharacterStream(string: string, bounds: bounds)
        XCTAssertEqual(stream.string, string)
        XCTAssertEqual(stream.startIndex, bounds.lowerBound)
        XCTAssertEqual(stream.endIndex, bounds.upperBound)
        XCTAssertEqual(stream.nextIndex, bounds.lowerBound)
    }
    
    func test_init_whenNotGivenBounds() {
        let string = "Foo"
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
        let string = "Foo"
        let stream = CharacterStream(string: string)
        
        XCTAssertEqual(stream.peek(), "F")
        
        stream.seek(to: string.index(after: string.startIndex))
        XCTAssertEqual(stream.peek(), "o")
        
        stream.seek(to: stream.endIndex)
        XCTAssertNil(stream.peek())
    }
    
    func test_peekOffset() {
        let string = "Foo"
        let stream = CharacterStream(string: string)
        
        XCTAssertNil(stream.peek(offset: -1))
        XCTAssertNil(stream.peek(offset: -2))
        XCTAssertEqual(stream.peek(offset: 0), "F")
        XCTAssertEqual(stream.peek(offset: 1), "o")
        XCTAssertEqual(stream.peek(offset: 2), "o")
        XCTAssertNil(stream.peek(offset: 3))
        XCTAssertNil(stream.peek(offset: 4))
        
        stream.seek(to: stream.endIndex)
        XCTAssertNil(stream.peek(offset: -5))
        XCTAssertNil(stream.peek(offset: -4))
        XCTAssertEqual(stream.peek(offset: -3), "F")
        XCTAssertEqual(stream.peek(offset: -2), "o")
        XCTAssertEqual(stream.peek(offset: -1), "o")
        XCTAssertNil(stream.peek(offset: 0))
        XCTAssertNil(stream.peek(offset: 1))
    }
}



