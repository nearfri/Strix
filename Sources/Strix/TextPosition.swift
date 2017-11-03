
public struct TextPosition {
    public let string: String
    public let index: String.Index
    private let info: Info = Info()
    
    public var lineNumber: Int {
        calculateInfoIfNeeded()
        return info.lineNumber
    }
    
    public var columnNumber: Int {
        calculateInfoIfNeeded()
        return info.columnNumber
    }
    
    public var substring: String {
        calculateInfoIfNeeded()
        return info.substring
    }
    
    private func calculateInfoIfNeeded() {
        if !info.isCalculated {
            info.calculate(string: string, index: index)
        }
    }
}

extension TextPosition: CustomStringConvertible {
    public var description: String {
        return "line: \(lineNumber), column: \(columnNumber), substring: \"\(substring)\""
    }
}

extension TextPosition {
    private class Info {
        private static let invalidNumber: Int = -1
        
        var lineNumber: Int = Info.invalidNumber
        var columnNumber: Int = Info.invalidNumber
        var substring: String = ""
        
        var isCalculated: Bool {
            return lineNumber != Info.invalidNumber
        }
        
        func calculate(string: String, index: String.Index) {
            lineNumber = 1
            columnNumber = 1
            var enumerationCount = 0
            string.enumerateSubstrings(in: string.startIndex..<string.endIndex,
                                       options: [.byLines, .substringNotRequired])
            { (substr, subRange, enclosingRange, stop) in
                let upperBound = enclosingRange.upperBound
                if index < upperBound || (index == upperBound && index == string.endIndex) {
                    stop = true
                    self.lineNumber = enumerationCount + 1
                    self.columnNumber = string[subRange.lowerBound..<index].count + 1
                    self.substring = String(string[subRange])
                }
                enumerationCount += 1
            }
        }
    }
}

extension TextPosition: Comparable {
    public static func == (lhs: TextPosition, rhs: TextPosition) -> Bool {
        return lhs.string == rhs.string
            && lhs.index == rhs.index
    }
    
    public static func < (lhs: TextPosition, rhs: TextPosition) -> Bool {
        return lhs.string == rhs.string
            && lhs.index < rhs.index
    }
}

extension TextPosition {
    var columnMarker: String? {
        let tab: UnicodeScalar = "\t"
        let printableASCIIRange: ClosedRange<UnicodeScalar> = " "..."~"
        
        var result = ""
        for scalar in substring.unicodeScalars.prefix(columnNumber-1) {
            // ASCII 외의 문자는 어떻게 프린트될지 모르므로 nil을 리턴한다
            guard scalar.isASCII else { return nil }
            
            switch scalar {
            case tab:
                result.append("\t")
            case printableASCIIRange:
                result.append(" ")
            default:
                // 그 외 제어 문자는 프린트 되지 않으므로 아무 것도 더하지 않는다
                break
            }
        }
        result.append("^")
        return result
    }
}



