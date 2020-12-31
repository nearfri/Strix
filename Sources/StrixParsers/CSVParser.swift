import Foundation
import Strix

public typealias CSV = [[String]]

public struct CSVParser {
    private let parser: Parser<CSV>
    
    public init() {
        let ws = Parser.many(.whitespace)
        parser = ws *> Parser.csv <* ws <* .endOfStream
    }
    
    public func parse(_ csvString: String) throws -> CSV {
        return try parser.run(csvString)
    }
    
    public func callAsFunction(_ csvString: String) throws -> CSV {
        return try parse(csvString)
    }
}

extension Parser where T == CSV {
    public static var csv: Parser<CSV> { CSVParserGenerator().csv }
}

private struct CSVParserGenerator {
    var csv: Parser<CSV> { .many(record, separatedBy: .newline) }
    
    private var record: Parser<[String]> { .many(field, separatedBy: .character(",")) }
    
    private var field: Parser<String> { quotedField <|> nonQuotedField }
    
    private var quotedField: Parser<String> { quote *> quotedString <* quote }
    private var quotedString: Parser<String> {
        return Parser.many((.none(of: "\"") <|> doubleQuote)).map({ String($0) })
    }
    private let quote: Parser<Character> = .character("\"")
    private let doubleQuote: Parser<Character> = Parser.string("\"\"") *> .just("\"")
    
    private var nonQuotedField: Parser<String> { .skipped(by: .many(nonSeparator)) }
    private let nonSeparator: Parser<Character> = .satisfy({ $0 != "," && !$0.isNewline },
                                                           label: "non-separator")
}
