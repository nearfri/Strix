import Testing
@testable import StrixParsers

@Suite struct StringTests {
    @Test(arguments: [
        ("ab\"cd", #"ab\"cd"#),
        ("ab\\cd", #"ab\cd"#),
        ("ab\\ncd", #"ab\ncd"#),
        ("ab\ncd", #"ab\ncd"#),
        ("ab\rcd", #"ab\rcd"#),
        ("ab\tcd", #"ab\tcd"#),
        ("ab\u{0008}cd", #"ab\bcd"#),
        ("ab\u{000C}cd", #"ab\fcd"#),
    ])
    func addingBackslashEncoding2(input: String, expected: String) {
        #expect(input.addingBackslashEncoding() == expected)
    }
}
