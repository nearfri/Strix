
import Foundation

public struct CharacterPosition {
    public let string: String
    public let index: String.Index
    private let info: Info = Info()
    
    public var line: Int {
        calculateInfoIfNeeded()
        return info.line
    }
    
    public var column: Int {
        calculateInfoIfNeeded()
        return info.column
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
        var line: Int = -1
        var column: Int = -1
        var substring: String = ""
        
        var isCalculated: Bool {
            return line != -1
        }
        
        func calculate(with string: String, index: String.Index) {
            var enumerationCount = 0
            string.enumerateSubstrings(in: string.startIndex..<string.endIndex,
                                       options: [.byLines, .substringNotRequired])
            { (substr, subRange, enclosingRange, stop) in
                let upperBound = enclosingRange.upperBound
                if index < upperBound || (index == upperBound && index == string.endIndex) {
                    stop = true
                    self.line = enumerationCount
                    self.column = string[subRange.lowerBound..<index].characters.count
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



