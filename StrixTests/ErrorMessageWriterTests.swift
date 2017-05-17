
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
        
        let str = "apple"
        position = TextPosition(string: str, index: str.startIndex)
        outputBuffer = ErrorOutputBuffer()
        positionString = "Error in 1:1\napple\n^\n"
        
        expectedErrors = [
            ParseError.Expected("abc"),
            ParseError.Expected("def")
        ]
        expectedStringErrors = [
            ParseError.ExpectedString("abc", case: .sensitive),
            ParseError.ExpectedString("def", case: .sensitive),
            ParseError.ExpectedString("abc", case: .insensitive),
            ParseError.ExpectedString("def", case: .insensitive)
        ]
        unexpectedErrors = [
            ParseError.Unexpected("abc"),
            ParseError.Unexpected("def")
        ]
        unexpectedStringErrors = [
            ParseError.UnexpectedString("abc", case: .sensitive),
            ParseError.UnexpectedString("def", case: .sensitive),
            ParseError.UnexpectedString("abc", case: .insensitive),
            ParseError.UnexpectedString("def", case: .insensitive)
        ]
        genericErrors = [
            ParseError.Generic(message: "abc"),
            ParseError.Generic(message: "def")
        ]
        nestedErrors = [
            ParseError.Nested(position: TextPosition(string: str, index: str.index(after: str.startIndex)),
                              userInfo: [:], errors: [expectedErrors[0]])
        ]
        compoundErrors = [
            ParseError.Compound(label: "123",
                                position: TextPosition(string: str, index: str.index(after: str.startIndex)),
                                userInfo: [:], errors: [expectedErrors[1]])
        ]
        unknownErrors = [
            NSError(domain: "test", code: 1, userInfo: nil)
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
                       "\(positionString)Expecting: abc or def\n")
    }
    
    func test_expectedStringErrors() {
        ErrorMessageWriter.write(position: position, errors: expectedStringErrors,
                                 to: &outputBuffer)
        XCTAssertEqual(outputBuffer.text,
                       "\(positionString)Expecting: 'abc', 'def', "
                        + "'abc' (case-insensitive) or 'def' (case-insensitive)\n")
    }
    
    func test_unexpectedErrors() {
        ErrorMessageWriter.write(position: position, errors: unexpectedErrors, to: &outputBuffer)
        XCTAssertEqual(outputBuffer.text,
                       "\(positionString)Unexpected: abc and def\n")
    }
    
    func test_unexpectedStringErrors() {
        ErrorMessageWriter.write(position: position, errors: unexpectedStringErrors,
                                 to: &outputBuffer)
        XCTAssertEqual(outputBuffer.text,
                       "\(positionString)Unexpected: 'abc', 'def', "
                        + "'abc' (case-insensitive) and 'def' (case-insensitive)\n")
    }
    
    func test_allExpectedErrors() {
        let errors: [Error] = expectedErrors as [Error] + expectedStringErrors
        ErrorMessageWriter.write(position: position, errors: errors, to: &outputBuffer)
        XCTAssertEqual(outputBuffer.text,
                       "\(positionString)Expecting: abc, def, 'abc', 'def', "
                        + "'abc' (case-insensitive) or 'def' (case-insensitive)\n")
    }
    
    func test_allUnexpectedErrors() {
        let errors: [Error] = unexpectedErrors as [Error] + unexpectedStringErrors
        ErrorMessageWriter.write(position: position, errors: errors, to: &outputBuffer)
        XCTAssertEqual(outputBuffer.text,
                       "\(positionString)Unexpected: abc, def, 'abc', 'def', "
                        + "'abc' (case-insensitive) and 'def' (case-insensitive)\n")
    }
    
    func test_otherMessages_whenNotGivenExpectedErrors() {
        let errors: [Error] = genericErrors as [Error] + unknownErrors
        ErrorMessageWriter.write(position: position, errors: errors, to: &outputBuffer)
        XCTAssertEqual(outputBuffer.text,
                       "\(positionString)abc\n"
                        + "def\n"
                        + "\(unknownErrors[0])\n")
    }
    
    func test_otherMessages_whenGivenExpectedErrors() {
        let errors: [Error] = genericErrors as [Error] + unknownErrors + expectedErrors
        ErrorMessageWriter.write(position: position, errors: errors, to: &outputBuffer)
        XCTAssertEqual(outputBuffer.text,
                       "\(positionString)Expecting: abc or def\n"
                        + "Other error messages: \n"
                        + "  abc\n"
                        + "  def\n"
                        + "  \(unknownErrors[0])\n")
    }
    
    func test_nestedErrors() {
        ErrorMessageWriter.write(position: position, errors: nestedErrors, to: &outputBuffer)
        XCTAssertEqual(outputBuffer.text,
                       "\(positionString)\n"
                        + "The parser backtracked after: \n"
                        + "  Error in 1:2\n"
                        + "  apple\n"
                        + "   ^\n"
                        + "  Expecting: abc\n")
    }
    
    func test_compoundErrors() {
        ErrorMessageWriter.write(position: position, errors: compoundErrors, to: &outputBuffer)
        XCTAssertEqual(outputBuffer.text,
                       "\(positionString)Expecting: 123\n"
                        + "\n"
                        + "123 could not be parsed because: \n"
                        + "  Error in 1:2\n"
                        + "  apple\n"
                        + "   ^\n"
                        + "  Expecting: def\n")
    }
    
    func test_mixedErrors() {
        
    }
}



