
import Foundation

public struct CharacterPosition {
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

extension CharacterPosition {
    fileprivate class Info {
        var lineNumber: Int = -1
        var columnNumber: Int = -1
        var substring: String = ""
        
        var isCalculated: Bool {
            return lineNumber != -1
        }
        
        func calculate(with string: String, index: String.Index) {
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

extension CharacterPosition: Comparable {
    public static func == (lhs: CharacterPosition, rhs: CharacterPosition) -> Bool {
        return lhs.string == rhs.string
            && lhs.index == rhs.index
    }
    
    public static func < (lhs: CharacterPosition, rhs: CharacterPosition) -> Bool {
        return lhs.string == rhs.string
            && lhs.index < rhs.index
    }
}



