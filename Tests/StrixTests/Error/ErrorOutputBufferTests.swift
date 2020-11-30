import XCTest
@testable import Strix

final class ErrorOutputBufferTests: XCTestCase {
    var sut: ErrorOutputBuffer = .init()
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        sut = .init()
        sut.indent.width = 4
    }
    
    func test_write_singleLine() {
        // Given
        let input = "hello world"
        
        // When
        print(input, terminator: "", to: &sut)
        
        // Then
        XCTAssertEqual(sut.text, input)
    }
    
    func test_write_multipleLine() {
        // Given
        let input = """
        hello
            swift
        world
        """
        
        // When
        print(input, terminator: "", to: &sut)
        
        // Then
        XCTAssertEqual(sut.text, input)
    }
    
    func test_write_repeat() {
        // Given
        let lines: [String] = [
            "hello",
            "    swift",
            "world",
        ]
        
        // When
        for line in lines {
            print(line, to: &sut)
        }
        
        // Then
        XCTAssertEqual(sut.text, "hello\n" + "    swift\n" + "world\n")
    }
    
    func test_write_withoutTerminator() {
        // When
        print("hello ", terminator: "", to: &sut)
        print("swift", terminator: "", to: &sut)
        print(" world", terminator: "", to: &sut)
        
        // Then
        XCTAssertEqual(sut.text, "hello swift world")
    }
    
    func test_write_indent_singleLine() {
        // Given
        let input = "hello world"
        
        // When
        print("start", to: &sut)
        
        sut.indent.level += 1
        print(input, to: &sut)
        sut.indent.level -= 1
        
        print("end", to: &sut)
        
        // Then
        XCTAssertEqual(sut.text, """
        start
            hello world
        end
        
        """)
    }
    
    func test_write_indent_multipleLine() {
        // Given
        let input = """
        hello
            swift
        world
        """
        
        // When
        print("start", to: &sut)
        
        sut.indent.level += 1
        print(input, to: &sut)
        sut.indent.level -= 1
        
        print("end", to: &sut)
        
        // Then
        XCTAssertEqual(sut.text, """
        start
            hello
                swift
            world
        end
        
        """)
    }
    
    func test_write_indent_repeat() {
        // Given
        let lines: [String] = [
            "hello",
            "    swift",
            "world",
        ]
        
        // When
        print("start", to: &sut)
        
        sut.indent.level += 1
        for line in lines {
            print(line, to: &sut)
        }
        sut.indent.level -= 1
        
        print("end", to: &sut)
        
        // Then
        XCTAssertEqual(sut.text, """
        start
            hello
                swift
            world
        end
        
        """)
    }
    
    func test_write_indent_startsWithIndent() {
        // When
        sut.indent.level += 1
        print("hello", to: &sut)
        
        // Then
        XCTAssertEqual(sut.text, "    hello\n")
    }
}
