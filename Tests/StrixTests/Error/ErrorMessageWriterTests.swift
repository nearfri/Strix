import Testing
@testable import Strix

private struct StreamSnapshot {
    var indent: Indent
    var text: String
}

private struct FakeErrorOutputStream: ErrorOutputStream {
    var indent: Indent = .init()
    var text: String = ""
    var snapshots: [StreamSnapshot] = []
    
    mutating func write(_ string: String) {
        text.write(string)
        
        snapshots.append(StreamSnapshot(indent: indent, text: text))
    }
}

private typealias ErrorMessageWriter = Strix.ErrorMessageWriter<FakeErrorOutputStream>

@Suite struct ErrorMessageWriterTests {
    private var errorStream = FakeErrorOutputStream()
    
    @Test mutating func write() {
        // Given
        let input = "\"abc def"
        let errors: [ParseError] = [
            .compound(label: "string literal in double quotes",
                      position: input.endIndex,
                      errors: [.expected(label: "'\"'")]),
        ]
        let sut = ErrorMessageWriter(input: input, position: input.startIndex, errors: errors)
        
        // When
        sut.write(to: &errorStream)
        
        // Then
        #expect(errorStream.text == """
            Error at line 1, column 1
            "abc def
            ^
            Expecting: string literal in double quotes
            
            string literal in double quotes could not be parsed because:
            Error at line 1, column 9
            "abc def
                    ^
            Note: The error occurred at the end of the input stream.
            Expecting: '"'
            
            """)
        
        #expect(errorStream.snapshots.contains(where: { snapshot in
            snapshot.indent.level == 0
            && snapshot.text.contains("Expecting: string literal in double quotes")
            && snapshot.text.hasSuffix("could not be parsed because:\n")
        }))
        
        #expect(errorStream.snapshots.contains(where: { snapshot in
            return snapshot.indent.level == 1
            && snapshot.text.contains("Error at line 1, column 9")
            && snapshot.text.contains("Expecting: '\"'")
        }))
        
        #expect(errorStream.indent.level == 0)
    }
    
    // MARK: - Position
    
    private enum PositionFixture {
        static let input = """
            12345
            abcde
            a\tde
            ABCDE
            """
    }
    
    @Test mutating func write_lineAndColumn() throws {
        // Given
        let position = try #require(PositionFixture.input.firstIndex(of: "c"))
        let sut = ErrorMessageWriter(input: PositionFixture.input, position: position, errors: [])
        
        // When
        sut.write(to: &errorStream)
        
        // Then
        #expect(errorStream.text.contains("Error at line 2, column 3"))
    }
    
    @Test mutating func write_substringAtPosition() throws {
        // Given
        let position = try #require(PositionFixture.input.firstIndex(of: "c"))
        let sut = ErrorMessageWriter(input: PositionFixture.input, position: position, errors: [])
        
        // When
        sut.write(to: &errorStream)
        
        // Then
        #expect(errorStream.text.contains("abcde"))
        #expect(!errorStream.text.contains("12345"))
        #expect(!errorStream.text.contains("ABCDE"))
    }
    
    @Test mutating func write_columnMarker() throws {
        // Given
        let position = try #require(PositionFixture.input.firstIndex(of: "c"))
        let sut = ErrorMessageWriter(input: PositionFixture.input, position: position, errors: [])
        
        // When
        sut.write(to: &errorStream)
        
        // Then
        //                                   abcde
        #expect(errorStream.text.contains("\n  ^"))
    }
    
    @Test mutating func write_columnMarkerAtEndOfLine() throws {
        // Given
        let input = PositionFixture.input
        let position = PositionFixture.input.index(after: try #require(input.firstIndex(of: "e")))
        let sut = ErrorMessageWriter(input: input, position: position, errors: [])
        
        // When
        sut.write(to: &errorStream)
        
        // Then
        //                                   abcde
        #expect(errorStream.text.contains("\n     ^"))
    }
    
    @Test mutating func write_columnMarkerAtEndOfInput() throws {
        // Given
        let position = PositionFixture.input.endIndex
        let sut = ErrorMessageWriter(input: PositionFixture.input, position: position, errors: [])
        
        // When
        sut.write(to: &errorStream)
        
        // Then
        //                                   ABCDE
        #expect(errorStream.text.contains("\n     ^"))
    }
    
    @Test mutating func write_columnMarkerAfterTab() throws {
        // Given
        let input = PositionFixture.input
        let position = PositionFixture.input.index(after: try #require(input.firstIndex(of: "\t")))
        #expect(PositionFixture.input[position] == "d")
        let sut = ErrorMessageWriter(input: input, position: position, errors: [])
        
        // When
        sut.write(to: &errorStream)
        
        // Then
        //                                   a\tde
        #expect(errorStream.text.contains("\n \t^"))
    }
    
    @Test mutating func write_noteAtEndOfInput() {
        // Given
        let position = PositionFixture.input.endIndex
        let sut = ErrorMessageWriter(input: PositionFixture.input, position: position, errors: [])
        
        // When
        sut.write(to: &errorStream)
        
        // Then
        #expect(errorStream.text.contains("The error occurred at the end of the input stream."))
    }
    
    @Test mutating func write_noteAtEndOfLine() throws {
        // Given
        let input = PositionFixture.input
        let position = PositionFixture.input.index(after: try #require(input.firstIndex(of: "e")))
        let sut = ErrorMessageWriter(input: input, position: position, errors: [])
        
        // When
        sut.write(to: &errorStream)
        
        // Then
        #expect(errorStream.text.contains("The error occurred at the end of the line."))
    }
    
    @Test mutating func write_noteAtEmptyLine() throws {
        // Given
        let input = """
            abc
            
            def
            """
        let position = input.index(before: try #require(input.firstIndex(of: "d")))
        let sut = ErrorMessageWriter(input: input, position: position, errors: [])
        
        // When
        sut.write(to: &errorStream)
        
        // Then
        #expect(errorStream.text.contains("The error occurred on an empty line."))
    }
    
    @Test mutating func write_multiline() throws {
        // Given
        let position = try #require(PositionFixture.input.firstIndex(of: "c"))
        let sut = ErrorMessageWriter(input: PositionFixture.input, position: position, errors: [])
        
        // When
        sut.write(to: &errorStream)
        
        // Then
        #expect(errorStream.text.contains("""
            Error at line 2, column 3
            abcde
              ^
            
            """))
    }
    
    // MARK: - Without position
    
    @Test mutating func writeWithoutPosition() {
        // Given
        let errors: [ParseError] = [
            .expected(label: "number"),
        ]
        let sut = ErrorMessageWriter(errors: errors)
        
        // When
        sut.write(to: &errorStream)
        
        // Then
        #expect(errorStream.text == "Expecting: number\n")
    }
    
    // MARK: - Expected error
    
    @Test mutating func write_expectedErrors_1() {
        // Given
        let input = "hello"
        let errors: [ParseError] = [
            .expected(label: "number"),
        ]
        let sut = ErrorMessageWriter(input: input, position: input.startIndex, errors: errors)
        
        // When
        sut.write(to: &errorStream)
        
        // Then
        #expect(errorStream.text.contains("Expecting: number"))
    }
    
    @Test mutating func write_expectedErrors_2() {
        // Given
        let input = "hello"
        let errors: [ParseError] = [
            .expected(label: "number"),
            .expected(label: "boolean"),
        ]
        let sut = ErrorMessageWriter(input: input, position: input.startIndex, errors: errors)
        
        // When
        sut.write(to: &errorStream)
        
        // Then
        #expect(errorStream.text.contains("Expecting: number or boolean"))
    }
    
    @Test mutating func write_expectedErrors_3() {
        // Given
        let input = ""
        let errors: [ParseError] = [
            .expected(label: "number"),
            .expected(label: "boolean"),
            .expected(label: "string"),
        ]
        let sut = ErrorMessageWriter(input: input, position: input.startIndex, errors: errors)
        
        // When
        sut.write(to: &errorStream)
        
        // Then
        #expect(errorStream.text.contains("Expecting: number, boolean, or string"))
    }
    
    @Test mutating func write_expectedStringErrors() {
        // Given
        let input = "wow"
        let errors: [ParseError] = [
            .expectedString(string: "HELLO", caseSensitive: false),
            .expectedString(string: "WORLD", caseSensitive: true),
        ]
        let sut = ErrorMessageWriter(input: input, position: input.startIndex, errors: errors)
        
        // When
        sut.write(to: &errorStream)
        
        // Then
        #expect(errorStream.text.contains("Expecting: 'HELLO' (case-insensitive) or 'WORLD'"))
    }
    
    @Test mutating func write_compoundExpectedErrors() {
        // Given
        let input = "\"abcd"
        let errors: [ParseError] = [
            .compound(label: "string literal in double quotes",
                      position: input.endIndex,
                      errors: [.expected(label: "'\"'")]),
        ]
        let sut = ErrorMessageWriter(input: input, position: input.startIndex, errors: errors)
        
        // When
        sut.write(to: &errorStream)
        
        // Then
        #expect(errorStream.text.contains("Expecting: string literal in double quotes"))
    }
    
    // MARK: - Unexpected error
    
    @Test mutating func write_unexpectedErrors() {
        // Given
        let input = "false"
        let errors: [ParseError] = [
            .unexpected(label: "boolean"),
            .unexpected(label: "string"),
        ]
        let sut = ErrorMessageWriter(input: input, position: input.startIndex, errors: errors)
        
        // When
        sut.write(to: &errorStream)
        
        // Then
        #expect(errorStream.text.contains("Unexpected: boolean and string"))
    }
    
    @Test mutating func write_unexpectedStringErrors() {
        // Given
        let input = "hello"
        let errors: [ParseError] = [
            .unexpectedString(string: "HELLO", caseSensitive: false),
            .unexpectedString(string: "WORLD", caseSensitive: true),
        ]
        let sut = ErrorMessageWriter(input: input, position: input.startIndex, errors: errors)
        
        // When
        sut.write(to: &errorStream)
        
        // Then
        #expect(errorStream.text.contains("Unexpected: 'HELLO' (case-insensitive) and 'WORLD'"))
    }
    
    // MARK: - Generic error
    
    @Test mutating func write_onlyGenericErrors() {
        // Given
        let input = "foo bar"
        let errors: [ParseError] = [
            .generic(message: "integer overflow"),
        ]
        let sut = ErrorMessageWriter(input: input, position: input.startIndex, errors: errors)
        
        // When
        sut.write(to: &errorStream)
        
        // Then
        #expect(errorStream.snapshots.contains(where: { snapshot in
            return snapshot.indent.level == 0
            && snapshot.text.contains("integer overflow")
        }))
    }
    
    @Test mutating func write_genericErrorsWithExpectedErrors() {
        // Given
        let input = "1) Write open source library 2) ??? 3) lot's of unpaid work"
        let errors: [ParseError] = [
            .expectedString(string: "profit", caseSensitive: true),
            .generic(message: "So much about that theory ..."),
        ]
        let position = input.index(input.firstIndex(of: "3")!, offsetBy: 3)
        let sut = ErrorMessageWriter(input: input, position: position, errors: errors)
        
        // When
        sut.write(to: &errorStream)
        
        // Then
        #expect(errorStream.text.contains("""
            Expecting: 'profit'
            Other error messages:
            So much about that theory ...
            """))
        
        #expect(errorStream.snapshots.contains(where: { snapshot in
            return snapshot.indent.level == 1
            && snapshot.text.contains("So much about that theory ...")
        }))
        
        #expect(errorStream.indent.level == 0)
    }
    
    // MARK: - Compound, nested error
    
    @Test mutating func write_compoundErrors() {
        // Given
        let input = "\"abc def"
        let errors: [ParseError] = [
            .compound(label: "string literal in double quotes",
                      position: input.endIndex,
                      errors: [.expected(label: "'\"'")]),
        ]
        let sut = ErrorMessageWriter(input: input, position: input.startIndex, errors: errors)
        
        // When
        sut.write(to: &errorStream)
        
        // Then
        #expect(errorStream.text.contains("""
            Expecting: string literal in double quotes
            
            string literal in double quotes could not be parsed because:
            Error at line 1, column 9
            "abc def
                    ^
            Note: The error occurred at the end of the input stream.
            Expecting: '"'
            """))
        
        #expect(errorStream.snapshots.contains(where: { snapshot in
            return snapshot.indent.level == 0
            && snapshot.text.contains("Expecting: string literal in double quotes")
            && snapshot.text.hasSuffix("could not be parsed because:\n")
        }))
        
        #expect(errorStream.snapshots.contains(where: { snapshot in
            return snapshot.indent.level == 1
            && snapshot.text.contains("Error at line 1, column 9")
            && snapshot.text.contains("Expecting: '\"'")
        }))
        
        #expect(errorStream.indent.level == 0)
    }
    
    @Test mutating func write_nestedErrors() {
        // Given
        let input = "ac"
        let errors: [ParseError] = [
            .nested(position: input.index(after: input.startIndex),
                    errors: [.expectedString(string: "b", caseSensitive: true)]),
        ]
        let sut = ErrorMessageWriter(input: input, position: input.startIndex, errors: errors)
        
        // When
        sut.write(to: &errorStream)
        
        // Then
        #expect(errorStream.text.contains("""
            The parser backtracked after:
            Error at line 1, column 2
            ac
             ^
            Expecting: 'b'
            """))
        
        #expect(errorStream.snapshots.contains(where: { snapshot in
            return snapshot.indent.level == 1
            && snapshot.text.contains("Error at line 1, column 2")
            && snapshot.text.contains("Expecting: 'b'")
        }))
        
        #expect(errorStream.indent.level == 0)
    }
}
