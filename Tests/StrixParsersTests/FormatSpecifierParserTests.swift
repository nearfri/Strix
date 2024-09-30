import Testing
import Strix
@testable import StrixParsers

@Suite struct FormatSpecifierParserTests {
    private let sut = Parser.formatSpecifier
    
    @Test func parse_nonFormat_throwError() {
        #expect(throws: RunError.self, performing: {
            try sut.run("d")
        })
    }
    
    @Test func parse_invalidFormat_throwError() {
        #expect(throws: RunError.self, performing: {
            try sut.run("%m")
        })
    }
    
    @Test func parse_percent() throws {
        try #expect(sut.run("%%") == .percentSign)
    }
    
    @Test func parse_int() throws {
        try #expect(sut.run("%d") == .placeholder(.init(conversion: .decimal)))
        try #expect(sut.run("%D") == .placeholder(.init(conversion: .DECIMAL)))
    }
    
    @Test func parse_hex() throws {
        try #expect(sut.run("%x") == .placeholder(.init(conversion: .hex)))
        try #expect(sut.run("%X") == .placeholder(.init(conversion: .HEX)))
    }
    
    @Test func parse_object() throws {
        try #expect(sut.run("%@") == .placeholder(.init(conversion: .object)))
    }
    
    @Test func parse_index() throws {
        try #expect(sut.run("%1$d") == .placeholder(.init(index: 1, conversion: .decimal)))
    }
    
    @Test func parse_index_zero_throwError() {
        #expect(throws: RunError.self, performing: {
            try sut.run("%0$d")
        })
    }
    
    @Test(arguments: [
        ("minus", "%-d", .init(flags: [.minus], conversion: .decimal)),
        ("hash", "%#d", .init(flags: [.hash], conversion: .decimal)),
        ("minus and zero", "%-0d", .init(flags: [.minus, .zero], conversion: .decimal)),
    ] as [(Comment, String, FormatPlaceholder)])
    func parse_flags(comment: Comment, input: String, expected: FormatPlaceholder) throws {
        try #expect(sut.run(input) == .placeholder(expected), comment)
    }
    
    @Test(arguments: [
        ("static", "%5d", .init(width: .static(5), conversion: .decimal)),
        ("dynamic", "%*d", .init(width: .dynamic(nil), conversion: .decimal)),
        ("dynamic with index", "%*2$d", .init(width: .dynamic(2), conversion: .decimal)),
    ] as [(Comment, String, FormatPlaceholder)])
    func parse_width(comment: Comment, input: String, expected: FormatPlaceholder) throws {
        try #expect(sut.run(input) == .placeholder(expected), comment)
    }
    
    @Test(arguments: [
        ("static", "%.5d", .init(precision: .static(5), conversion: .decimal)),
        ("dynamic", "%.*d", .init(precision: .dynamic(nil), conversion: .decimal)),
        ("dynamic with index", "%.*2$d", .init(precision: .dynamic(2), conversion: .decimal)),
    ] as [(Comment, String, FormatPlaceholder)])
    func parse_precision(comment: Comment, input: String, expected: FormatPlaceholder) throws {
        try #expect(sut.run(input) == .placeholder(expected), comment)
    }
    
    @Test(arguments: [
        ("char", "%hhd", .init(length: .char, conversion: .decimal)),
        ("short", "%hd", .init(length: .short, conversion: .decimal)),
        ("long", "%ld", .init(length: .long, conversion: .decimal)),
    ] as [(Comment, String, FormatPlaceholder)])
    func parse_length(comment: Comment, input: String, expected: FormatPlaceholder) throws {
        try #expect(sut.run(input) == .placeholder(expected), comment)
    }
    
    @Test func parse_variableName_goodName() throws {
        let expected = FormatPlaceholder(
            flags: [.hash],
            conversion: .object,
            variableName: "v1_minutes")
        
        try #expect(sut.run("%#@v1_minutes@") == .placeholder(expected))
    }
    
    @Test(arguments: [
        "%#@v1_min&utes@",
        "%#@v1_min utes@",
        "%#@v1_min+utes@",
    ])
    func parse_variableName_invalidCharacter_throwError(input: String) {
        #expect(throws: RunError.self, performing: {
            try sut.run(input)
        })
    }
    
    @Test func parse_variableName_notEndWithCommercialAt_throwError() {
        #expect(throws: RunError.self, performing: {
            try sut.run("%#@v1_minutes")
        })
    }
    
    @Test func parse_complex_placeholder() throws {
        let expected = FormatPlaceholder(
            index: 2,
            flags: [.zero],
            width: .static(5),
            precision: .dynamic(3),
            length: .long,
            conversion: .decimal)
        
        try #expect(sut.run("%2$05.*3$ld") == .placeholder(expected))
    }
}
