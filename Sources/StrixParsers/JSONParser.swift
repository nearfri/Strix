import Foundation
import Strix

public struct JSONParser {
    private let parser: Parser<JSON>
    
    public init() {
        let ws = Parser.many(.whitespace)
        parser = ws *> Parser.json <* ws <* .endOfStream
    }
    
    public func parse(_ jsonString: String) throws -> JSON {
        return try parser.run(jsonString)
    }
    
    public func callAsFunction(_ jsonString: String) throws -> JSON {
        return try parse(jsonString)
    }
}

extension Parser where T == JSON {
    public static var json: Parser<JSON> { JSONParserGenerator().json }
}

private struct JSONParserGenerator {
    var json: Parser<JSON> {
        return .recursive { placeholder in
            return .any(of: [
                dictionaryJSON(json: placeholder), arrayJSON(json: placeholder),
                stringJSON, numberJSON, trueJSON, falseJSON, nullJSON
            ])
        }
    }
    
    private func dictionaryJSON(json: Parser<JSON>) -> Parser<JSON> {
        let pair: Parser<(String, JSON)> = .tuple(stringLiteral <* ws, colon *> ws *> json)
        let pairs: Parser<[String: JSON]> = Parser.many(pair <* ws, separatedBy: comma *> ws).map {
            Dictionary($0, uniquingKeysWith: { _, last in last })
        }
        return (.character("{") *> ws *> pairs <* .character("}")).map({ .dictionary($0) })
    }
    
    private func arrayJSON(json: Parser<JSON>) -> Parser<JSON> {
        let values: Parser<[JSON]> = Parser.many(json <* ws, separatedBy: comma *> ws)
        return (.character("[") *> ws *> values <* .character("]")).map({ .array($0) })
    }
    
    private var stringJSON: Parser<JSON> { stringLiteral.map({ .string($0) }) }
    private let numberJSON: Parser<JSON> = Parser.number().map({ .number($0) })
    private let trueJSON: Parser<JSON> = .string("true") *> .just(.bool(true))
    private let falseJSON: Parser<JSON> = .string("false") *> .just(.bool(false))
    private let nullJSON: Parser<JSON> = .string("null") *> .just(.null)
    
    private let ws: Parser<[Character]> = .many(.whitespace)
    private let hex: Parser<Character> = .hexadecimalDigit
    private let colon: Parser<Character> = .character(":")
    private let comma: Parser<Character> = .character(",")
    
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
        let asciiEscape: Parser<Character> = Parser.any(of: "\"\\/bfnrt").map {
            return escapeMap[$0] ?? $0
        }
        
        let unicodeEscape: Parser<Character> = (.character("u") *> .tuple(hex, hex, hex, hex)).map {
            let scalar = Int(String([$0, $1, $2, $3]), radix: 16).flatMap({ UnicodeScalar($0) })
            return Character(scalar ?? UnicodeScalar(0))
        }
        
        return .character("\\") *> (asciiEscape <|> unicodeEscape)
    }
}
