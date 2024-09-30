import Testing
@testable import Strix

@Suite struct ErrorOutputBufferTests {
    private var sut: ErrorOutputBuffer = .init()
    
    init() {
        sut.indent.width = 4
    }
    
    @Test mutating func write_singleLine() {
        // Given
        let input = "hello world"
        
        // When
        print(input, terminator: "", to: &sut)
        
        // Then
        #expect(sut.text == input)
    }
    
    @Test mutating func write_multipleLine() {
        // Given
        let input = """
        hello
            swift
        world
        """
        
        // When
        print(input, terminator: "", to: &sut)
        
        // Then
        #expect(sut.text == input)
    }
    
    @Test mutating func write_repeat() {
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
        #expect(sut.text == "hello\n" + "    swift\n" + "world\n")
    }
    
    @Test mutating func write_withoutTerminator() {
        // When
        print("hello ", terminator: "", to: &sut)
        print("swift", terminator: "", to: &sut)
        print(" world", terminator: "", to: &sut)
        
        // Then
        #expect(sut.text == "hello swift world")
    }
    
    @Test mutating func write_indent_singleLine() {
        // Given
        let input = "hello world"
        
        // When
        print("start", to: &sut)
        
        sut.indent.level += 1
        print(input, to: &sut)
        sut.indent.level -= 1
        
        print("end", to: &sut)
        
        // Then
        #expect(sut.text == """
            start
                hello world
            end
            
            """)
    }
    
    @Test mutating func write_indent_multipleLine() {
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
        #expect(sut.text == """
            start
                hello
                    swift
                world
            end
            
            """)
    }
    
    @Test mutating func write_indent_repeat() {
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
        #expect(sut.text == """
            start
                hello
                    swift
                world
            end
            
            """)
    }
    
    @Test mutating func write_indent_startsWithIndent() {
        // When
        sut.indent.level += 1
        print("hello", to: &sut)
        
        // Then
        #expect(sut.text == "    hello\n")
    }
}
