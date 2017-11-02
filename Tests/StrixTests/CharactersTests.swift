
import XCTest
@testable import Strix

class CharactersTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    // MARK: - Test parsing single chars
    
    func test_character() {
        let stream = CharacterStream(string: "ab")
        
        checkFailure(character("A").parse(stream))
        checkSuccess(character("a").parse(stream), "a")
        
        checkFailure(character("A").parse(stream))
        checkSuccess(character("b").parse(stream), "b")
        
        XCTAssertTrue(stream.isAtEnd)
        checkFailure(character("b").parse(stream))
    }
    
    func test_anyCharacter() {
        let stream = CharacterStream(string: "ab")
        
        checkSuccess(anyCharacter().parse(stream), "a")
        checkSuccess(anyCharacter().parse(stream), "b")
        
        XCTAssertTrue(stream.isAtEnd)
        checkFailure(anyCharacter().parse(stream))
    }
    
    func test_satisfy() {
        let errorLabel = "only 'a'"
        let aParser = satisfy({ $0 == "a" }, errorLabel: errorLabel)
        checkSuccess(aParser.run("a"), "a")
        checkFailure(aParser.run("b"), [ParseError.Expected(errorLabel)])
        checkFailure(satisfy({ $0 == "a" }).run("b"), [] as [ParseError.Expected])
    }
    
    func test_anyOfCharacters() {
        let stream = CharacterStream(string: "ab")
        
        checkFailure(any(of: "ABC").parse(stream))
        checkSuccess(any(of: "abc").parse(stream), "a")
        
        checkFailure(any(of: "ABC").parse(stream))
        checkSuccess(any(of: "abc").parse(stream), "b")
        
        XCTAssertTrue(stream.isAtEnd)
        checkFailure(any(of: "abc").parse(stream))
    }
    
    func test_noneOfCharacters() {
        let stream = CharacterStream(string: "ab")
        
        checkFailure(none(of: "abc").parse(stream))
        checkSuccess(none(of: "ABC").parse(stream), "a")
        
        checkFailure(none(of: "abc").parse(stream))
        checkSuccess(none(of: "ABC").parse(stream), "b")
        
        XCTAssertTrue(stream.isAtEnd)
        checkFailure(none(of: "ABC").parse(stream))
    }
    
    func test_asciiLetter() {
        let ascii = asciiLetter()
        
        checkFailure(ascii.run("1"))
        checkFailure(ascii.run("2"))
        
        let stream = CharacterStream(string: "aB")
        
        checkSuccess(ascii.parse(stream), "a")
        checkSuccess(ascii.parse(stream), "B")
        
        XCTAssertTrue(stream.isAtEnd)
        checkFailure(ascii.parse(stream))
    }
    
    func test_asciiUppercaseLowercaseLetter() {
        let uppercase = asciiUppercaseLetter()
        let lowercase = asciiLowercaseLetter()
        
        checkFailure(uppercase.run("1"))
        checkFailure(lowercase.run("1"))
        
        let stream = CharacterStream(string: "aB")
        
        checkFailure(uppercase.parse(stream))
        checkSuccess(lowercase.parse(stream), "a")
        
        checkFailure(lowercase.parse(stream))
        checkSuccess(uppercase.parse(stream), "B")
    }
    
    func test_decimalDigit() {
        let decimal = decimalDigit()
        
        let digits = "0123456789"
        let stream = CharacterStream(string: digits)
        
        for c in digits {
            checkSuccess(decimal.parse(stream), c, "when \(c)")
        }
        
        checkFailure(decimal.run("a"))
        checkFailure(decimal.run("A"))
        checkFailure(decimal.run("x"))
    }
    
    func test_hexadecimalDigit() {
        let hexadecimal = hexadecimalDigit()
        
        let digits = "0123456789ABCDEFabcdef"
        let stream = CharacterStream(string: digits)
        
        for c in digits {
            checkSuccess(hexadecimal.parse(stream), c, "when \(c)")
        }
        
        checkFailure(hexadecimal.run("g"))
        checkFailure(hexadecimal.run("G"))
        checkFailure(hexadecimal.run("x"))
    }
    
    func test_octalDigit() {
        let octal = octalDigit()
        
        let digits = "01234567"
        let stream = CharacterStream(string: digits)
        
        for c in digits {
            checkSuccess(octal.parse(stream), c, "when \(c)")
        }
        
        checkFailure(octal.run("a"))
        checkFailure(octal.run("A"))
        checkFailure(octal.run("x"))
        checkFailure(octal.run("8"))
        checkFailure(octal.run("9"))
    }
    
    func test_binaryDigit() {
        let binary = binaryDigit()
        
        let digits = "01"
        let stream = CharacterStream(string: digits)
        
        for c in digits {
            checkSuccess(binary.parse(stream), c, "when \(c)")
        }
        
        checkFailure(binary.run("a"))
        checkFailure(binary.run("A"))
        checkFailure(binary.run("x"))
        checkFailure(binary.run("2"))
        checkFailure(binary.run("9"))
    }
    
    func test_tab() {
        let tab = Strix.tab()
        
        checkSuccess(tab.run("\t"), "\t")
        checkFailure(tab.run(" "))
        checkFailure(tab.run("\n"))
    }
    
    func test_newline() {
        let newline = Strix.newline()
        
        checkSuccess(newline.run("\n"), "\n")
        checkSuccess(newline.run("\r"), "\r")
        checkSuccess(newline.run("\r\n"), "\r\n")
        checkFailure(newline.run("\t"))
    }
    
    func test_skipWhitespaces() {
        let whitespaces = skipWhitespaces()
        let stream = CharacterStream(string: "  \n\n  \t\t  a   ")
        
        checkSuccess(whitespaces.parse(stream))
        
        let index = stream.nextIndex
        checkSuccess(whitespaces.parse(stream))
        XCTAssertEqual(index, stream.nextIndex)
        
        checkSuccess(anyCharacter().parse(stream), "a")
        
        checkSuccess(whitespaces.parse(stream))
        
        XCTAssertTrue(stream.isAtEnd)
        checkSuccess(whitespaces.parse(stream))
    }
    
    func test_skipWhitespaces1() {
        let whitespaces = skipWhitespaces(atLeastOne: true)
        let stream = CharacterStream(string: "  \n\n  \t\t  a   ")
        
        checkSuccess(whitespaces.parse(stream))
        
        let index = stream.nextIndex
        checkFailure(whitespaces.parse(stream))
        XCTAssertEqual(index, stream.nextIndex)
        
        checkSuccess(anyCharacter().parse(stream), "a")
        
        checkSuccess(whitespaces.parse(stream))
        
        XCTAssertTrue(stream.isAtEnd)
        checkFailure(whitespaces.parse(stream))
    }
    
    // MARK: - Test parsing strings directly
    
    func test_string() {
        let str1 = "You, "
        let str2 = "the people, "
        let str3 = "have the power to make this life free and beautiful, "
        let str4 = "to make this life a wonderful adventure."
        let stream = CharacterStream(string: [str1, str2, str3, str4].joined(separator: ""))
        
        checkSuccess(string(str1).parse(stream), str1[...])
        
        checkSuccess(string(str2).parse(stream), str2[...])
        
        checkFailure(string(str3.uppercased()).parse(stream))
        checkSuccess(string(str3.uppercased(), case: .insensitive).parse(stream), str3[...])
        
        checkFailure(string(str4.uppercased()).parse(stream))
        checkSuccess(string(str4.uppercased(), case: .insensitive).parse(stream), str4[...])
        
        XCTAssertTrue(stream.isAtEnd)
        checkFailure(string(str4.uppercased(), case: .insensitive).parse(stream))
    }
    
    func test_restOfLine() {
        let stream = CharacterStream(string: """
        0123456789
        abcdefg
        p
        
        qwer
        """)
        
        checkSuccess(string("01234").parse(stream), "01234")
        checkSuccess(restOfLine().parse(stream), "56789")
        checkSuccess(string("abc").parse(stream), "abc")
        checkSuccess(restOfLine(strippingNewline: false).parse(stream), "defg\n")
        checkSuccess(string("p").parse(stream), "p")
        checkSuccess(restOfLine().parse(stream), "")
        checkSuccess(restOfLine().parse(stream), "")
        checkSuccess(restOfLine().parse(stream), "qwer")
        
        XCTAssertTrue(stream.isAtEnd)
        checkSuccess(restOfLine().parse(stream), "")
    }
    
    func test_stringUntil_skipString() {
        let stream = CharacterStream(string: "MangoBanana")
        
        checkFailure(string(until: "Apple", thenSkipString: false).parse(stream))
        
        checkSuccess(string(until: "Banana", thenSkipString: false).parse(stream), "Mango")
        XCTAssertTrue(stream.matches("Banana", case: .sensitive))
        
        stream.seek(to: stream.startIndex)
        checkSuccess(string(until: "Banana", thenSkipString: true).parse(stream), "Mango")
        XCTAssertTrue(stream.isAtEnd)
    }
    
    func test_stringUntil_caseSensitivity() {
        let stream = CharacterStream(string: "MangoBanana")
        
        checkFailure(string(until: "BANANA", case: .sensitive, thenSkipString: true).parse(stream))
        checkSuccess(string(until: "BANANA", case: .insensitive, thenSkipString: true).parse(stream),
                     "Mango")
    }
    
    func test_stringUntil_maxCount() {
        let stream = CharacterStream(string: "MangoBanana")
        //                                    012345
        
        checkFailure(string(until: "Banana", maxCount: 0, thenSkipString: true).parse(stream))
        checkFailure(string(until: "Banana", maxCount: 1, thenSkipString: true).parse(stream))
        checkFailure(string(until: "Banana", maxCount: 4, thenSkipString: true).parse(stream))
        checkSuccess(string(until: "Banana", maxCount: 5, thenSkipString: true).parse(stream),
                     "Mango")
        stream.seek(to: stream.startIndex)
        checkSuccess(string(until: "Banana", maxCount: 6, thenSkipString: true).parse(stream),
                     "Mango")
    }
    
    func test_manyCharacters() {
        let isNumber = isDecimalDigit
        let isLetter = isASCIILetter
        let str = "12345ABCDE"
        let stream = CharacterStream(string: str)
        
        checkSuccess(manyCharacters(while: isNumber).parse(stream), "12345")
        checkSuccess(manyCharacters(while: isLetter).parse(stream), "ABCDE")
        XCTAssertTrue(stream.isAtEnd)
    }
    
    func test_manyCharacters_minMaxCount() {
        let isNumber = isDecimalDigit
        let isLetter = isASCIILetter
        let str = "12345ABCDE"
        
        checkSuccess(manyCharacters(while: isNumber).run(str), "12345")
        checkSuccess(manyCharacters(while: isLetter).run(str), "")
        
        checkSuccess(manyCharacters(minCount: 1, while: isNumber).run(str), "12345")
        checkFailure(manyCharacters(minCount: 1, while: isLetter).run(str),
                     [] as [ParseError.Expected])
        checkFailure(manyCharacters(minCount: 1, errorLabel: "alphabet", while: isLetter).run(str),
                     [ParseError.Expected("alphabet")])
        
        checkFailure(manyCharacters(minCount: 10, while: isNumber).run(str))
        
        checkSuccess(manyCharacters(maxCount: 3, while: isNumber).run(str), "123")
    }
    
    func test_manyCharacters_first() {
        let isNumber = isDecimalDigit
        let isLetter = isASCIILetter
        
        checkSuccess(manyCharacters(first: isNumber, while: isLetter).run("1a"), "1a")
        checkSuccess(manyCharacters(first: isLetter, while: isNumber).run("a1"), "a1")
        
        checkSuccess(manyCharacters(first: isNumber, while: isLetter).run("11aa"), "1")
        checkSuccess(manyCharacters(first: isLetter, while: isNumber).run("aa11"), "a")
        
        checkSuccess(manyCharacters(first: isNumber, while: isLetter).run("aa"), "")
        checkSuccess(manyCharacters(first: isLetter, while: isNumber).run("11"), "")
        
        checkFailure(manyCharacters(minCount: 3, first: isNumber, while: isLetter).run("1a11"))
    }
    
    func test_regex() {
        let stream = CharacterStream(string: "FooBarSwift4")
        
        XCTAssertTrue(stream.skip("Foo", case: .sensitive))
        
        checkFailure(regex("F[a-zA-Z]+").parse(stream))
        checkSuccess(regex("B[a-zA-Z]+").parse(stream), "BarSwift")
    }
    
    // MARK: - Test parsing strings with the help of other parsers
    
    func test_manyCharactersParser() {
        let letter = asciiLetter()
        let upper = letter >>| { String($0).uppercased().first! }
        let lower = letter >>| { String($0).lowercased().first! }
        
        checkSuccess(manyCharacters(letter).run("AppleMango"), "AppleMango")
        checkSuccess(manyCharacters(upper).run("AppleMango"), "APPLEMANGO")
        checkSuccess(manyCharacters(letter).run("1234"), "")
        checkFailure(manyCharacters(letter, atLeastOne: true).run("1234"))
        
        checkSuccess(manyCharacters(first: lower, repeating: upper).run("AppleMango"), "aPPLEMANGO")
    }
    
    func test_manyStrings() {
        let apple = string("Apple")
        let mango = string("Mango")
        
        checkSuccess(manyStrings(apple).run("AppleAppleMangoMango"), "AppleApple")
        checkSuccess(manyStrings(mango).run("AppleAppleMangoMango"), "")
        checkFailure(manyStrings(mango, atLeastOne: true).run("AppleAppleMangoMango"))
        checkSuccess(manyStrings(first: apple, repeating: mango).run("AppleMangoMango"),
                     "AppleMangoMango")
    }
    
    func test_manyStringsSeparator() {
        let letter = manyCharacters(minCount: 1, while: isASCIILetter)
        let comma = string(", ")
        
        checkSuccess(manyStrings(letter, separator: comma, includeSeparator: false)
            .run("abc, def, ghi"), "abcdefghi")
        
        checkSuccess(manyStrings(letter, separator: comma, includeSeparator: true)
            .run("abc, def, ghi"), "abc, def, ghi")
        
        checkFailure(manyStrings(letter, separator: comma, includeSeparator: false)
            .run("abc, def, ghi, 123"))
        
        checkFailure(manyStrings(letter, separator: comma, includeSeparator: false)
            .run("abc, def, ghi, "))
        
        checkSuccess(manyStrings(letter, separator: comma, includeSeparator: false,
                                 allowEndBySeparator: true)
            .run("abc, def, ghi, "), "abcdefghi")
    }
    
    func test_skip() {
        let number = manyCharacters(minCount: 1, while: isDecimalDigit) >>| { Int($0)! }
        
        checkSuccess(skip(number, apply: { (num, substr) in
            XCTAssertEqual(num, 123)
            XCTAssertEqual(substr, "123")
            return 8
        }).run("123abc"), 8)
    }
    
    func test_stringSkipped() {
        let skipLetter = manyCharacters(while: isASCIILetter) >>% ()
        checkSuccess(stringSkipped(by: skipLetter).run("abc123"), "abc")
    }
    
    // MARK: - Test conditional parsing
    
    func test_endOfStream() {
        let stream = CharacterStream(string: "abc")
        
        checkFailure(endOfStream().parse(stream))
        checkSuccess(notEndOfStream().parse(stream))
        
        stream.seek(to: stream.endIndex)
        XCTAssertTrue(stream.isAtEnd)
        checkSuccess(endOfStream().parse(stream))
        checkFailure(notEndOfStream().parse(stream))
        
        checkSuccess(endOfStream().run(""))
        checkFailure(notEndOfStream().run(""))
    }
    
    func test_followedByCharacter() {
        let stream = CharacterStream(string: "Apple")
        
        checkSuccess(followed(by: { $0 == "A" }).parse(stream))
        XCTAssertEqual(stream.nextIndex, stream.startIndex)
        
        checkFailure(followed(by: { $0 == "a" }).parse(stream))
        XCTAssertEqual(stream.nextIndex, stream.startIndex)
        
        checkFailure(followed(by: { _ in true }, errorLabel: "any character").run(""),
                     [ParseError.Expected("any character")])
    }
    
    func test_followedByNewline() {
        checkSuccess(followedByNewline().run("\nApple"))
        checkFailure(notFollowedByNewline().run("\nApple"))
        
        checkFailure(followedByNewline().run("Apple"))
        checkSuccess(notFollowedByNewline().run("Apple"))
        
        checkFailure(followedByNewline().run(""))
        checkSuccess(notFollowedByNewline().run(""))
    }
    
    func test_followedByString() {
        let stream = CharacterStream(string: "AppleMango")
        
        checkSuccess(followed(by: "Apple").parse(stream))
        XCTAssertEqual(stream.nextIndex, stream.startIndex)
        
        checkFailure(followed(by: "APPLE").parse(stream))
        checkSuccess(followed(by: "APPLE", case: .insensitive).parse(stream))
        XCTAssertEqual(stream.nextIndex, stream.startIndex)
        
        checkFailure(notFollowed(by: "Apple").parse(stream))
        checkSuccess(notFollowed(by: "APPLE").parse(stream))
        checkFailure(notFollowed(by: "APPLE", case: .insensitive).parse(stream))
    }
    
    func test_precededByCharacter() {
        let stream = CharacterStream(string: "AppleMango")
        
        XCTAssertTrue(stream.skip("Apple", case: .sensitive))
        XCTAssertTrue(stream.matches("Mango", case: .sensitive))
        
        checkSuccess(preceded(by: { $0 == "e" }).parse(stream))
        XCTAssertTrue(stream.matches("Mango", case: .sensitive))
        
        checkFailure(preceded(by: { $0 == "E" }).parse(stream))
        checkFailure(preceded(by: { $0 == "o" }, errorLabel: "o").parse(stream),
                     [ParseError.Expected("o")])
        XCTAssertTrue(stream.matches("Mango", case: .sensitive))
    }
}



