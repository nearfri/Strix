import Foundation
import Strix

struct ASCIIPlistParser {
    private let parser: Parser<ASCIIPlist>
    
    init() {
        let ws = Parser.many(.whitespace)
        parser =  ws *> Parser.plist <* ws <* .endOfStream
    }
    
    func parse(_ plistString: String) throws -> ASCIIPlist {
        return try parser.run(plistString)
    }
    
    func callAsFunction(_ plistString: String) throws -> ASCIIPlist {
        return try parse(plistString)
    }
}

extension Parser where T == ASCIIPlist {
    static var plist: Parser<ASCIIPlist> { ASCIIPlistParserGenerator().make() }
}

struct ASCIIPlistParserGenerator {
    private typealias DictionaryEntry = ASCIIPlist.DictionaryEntry
    
    func make() -> Parser<ASCIIPlist> {
        return rootPlist
    }
    
    private var rootPlist: Parser<ASCIIPlist> {
        return .attempt(dictionaryContent(minCount: 1)) <|> plist
    }
    
    private var plist: Parser<ASCIIPlist> {
        let anyNode = Parser.any(of: [dictionaryNode, arrayNode, stringNode, dataNode])
        return manyComment *> ws *> anyNode <* ws <* manyComment
    }
    
    private var dictionaryNode: Parser<ASCIIPlist> {
        return .character("{") *> ws *> dictionaryContent(minCount: 0) <* .character("}")
    }
    
    private func dictionaryContent(minCount: Int) -> Parser<ASCIIPlist> {
        let entryAndSeparator = dictionaryEntry <* ws <* .character(";") <* ws
        return Parser.many(entryAndSeparator, minCount: minCount).map({ .dictionary($0) })
            <* manyComment
    }
    
    private var dictionaryEntry: Parser<DictionaryEntry> {
        return Parser { [manyComment, dictionaryPair] state in
            let commentReply = manyComment.map({ $0.last }).parse(state)
            if case let .failure(errors) = commentReply.result {
                return .failure(errors, commentReply.state)
            }
            
            let pairReply = dictionaryPair.parse(commentReply.state)
            switch pairReply.result {
            case let .success(pair, errors):
                let comment: String? = commentReply.result.value ?? nil
                let entry = DictionaryEntry(comment: comment, key: pair.0, value: pair.1)
                return .success(entry, errors, pairReply.state)
            case let .failure(errors):
                let resultState = pairReply.state != commentReply.state ? pairReply.state : state
                return .failure(errors, resultState)
            }
        }
    }
    
    private var dictionaryPair: Parser<(String, ASCIIPlist)> {
        return .tuple(stringOrWord <* ws <* manyComment,
                      .character("=") *> ws *> manyComment *> .lazy(plist))
    }
    
    private var arrayNode: Parser<ASCIIPlist> {
        return .character("(") *> ws *> arrayContent <* .character(")")
    }
    
    private var arrayContent: Parser<ASCIIPlist> {
        return Parser.many(
            .lazy(plist) <* ws,
            separatedBy: .character(",") *> ws,
            allowEndBySeparator: true
        )
        .map({ .array($0) })
    }
    
    private var stringNode: Parser<ASCIIPlist> { stringOrWord.map({ .string($0) }) }
    private var dataNode: Parser<ASCIIPlist> { data.map({ .data($0) }) }
    
    private let ws: Parser<[Character]> = .many(.whitespace)
    private let hex: Parser<Character> = .hexadecimalDigit
    
    private var manyComment: Parser<[String]> {
        return Parser.many(comment <* ws)
    }
    
    private var comment: Parser<String> {
        let singleLine = .string("//") *> .restOfLine()
        let multiline = .string("/*") *> .string(until: "*/", skipBoundary: true)
        return (singleLine <|> multiline).map({ $0.trimmingCharacters(in: .whitespaces) })
    }
    
    private var stringOrWord: Parser<String> { stringLiteral <|> word }
    
    private var stringLiteral: Parser<String> {
        let text = Parser.many(nonEscape <|> escape).map({ String($0) })
        return .character("\"") *> text <* .character("\"")
    }
    
    private var nonEscape: Parser<Character> {
        return .satisfy({ $0 != "\"" && $0 != "\\" }, label: "non-escaped character")
    }
    
    private var escape: Parser<Character> {
        let escapeMap: [Character: Character] = [
            "b": "\u{0008}", "f": "\u{000C}", "n": "\n", "r": "\r", "t": "\t"
        ]
        let asciiEscape: Parser<Character> = Parser.any(of: "\"\\bfnrt").map {
            return escapeMap[$0] ?? $0
        }
        
        return .character("\\") *> (asciiEscape <|> .anyCharacter)
    }
    
    private var word: Parser<String> {
        return .skipped(by: .many(.asciiLetter <|> .decimalDigit, minCount: 1))
    }
    
    private var data: Parser<Data> {
        let uint8: Parser<UInt8> = Parser.tuple(hex, hex)
            .map({ UInt8(String([$0, $1]), radix: 16)! })
        
        let bytes: Parser<Data> = Parser { state in
            var data = Data()
            let byte: Parser<Void> = uint8.map({ data.append($0) })
            let skipWS: Parser<Void> = .skip(.notEmpty(ws))
            return Parser.many(byte <|> skipWS).parse(state).map({ _ in data })
        }
        
        return .character("<") *> bytes <* .character(">")
    }
}
