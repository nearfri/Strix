import Foundation
import Strix

public typealias CSV = [[String]]

public struct CSVParser {
    private let parser: Parser<CSV>
    
    public init() {
        let ws = Parser.many(.whitespace)
        parser = ws *> Parser.csv <* ws <* .endOfStream
    }
    
    public func parse(_ csvString: String) throws(RunError) -> CSV {
        return try parser.run(csvString)
    }
    
    public func callAsFunction(_ csvString: String) throws(RunError) -> CSV {
        return try parse(csvString)
    }
}

extension Parser where T == CSV {
    public static var csv: Parser<CSV> { CSVParserGenerator().csv }
}

private struct CSVParserGenerator {
    var csv: Parser<CSV> { Parser.many(record, separatedBy: .newline).map({ fixCSV($0) }) }
    
    private var record: Parser<[String]> { .many(field, separatedBy: .character(",")) }
    
    private var field: Parser<String> { escapedField <|> nonEscapedField }
    
    private var escapedField: Parser<String> { doubleQuote *> escapedText <* doubleQuote }
    private var escapedText: Parser<String> {
        return Parser.many((.none(of: "\"") <|> twoDoubleQuote)).map({ String($0) })
    }
    private let doubleQuote: Parser<Character> = .character("\"")
    private let twoDoubleQuote: Parser<Character> = Parser.string("\"\"") *> .just("\"")
    
    private var nonEscapedField: Parser<String> { .skipped(by: .many(nonSeparator)) }
    private let nonSeparator: Parser<Character> = .satisfy("non-separator",
                                                           { $0 != "," && !$0.isNewline })
}

private func fixCSV(_ csv: CSV) -> CSV {
    var csv = csv
    
    if let lastValidRecordIndex = csv.lastIndex(where: { $0 != [""] }) {
        let invalidRecordIndex = lastValidRecordIndex + 1
        csv.removeSubrange(invalidRecordIndex...)
    } else {
        csv.removeAll()
    }
    
    return csv
}
