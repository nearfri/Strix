import Foundation

// https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/PropertyLists/OldStylePlists/OldStylePLists.html
// XML 같이 집합 타입으로 array만 있는 건 주석을 지원하기 쉽지만,
// JSON 같이 dictionary를 포함하는 타입은 주석을 지원하는게 구조적으로 쉽지 않다.
// 본래 ASCII property list에서 주석은 어디에도 있을 수 있지만, 여기선 key-value pair 앞에 있는 것만 저장하도록 한다.
// Localizable.strings 파일을 다루는데는 이 정도면 충분하다.

public enum ASCIIPlist: Equatable {
    case string(String)
    case data(Data)
    case array([ASCIIPlist])
    case dictionary([DictionaryEntry])
}

extension ASCIIPlist {
    public struct DictionaryEntry: Equatable {
        var comment: String?
        var key: String
        var value: ASCIIPlist
    }
}

extension ASCIIPlist: CustomStringConvertible {
    public var description: String {
        return ASCIIPlistFormatter.string(from: self, omittingBracesAtRoot: true)
    }
}

private struct ASCIIPlistFormatter {
    private var text: String = ""
    private var indent: Indent = Indent()
    private let omitsBracesAtRoot: Bool
    
    static func string(from plist: ASCIIPlist,
                       indentWidth: Int = 4,
                       omittingBracesAtRoot: Bool
    ) -> String {
        var formatter = ASCIIPlistFormatter(omitsBracesAtRoot: omittingBracesAtRoot)
        formatter.indent.width = indentWidth
        formatter.write(plist)
        return formatter.text
    }
    
    private mutating func write(_ plist: ASCIIPlist) {
        switch plist {
        case let .string(str):
            text.write("\"\(str.addingBackslashEncoding())\"")
        case let .data(data):
            text.write("<\(data.hexStringRepresentation())>")
        case let .array(arr):
            write(arr)
        case let .dictionary(dict):
            write(dict)
        }
    }
    
    private mutating func write(_ array: [ASCIIPlist]) {
        if array.isEmpty {
            text.write("()")
            return
        }
        
        text.write("(\n")
        indent.level += 1
        
        for (index, plist) in array.enumerated() {
            let isLastElement = index + 1 == array.count
            text.write(indent.string)
            write(plist)
            text.write(isLastElement ? "\n" : ",\n")
        }
        
        indent.level -= 1
        text.write("\(indent.string))")
    }
    
    private mutating func write(_ dictionary: [ASCIIPlist.DictionaryEntry]) {
        if dictionary.isEmpty {
            if !text.isEmpty {
                text.write("{}")
            }
            return
        }
        
        let needsBraces = !omitsBracesAtRoot || !text.isEmpty
        
        if needsBraces {
            text.write("{\n")
            indent.level += 1
        }
        
        for (index, entry) in dictionary.enumerated() {
            if let comment = entry.comment {
                if index != 0 {
                    text.write("\(indent.string)\n")
                }
                text.write("\(indent.string)/* \(comment.addingBackslashEncoding()) */\n")
            }
            text.write("\(indent.string)\"\(entry.key)\" = ")
            write(entry.value)
            
            let isLastElement = index + 1 == dictionary.count
            text.write(isLastElement && !needsBraces ? ";" : ";\n")
        }
        
        if needsBraces {
            indent.level -= 1
            text.write("\(indent.string)}")
        }
    }
}
