import XCTest
import Strix
@testable import StrixParsers

final class FormatSpecifierParserTests: XCTestCase {
    let sut = Parser.formatSpecifier
    
    func test_parse_nonFormat_throwError() {
        XCTAssertThrowsError(try sut.run("d"))
    }
    
    func test_parse_invalidFormat_throwError() {
        XCTAssertThrowsError(try sut.run("%m"))
    }
    
    func test_parse_percent() throws {
        XCTAssertEqual(try sut.run("%%"), .percentSign)
    }
    
    func test_parse_int() throws {
        XCTAssertEqual(try sut.run("%d"), .placeholder(.init(conversion: .decimal)))
        XCTAssertEqual(try sut.run("%D"), .placeholder(.init(conversion: .DECIMAL)))
    }
    
    func test_parse_hex() throws {
        XCTAssertEqual(try sut.run("%x"), .placeholder(.init(conversion: .hex)))
        XCTAssertEqual(try sut.run("%X"), .placeholder(.init(conversion: .HEX)))
    }
    
    func test_parse_object() throws {
        XCTAssertEqual(try sut.run("%@"), .placeholder(.init(conversion: .object)))
    }
    
    func test_parse_index() {
        XCTAssertEqual(try sut.run("%1$d"), .placeholder(
                        .init(index: 1, conversion: .decimal)))
    }
    
    func test_parse_index_zero_throwError() {
        XCTAssertThrowsError(try sut.run("%0$d"))
    }
    
    func test_parse_flags_minus() {
        XCTAssertEqual(try sut.run("%-d"), .placeholder(
                        .init(flags: [.minus], conversion: .decimal)))
    }
    
    func test_parse_flags_hash() {
        XCTAssertEqual(try sut.run("%#d"), .placeholder(
                        .init(flags: [.hash], conversion: .decimal)))
    }
    
    func test_parse_flags_minusAndZero() {
        XCTAssertEqual(try sut.run("%-0d"), .placeholder(
                        .init(flags: [.minus, .zero], conversion: .decimal)))
    }
    
    func test_parse_width_static() {
        XCTAssertEqual(try sut.run("%5d"), .placeholder(
                        .init(width: .static(5), conversion: .decimal)))
    }
    
    func test_parse_width_dynamic() {
        XCTAssertEqual(try sut.run("%*d"), .placeholder(
                        .init(width: .dynamic(nil), conversion: .decimal)))
    }
    
    func test_parse_width_dynamicWithIndex() {
        XCTAssertEqual(try sut.run("%*2$d"), .placeholder(
                        .init(width: .dynamic(2), conversion: .decimal)))
    }
    
    func test_parse_precision_static() {
        XCTAssertEqual(try sut.run("%.5d"), .placeholder(
                        .init(precision: .static(5), conversion: .decimal)))
    }
    
    func test_parse_precision_dynamic() {
        XCTAssertEqual(try sut.run("%.*d"), .placeholder(
                        .init(precision: .dynamic(nil), conversion: .decimal)))
    }
    
    func test_parse_precision_dynamicWithIndex() {
        XCTAssertEqual(try sut.run("%.*2$d"), .placeholder(
                        .init(precision: .dynamic(2), conversion: .decimal)))
    }
    
    func test_parse_length_char() {
        XCTAssertEqual(try sut.run("%hhd"), .placeholder(
                        .init(length: .char, conversion: .decimal)))
    }
    
    func test_parse_length_short() {
        XCTAssertEqual(try sut.run("%hd"), .placeholder(
                        .init(length: .short, conversion: .decimal)))
    }
    
    func test_parse_length_long() {
        XCTAssertEqual(try sut.run("%ld"), .placeholder(
                        .init(length: .long, conversion: .decimal)))
    }
    
    func test_parse_variableName_goodName() {
        XCTAssertEqual(try sut.run("%#@v1_minutes@"), .placeholder(
                        .init(flags: [.hash], conversion: .object, variableName: "v1_minutes")))
    }
    
    func test_parse_variableName_invalidCharacter_throwError() {
        XCTAssertThrowsError(try sut.run("%#@v1_min&utes@"))
        XCTAssertThrowsError(try sut.run("%#@v1_min utes@"))
        XCTAssertThrowsError(try sut.run("%#@v1_min+utes@"))
    }
    
    func test_parse_variableName_notEndWithCommercialAt_throwError() {
        XCTAssertThrowsError(try sut.run("%#@v1_minutes"))
    }
    
    func test_parse_complex_placeholder() {
        XCTAssertEqual(try sut.run("%2$05.*3$ld"), .placeholder(
                        .init(index: 2, flags: [.zero], width: .static(5), precision: .dynamic(3),
                              length: .long, conversion: .decimal)))
    }
}
