
import XCTest
@testable import Strix

class ParseErrorGroupTests: XCTestCase {
    var sut: ParseErrorGroup!
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
        let str = "abcd"
        nestedErrors = [
            ParseError.Nested(position: TextPosition(string: str, index: str.startIndex),
                                                     userInfo: [:], errors: []),
            ParseError.Nested(position: TextPosition(string: str, index: str.endIndex),
                                                     userInfo: [:], errors: [])
        ]
        compoundErrors = [
            ParseError.Compound(label: "123",
                                position: TextPosition(string: str, index: str.startIndex),
                                userInfo: [:], errors: []),
            ParseError.Compound(label: "456",
                                position: TextPosition(string: str, index: str.startIndex),
                                userInfo: [:], errors: []),
            ParseError.Compound(label: "456",
                                position: TextPosition(string: str, index: str.endIndex),
                                userInfo: [:], errors: [])
        ]
        unknownErrors = [
            DummyError.err0
        ]
        
        let shuffledErrors: [Error] = [
            compoundErrors[2], unknownErrors[0], compoundErrors[1], nestedErrors[1],
            compoundErrors[0], nestedErrors[0], unexpectedStringErrors[3], genericErrors[1],
            unexpectedErrors[1], expectedStringErrors[3], genericErrors[0],
            expectedErrors[1], unexpectedStringErrors[2], unexpectedErrors[0],
            expectedStringErrors[2], expectedErrors[0], unexpectedStringErrors[1],
            expectedStringErrors[1], unexpectedStringErrors[0], expectedStringErrors[0]
        ]
        sut = ParseErrorGroup(shuffledErrors)
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func test_expectedErrors_sorted() {
        XCTAssertEqual(sut.expectedErrors, expectedErrors)
    }
    
    func test_expectedStringErrors_sorted() {
        XCTAssertEqual(sut.expectedStringErrors, expectedStringErrors)
    }
    
    func test_unexpectedErrors_sorted() {
        XCTAssertEqual(sut.unexpectedErrors, unexpectedErrors)
    }
    
    func test_unexpectedStringErrors_sorted() {
        XCTAssertEqual(sut.unexpectedStringErrors, unexpectedStringErrors)
    }
    
    func test_genericErrors_sorted() {
        XCTAssertEqual(sut.genericErrors, genericErrors)
    }
    
    func test_nestedErrors_sorted() {
        XCTAssertEqual(sut.nestedErrors.count, nestedErrors.count)
        for (lErr, rErr) in zip(sut.nestedErrors, nestedErrors) {
            XCTAssertEqual(lErr.position, rErr.position)
        }
    }
    
    func test_compoundErrors_sorted() {
        XCTAssertEqual(sut.compoundErrors.count, compoundErrors.count)
        for (lErr, rErr) in zip(sut.compoundErrors, compoundErrors) {
            XCTAssertEqual(lErr.label, rErr.label)
            XCTAssertEqual(lErr.position, rErr.position)
        }
    }
    
    func test_unknownErrors_contained() {
        XCTAssertEqual(sut.unknownErrors.count, unknownErrors.count)
        guard let lErr = sut.unknownErrors.first as? DummyError,
            let rErr = unknownErrors.first as? DummyError else {
                XCTFail()
                return
        }
        XCTAssertEqual(lErr, rErr)
    }
    
    func test_isEmpty() {
        XCTAssertFalse(sut.isEmpty)
        XCTAssertTrue(ParseErrorGroup([]).isEmpty)
        XCTAssertFalse(ParseErrorGroup([expectedErrors[0]]).isEmpty)
        XCTAssertFalse(ParseErrorGroup([expectedStringErrors[0]]).isEmpty)
        XCTAssertFalse(ParseErrorGroup([unexpectedErrors[0]]).isEmpty)
        XCTAssertFalse(ParseErrorGroup([unexpectedStringErrors[0]]).isEmpty)
        XCTAssertFalse(ParseErrorGroup([genericErrors[0]]).isEmpty)
        XCTAssertFalse(ParseErrorGroup([nestedErrors[0]]).isEmpty)
        XCTAssertFalse(ParseErrorGroup([compoundErrors[0]]).isEmpty)
        XCTAssertFalse(ParseErrorGroup([unknownErrors[0]]).isEmpty)
    }
}



