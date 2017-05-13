
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
            info.calculate(with: string, index: index)
        }
    }
}

extension TextPosition {
    fileprivate class Info {
        private static let invalidNumber: Int = -1
        
        var lineNumber: Int = Info.invalidNumber
        var columnNumber: Int = Info.invalidNumber
        var substring: String = ""
        
        var isCalculated: Bool {
            return lineNumber != Info.invalidNumber
        }
        
        func calculate(with string: String, index: String.Index) {
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
                    self.columnNumber = string[subRange.lowerBound..<index].characters.count + 1
                    self.substring = string[subRange]
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



