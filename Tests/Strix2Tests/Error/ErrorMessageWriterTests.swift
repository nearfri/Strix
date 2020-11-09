import XCTest
@testable import Strix2

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

private typealias ErrorMessageWriter = Strix2.ErrorMessageWriter<FakeErrorOutputStream>

class BaseErrorMessageWriterTests: XCTestCase {
    fileprivate var errorStream = FakeErrorOutputStream()
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        errorStream = FakeErrorOutputStream()
    }
}

// MARK: - ErrorMessageWriter

final class ErrorMessageWriterTests: BaseErrorMessageWriterTests {
    func test_write() {
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
        XCTAssertEqual(errorStream.text, """
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
        
        XCTAssert(errorStream.snapshots.contains(where: { snapshot in
            return snapshot.indent.level == 0
                && snapshot.text.contains("Expecting: string literal in double quotes")
                && snapshot.text.hasSuffix("could not be parsed because:\n")
        }))
        
        XCTAssert(errorStream.snapshots.contains(where: { snapshot in
            return snapshot.indent.level == 1
                && snapshot.text.contains("Error at line 1, column 9")
                && snapshot.text.contains("Expecting: '\"'")
        }))
        
        XCTAssertEqual(errorStream.indent.level, 0)
    }
}

// MARK: - Position

final class ErrorMessageWriterPositionTests: BaseErrorMessageWriterTests {
    enum Seed {
        static let input = """
        12345
        abcde
        a\tde
        ABCDE
        """
    }
    
    func test_write_lineAndColumn() throws {
        // Given
        let position = try XCTUnwrap(Seed.input.firstIndex(of: "c"))
        let sut = ErrorMessageWriter(input: Seed.input, position: position, errors: [])
        
        // When
        sut.write(to: &errorStream)
        
        // Then
        XCTAssert(errorStream.text.contains("Error at line 2, column 3"))
    }
    
    func test_write_substringAtPosition() throws {
        // Given
        let position = try XCTUnwrap(Seed.input.firstIndex(of: "c"))
        let sut = ErrorMessageWriter(input: Seed.input, position: position, errors: [])
        
        // When
        sut.write(to: &errorStream)
        
        // Then
        XCTAssert(errorStream.text.contains("abcde"))
        XCTAssertFalse(errorStream.text.contains("12345"))
        XCTAssertFalse(errorStream.text.contains("ABCDE"))
    }
    
    func test_write_columnMarker() throws {
        // Given
        let position = try XCTUnwrap(Seed.input.firstIndex(of: "c"))
        let sut = ErrorMessageWriter(input: Seed.input, position: position, errors: [])
        
        // When
        sut.write(to: &errorStream)
        
        // Then
        //                                     abcde
        XCTAssert(errorStream.text.contains("\n  ^"))
    }
    
    func test_write_columnMarkerAtEndOfLine() throws {
        // Given
        let position = Seed.input.index(after: try XCTUnwrap(Seed.input.firstIndex(of: "e")))
        let sut = ErrorMessageWriter(input: Seed.input, position: position, errors: [])
        
        // When
        sut.write(to: &errorStream)
        
        // Then
        //                                     abcde
        XCTAssert(errorStream.text.contains("\n     ^"))
    }
    
    func test_write_columnMarkerAtEndOfInput() throws {
        // Given
        let position = Seed.input.endIndex
        let sut = ErrorMessageWriter(input: Seed.input, position: position, errors: [])
        
        // When
        sut.write(to: &errorStream)
        
        // Then
        //                                     ABCDE
        XCTAssert(errorStream.text.contains("\n     ^"))
    }
    
    func test_write_columnMarkerAfterTab() throws {
        // Given
        let position = Seed.input.index(after: try XCTUnwrap(Seed.input.firstIndex(of: "\t")))
        XCTAssertEqual(Seed.input[position], "d")
        let sut = ErrorMessageWriter(input: Seed.input, position: position, errors: [])
        
        // When
        sut.write(to: &errorStream)
        
        // Then
        //                                     a\tde
        XCTAssert(errorStream.text.contains("\n \t^"))
    }
    
    func test_write_noteAtEndOfInput() {
        // Given
        let position = Seed.input.endIndex
        let sut = ErrorMessageWriter(input: Seed.input, position: position, errors: [])
        
        // When
        sut.write(to: &errorStream)
        
        // Then
        XCTAssert(errorStream.text.contains("The error occurred at the end of the input stream."))
    }
    
    func test_write_noteAtEndOfLine() throws {
        // Given
        let position = Seed.input.index(after: try XCTUnwrap(Seed.input.firstIndex(of: "e")))
        let sut = ErrorMessageWriter(input: Seed.input, position: position, errors: [])
        
        // When
        sut.write(to: &errorStream)
        
        // Then
        XCTAssert(errorStream.text.contains("The error occurred at the end of the line."))
    }
    
    func test_write_noteAtEmptyLine() throws {
        // Given
        let input = """
        abc
        
        def
        """
        let position = input.index(before: try XCTUnwrap(input.firstIndex(of: "d")))
        let sut = ErrorMessageWriter(input: input, position: position, errors: [])
        
        // When
        sut.write(to: &errorStream)
        
        // Then
        XCTAssert(errorStream.text.contains("The error occurred on an empty line."))
    }
    
    func test_write_multiline() throws {
        // Given
        let position = try XCTUnwrap(Seed.input.firstIndex(of: "c"))
        let sut = ErrorMessageWriter(input: Seed.input, position: position, errors: [])
        
        // When
        sut.write(to: &errorStream)
        
        // Then
        XCTAssert(errorStream.text.contains("""
        Error at line 2, column 3
        abcde
          ^
        
        """))
    }
}

// MARK: - Expected error

final class ErrorMessageWriterExpectedTests: BaseErrorMessageWriterTests {
    func test_write_expectedErrors_1() {
        // Given
        let input = "hello"
        let errors: [ParseError] = [
            .expected(label: "number"),
        ]
        let sut = ErrorMessageWriter(input: input, position: input.startIndex, errors: errors)
        
        // When
        sut.write(to: &errorStream)
        
        // Then
        XCTAssert(errorStream.text.contains("Expecting: number"))
    }
    
    func test_write_expectedErrors_2() {
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
        XCTAssert(errorStream.text.contains("Expecting: number or boolean"))
    }
    
    func test_write_expectedErrors_3() {
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
        XCTAssert(errorStream.text.contains("Expecting: number, boolean, or string"))
    }
    
    func test_write_expectedStringErrors() {
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
        XCTAssert(errorStream.text.contains("Expecting: 'HELLO' (case-insensitive) or 'WORLD'"))
    }
    
    func test_write_compoundErrors() {
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
        XCTAssert(errorStream.text.contains("Expecting: string literal in double quotes"))
    }
}

// MARK: - Unexpected error

final class ErrorMessageWriterUnexpectedTests: BaseErrorMessageWriterTests {
    func test_write_unexpectedErrors() {
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
        XCTAssert(errorStream.text.contains("Unexpected: boolean and string"))
    }
    
    func test_write_unexpectedStringErrors() {
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
        XCTAssert(errorStream.text.contains("Unexpected: 'HELLO' (case-insensitive) and 'WORLD'"))
    }
}

// MARK: - Generic error

final class ErrorMessageWriterGenericTests: BaseErrorMessageWriterTests {
    func test_write_onlyGenericErrors() {
        // Given
        let input = "foo bar"
        let errors: [ParseError] = [
            .generic(message: "integer overflow"),
        ]
        let sut = ErrorMessageWriter(input: input, position: input.startIndex, errors: errors)
        
        // When
        sut.write(to: &errorStream)
        
        // Then
        XCTAssert(errorStream.snapshots.contains(where: { snapshot in
            return snapshot.indent.level == 0
                && snapshot.text.contains("integer overflow")
        }))
    }
    
    func test_write_genericErrorsWithExpectedErrors() {
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
        XCTAssert(errorStream.text.contains("""
        Expecting: 'profit'
        Other error messages:
        So much about that theory ...
        """))
        
        XCTAssert(errorStream.snapshots.contains(where: { snapshot in
            return snapshot.indent.level == 1
                && snapshot.text.contains("So much about that theory ...")
        }))
        
        XCTAssertEqual(errorStream.indent.level, 0)
    }
}

// MARK: - Compound, nested error

final class ErrorMessageWriterCompoundTests: BaseErrorMessageWriterTests {
    func test_write_compoundErrors() {
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
        XCTAssert(errorStream.text.contains("""
        Expecting: string literal in double quotes
        
        string literal in double quotes could not be parsed because:
        Error at line 1, column 9
        "abc def
                ^
        Note: The error occurred at the end of the input stream.
        Expecting: '"'
        """))
        
        XCTAssert(errorStream.snapshots.contains(where: { snapshot in
            return snapshot.indent.level == 0
                && snapshot.text.contains("Expecting: string literal in double quotes")
                && snapshot.text.hasSuffix("could not be parsed because:\n")
        }))
        
        XCTAssert(errorStream.snapshots.contains(where: { snapshot in
            return snapshot.indent.level == 1
                && snapshot.text.contains("Error at line 1, column 9")
                && snapshot.text.contains("Expecting: '\"'")
        }))
        
        XCTAssertEqual(errorStream.indent.level, 0)
    }
    
    func test_write_nestedErrors() {
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
        XCTAssert(errorStream.text.contains("""
        The parser backtracked after:
        Error at line 1, column 2
        ac
         ^
        Expecting: 'b'
        """))
        
        XCTAssert(errorStream.snapshots.contains(where: { snapshot in
            return snapshot.indent.level == 1
                && snapshot.text.contains("Error at line 1, column 2")
                && snapshot.text.contains("Expecting: 'b'")
        }))
        
        XCTAssertEqual(errorStream.indent.level, 0)
    }
}
