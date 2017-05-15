
import XCTest
@testable import Strix

class TextLineBufferTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func test_indent_string() {
        var indent = Indent(width: 4)
        
        XCTAssertEqual(indent.level, 0)
        XCTAssertEqual(indent.string, "")
        
        indent.level = 1
        XCTAssertEqual(indent.string, "    ")
        
        indent.level = 2
        XCTAssertEqual(indent.string, "        ")
    }
    
    func test_write() {
        let textBuffer = TextLineBuffer()
        
        textBuffer.write("hello")
        XCTAssertEqual(textBuffer.text, "hello")
        
        textBuffer.write(" world")
        XCTAssertEqual(textBuffer.text, "hello world")
    }
    
    func test_writeLine() {
        let textBuffer = TextLineBuffer()
        
        textBuffer.writeLine("hello")
        XCTAssertEqual(textBuffer.text, "hello\n")
        
        textBuffer.writeLine("world")
        XCTAssertEqual(textBuffer.text, "hello\nworld\n")
    }
    
    func test_writeLine_whenGivenIndent() {
        let textBuffer = TextLineBuffer()
        textBuffer.indent = Indent(width: 2)
        
        textBuffer.indent.level += 1
        textBuffer.writeLine("hello")
        XCTAssertEqual(textBuffer.text, "  hello\n")
        
        textBuffer.writeLine("world")
        XCTAssertEqual(textBuffer.text, "  hello\n  world\n")
        
        textBuffer.indent.level += 1
        textBuffer.writeLine("hi")
        XCTAssertEqual(textBuffer.text, "  hello\n  world\n    hi\n")
        
        textBuffer.writeLine("world")
        XCTAssertEqual(textBuffer.text, "  hello\n  world\n    hi\n    world\n")
    }
}



