import Foundation
import Strix

public enum FormatSpecifier: Equatable {
    case percentSign
    case placeholder(FormatPlaceholder)
}

extension Parser where T == FormatSpecifier {
    public static var formatSpecifier: Parser<FormatSpecifier> {
        return FormatSpecifierParserGenerator().formatSpecifier
    }
}

private struct FormatSpecifierParserGenerator {
    private typealias Index = FormatPlaceholder.Index
    private typealias Flag = FormatPlaceholder.Flag
    private typealias Width = FormatPlaceholder.Width
    private typealias Precision = FormatPlaceholder.Precision
    private typealias Length = FormatPlaceholder.Length
    private typealias Conversion = FormatPlaceholder.Conversion
    
    var formatSpecifier: Parser<FormatSpecifier> {
        return .character("%") *> (percentSign <|> placeholder)
    }
    
    private let percentSign: Parser<FormatSpecifier> = .character("%") *> .just(.percentSign)
    
    private var placeholder: Parser<FormatSpecifier> {
        let fields = Parser.tuple(
            Parser.optional(index),
            Parser.many(flag),
            Parser.optional(width),
            Parser.optional(precision),
            Parser.optional(length),
            conversion)
        
        return fields.map { index, flag, width, precision, length, conversion in
            return .placeholder(
                FormatPlaceholder(
                    index: index,
                    flags: flag,
                    width: width,
                    precision: precision,
                    length: length,
                    conversion: conversion))
        }
    }
    
    private var index: Parser<Index> { .attempt(positiveInteger <* .character("$")) }
    
    private var positiveInteger: Parser<Int> {
        return decimalInteger.map { number in
            guard number > 0 else {
                throw ParseError.expected(label: "positive integer")
            }
            return number
        }
    }
    
    private let decimalInteger: Parser<Int> = {
        return .number(options: .allowSign) { literal in
            guard let number = literal.toValue(type: Int.self) else {
                throw ParseError.generic(message: "\(literal.string) is outside the Int range")
            }
            return number
        }
    }()
    
    private let flag: Parser<Flag> = {
        let allFlagChars = Flag.allCases.map(\.rawValue)
        return Parser.any(of: allFlagChars).map({ Flag(rawValue: $0)! })
    }()
    
    private var width: Parser<Width> {
        let staticWidth = decimalInteger.map({ Width.static($0) })
        let dynamicWidth = (.character("*") *> .optional(index)).map({ Width.dynamic($0) })
        return staticWidth <|> dynamicWidth
    }
    
    private var precision: Parser<Precision> { .character(".") *> width }
    
    private let length: Parser<Length> = {
        let allLengthCases = Length.allCases.sorted { $0.rawValue > $1.rawValue }
        let lengthParsers: [Parser<Length>] = allLengthCases.map { length in
            return .string(length.rawValue) *> .just(length)
        }
        let label = "any string in [\(Length.allCases.map(\.rawValue).joined(separator: ", "))]"
        return Parser.any(of: lengthParsers) <?> label
    }()
    
    private let conversion: Parser<Conversion> = {
        let allConversionChars = Conversion.allCases.map(\.rawValue)
        return Parser.any(of: allConversionChars).map({ Conversion(rawValue: $0)! })
    }()
}
