
import XCTest
@testable import Strix

class ErrorMessageWriterTests: XCTestCase {
    var position: TextPosition!
    var outputBuffer: ErrorOutputBuffer = ErrorOutputBuffer()
    var positionString: String = ""
    
    var expectedErrors: [ParseError.Expected]!
    var expectedStringErrors: [ParseError.ExpectedString]!
    var unexpectedErrors: [ParseError.Unexpected]!
    var unexpectedStringErrors: [ParseError.UnexpectedString]!
    var genericErrors: [ParseError.Generic]!
    var nestedErrors: [ParseError.Nested]!
    var compoundErrors: [ParseError.Compound]!
    var unknownErrors: [Error]!
    
    override func setUp() {
        super.setUp()
        
        let str = "Banana"
        position = TextPosition(string: str, index: str.startIndex)
        outputBuffer = ErrorOutputBuffer()
        positionString = """
        Error in 1:1
        Banana
        ^
        
        """
        
        expectedErrors = [
            ParseError.Expected("apple"),
            ParseError.Expected("strawberry")
        ]
        expectedStringErrors = [
            ParseError.ExpectedString("Apple", case: .sensitive),
            ParseError.ExpectedString("Strawberry", case: .sensitive),
            ParseError.ExpectedString("chili", case: .insensitive),
            ParseError.ExpectedString("tomato", case: .insensitive)
        ]
        unexpectedErrors = [
            ParseError.Unexpected("banana"),
            ParseError.Unexpected("melon")
        ]
        unexpectedStringErrors = [
            ParseError.UnexpectedString("Banana", case: .sensitive),
            ParseError.UnexpectedString("Melon", case: .sensitive),
            ParseError.UnexpectedString("peach", case: .insensitive),
            ParseError.UnexpectedString("pear", case: .insensitive)
        ]
        genericErrors = [
            ParseError.Generic(message: "banana is yellow"),
            ParseError.Generic(message: "melon is green")
        ]
        nestedErrors = [
            ParseError.Nested(position: TextPosition(string: str, index: str.index(after: str.startIndex)),
                              userInfo: [:], errors: [expectedErrors[0]])
        ]
        compoundErrors = [
            ParseError.Compound(label: "Red fruit",
                                position: TextPosition(string: str, index: str.index(after: str.startIndex)),
                                userInfo: [:], errors: expectedErrors)
        ]
        unknownErrors = [
            DummyError.err0
        ]
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func test_emptyErrors() {
        ErrorMessageWriter.write(position: position, errors: [], to: &outputBuffer)
        XCTAssertEqual(outputBuffer.text, "\(positionString)Unknown Error(s)\n")
    }
    
    func test_expectedErrors() {
        ErrorMessageWriter.write(position: position, errors: expectedErrors, to: &outputBuffer)
        XCTAssertEqual(outputBuffer.text,
                       "\(positionString)Expecting: apple or strawberry\n")
    }
    
    func test_expectedStringErrors() {
        ErrorMessageWriter.write(position: position, errors: expectedStringErrors,
                                 to: &outputBuffer)
        XCTAssertEqual(outputBuffer.text, ""
            + "\(positionString)Expecting: 'Apple', 'Strawberry', "
            + "'chili' (case-insensitive) or 'tomato' (case-insensitive)\n")
    }
    
    func test_unexpectedErrors() {
        ErrorMessageWriter.write(position: position, errors: unexpectedErrors, to: &outputBuffer)
        XCTAssertEqual(outputBuffer.text,
                       "\(positionString)Unexpected: banana and melon\n")
    }
    
    func test_unexpectedStringErrors() {
        ErrorMessageWriter.write(position: position, errors: unexpectedStringErrors,
                                 to: &outputBuffer)
        XCTAssertEqual(outputBuffer.text, ""
            + "\(positionString)Unexpected: 'Banana', 'Melon', "
            + "'peach' (case-insensitive) and 'pear' (case-insensitive)\n")
    }
    
    func test_allExpectedErrors() {
        let errors: [Error] = expectedErrors as [Error] + expectedStringErrors
        ErrorMessageWriter.write(position: position, errors: errors, to: &outputBuffer)
        XCTAssertEqual(outputBuffer.text, ""
            + "\(positionString)Expecting: apple, strawberry, 'Apple', 'Strawberry', "
            + "'chili' (case-insensitive) or 'tomato' (case-insensitive)\n")
    }
    
    func test_allUnexpectedErrors() {
        let errors: [Error] = unexpectedErrors as [Error] + unexpectedStringErrors
        ErrorMessageWriter.write(position: position, errors: errors, to: &outputBuffer)
        XCTAssertEqual(outputBuffer.text, ""
            + "\(positionString)Unexpected: banana, melon, 'Banana', 'Melon', "
            + "'peach' (case-insensitive) and 'pear' (case-insensitive)\n")
    }
    
    func test_otherMessages_whenNotGivenExpectedErrors() {
        let errors: [Error] = genericErrors as [Error] + unknownErrors
        ErrorMessageWriter.write(position: position, errors: errors, to: &outputBuffer)
        XCTAssertEqual(outputBuffer.text, """
            \(positionString)banana is yellow
            melon is green
            \(unknownErrors[0])
            
            """)
    }
    
    func test_otherMessages_whenGivenExpectedErrors() {
        let errors: [Error] = genericErrors as [Error] + unknownErrors + expectedErrors
        ErrorMessageWriter.write(position: position, errors: errors, to: &outputBuffer)
        XCTAssertEqual(outputBuffer.text, """
            \(positionString)Expecting: apple or strawberry
            Other error messages:
              banana is yellow
              melon is green
              \(unknownErrors[0])
            
            """)
    }
    
    func test_nestedErrors() {
        ErrorMessageWriter.write(position: position, errors: nestedErrors, to: &outputBuffer)
        XCTAssertEqual(outputBuffer.text, """
            \(positionString)
            The parser backtracked after:
              Error in 1:2
              Banana
               ^
              Expecting: apple
            
            """)
    }
    
    func test_compoundErrors() {
        ErrorMessageWriter.write(position: position, errors: compoundErrors, to: &outputBuffer)
        XCTAssertEqual(outputBuffer.text, """
            \(positionString)Expecting: Red fruit
            
            Red fruit could not be parsed because:
              Error in 1:2
              Banana
               ^
              Expecting: apple or strawberry
            
            """)
    }
    
    func test_mixedErrors() {
        let errors: [Error] = expectedErrors as [Error] +  unexpectedErrors as [Error]
            + genericErrors as [Error] + nestedErrors as [Error] + compoundErrors as [Error]
            + unknownErrors
        ErrorMessageWriter.write(position: position, errors: errors, to: &outputBuffer)
        XCTAssertEqual(outputBuffer.text, """
            \(positionString)Expecting: apple, strawberry or Red fruit
            Unexpected: banana and melon
            Other error messages:
              banana is yellow
              melon is green
              \(unknownErrors[0])
            
            Red fruit could not be parsed because:
              Error in 1:2
              Banana
               ^
              Expecting: apple or strawberry
            
            The parser backtracked after:
              Error in 1:2
              Banana
               ^
              Expecting: apple
            
            """)
    }
    
    func test_positionStringNote_whenEndOfInput() {
        let str = "apple"
        let position = TextPosition(string: str, index: str.endIndex)
        ErrorMessageWriter.write(position: position, errors: [], to: &outputBuffer)
        XCTAssertEqual(outputBuffer.text, """
            Error in 1:6
            apple
                 ^
            Note: The error occurred at the end of the input stream.
            Unknown Error(s)
            
            """)
    }
    
    func test_positionStringNote_whenEmptyLine() {
        let str = "\napple"
        let position = TextPosition(string: str, index: str.startIndex)
        ErrorMessageWriter.write(position: position, errors: [], to: &outputBuffer)
        XCTAssertEqual(outputBuffer.text, """
            Error in 1:1
            
            ^
            Note: The error occurred on an empty line.
            Unknown Error(s)
            
            """)
    }
    
    func test_positionStringNote_whenEndOfLine() {
        let str = "apple\npen"
        let position = TextPosition(string: str, index: str.index(str.startIndex, offsetBy: 5))
        ErrorMessageWriter.write(position: position, errors: [], to: &outputBuffer)
        XCTAssertEqual(outputBuffer.text, """
            Error in 1:6
            apple
                 ^
            Note: The error occurred at the end of the line.
            Unknown Error(s)
            
            """)
    }
}



