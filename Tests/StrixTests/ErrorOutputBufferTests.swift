
import XCTest
@testable import Strix

class ErrorOutputBufferTests: XCTestCase {
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
        var outputBuffer = ErrorOutputBuffer()
        
        outputBuffer.write("hello")
        XCTAssertEqual(outputBuffer.text, "hello")
        
        outputBuffer.write(" world")
        XCTAssertEqual(outputBuffer.text, "hello world")
    }
    
    func test_writeLine() {
        var outputBuffer = ErrorOutputBuffer()
        
        outputBuffer.writeLine("hello")
        XCTAssertEqual(outputBuffer.text, "hello\n")
        
        outputBuffer.writeLine("world")
        XCTAssertEqual(outputBuffer.text, "hello\nworld\n")
        
        outputBuffer.writeLine()
        XCTAssertEqual(outputBuffer.text, "hello\nworld\n\n")
    }
    
    func test_writeLine_whenGivenIndent() {
        var outputBuffer = ErrorOutputBuffer()
        outputBuffer.indent = Indent(width: 2)
        
        outputBuffer.indent.level += 1
        outputBuffer.writeLine("hello")
        XCTAssertEqual(outputBuffer.text, "  hello\n")
        
        outputBuffer.writeLine("world")
        XCTAssertEqual(outputBuffer.text, "  hello\n  world\n")
        
        outputBuffer.writeLine()
        XCTAssertEqual(outputBuffer.text, "  hello\n  world\n  \n")
        
        outputBuffer.indent.level += 1
        outputBuffer.writeLine("hi")
        XCTAssertEqual(outputBuffer.text, "  hello\n  world\n  \n    hi\n")
        
        outputBuffer.writeLine("world")
        XCTAssertEqual(outputBuffer.text, "  hello\n  world\n  \n    hi\n    world\n")
    }
}



