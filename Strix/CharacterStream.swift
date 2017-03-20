
import Foundation

public enum StringSensitivity {
    case sensitive
    case insensitive
}

open class CharacterStream {
    public typealias UserInfo = [String: Any]
    
    open let string: String
    open let startIndex: String.Index
    open let endIndex: String.Index
    open var stateTag: Int = 0
    open fileprivate(set) var nextIndex: String.Index {
        didSet { stateTag += 1 }
    }
    open var userInfo: UserInfo = [:] {
        didSet { stateTag += 1 }
    }
    open var name: String = "" {
        didSet { stateTag += 1 }
    }
    
    public init(string: String, bounds: Range<String.Index>) {
        self.string = string
        self.startIndex = bounds.lowerBound
        self.endIndex = bounds.upperBound
        self.nextIndex = startIndex
    }
    
    public convenience init(string: String) {
        self.init(string: string, bounds: string.startIndex..<string.endIndex)
    }
}

extension CharacterStream {
    open var isAtStart: Bool { return nextIndex == startIndex }
    open var isAtEnd: Bool { return nextIndex == endIndex }
    
    open func seek(to index: String.Index) {
        precondition(index >= startIndex, "index is less than startIndex")
        precondition(index <= endIndex, "index is greater than endIndex")
        nextIndex = index
    }
}

extension CharacterStream {
    open func peek() -> Character? {
        return isAtEnd ? nil : string[nextIndex]
    }
    
    open func peek(offset: String.IndexDistance) -> Character? {
        if let i = index(nextIndex, offsetBy: offset), i != endIndex {
            return string[i]
        }
        return nil
    }
    
    fileprivate func index(_ i: String.Index, offsetBy n: String.IndexDistance) -> String.Index? {
        let limit = n < 0 ? startIndex : endIndex
        return string.index(i, offsetBy: n, limitedBy: limit)
    }
    
    open func matches(_ c: Character) -> Bool {
        return matches({ $0 == c })
    }
    
    open func matches(_ predicate: (Character) -> Bool) -> Bool {
        return !isAtEnd && predicate(string[nextIndex])
    }
    
    open func matches(_ str: String, case caseSensitivity: StringSensitivity) -> Bool {
        return index(afterMatch: str, from: nextIndex, case: caseSensitivity) != nil
    }
    
    fileprivate func index(afterMatch str: String, from start: String.Index,
                           case caseSensitivity: StringSensitivity) -> String.Index? {
        assert(start >= startIndex, "start is less than startIndex")
        guard let end = string.index(start, offsetBy: str.characters.count, limitedBy: endIndex)
            else { return nil }
        
        let options: String.CompareOptions
        switch caseSensitivity {
        case .sensitive:    options = []
        case .insensitive:  options = .caseInsensitive
        }
        
        if string.compare(str, options: options, range: start..<end) == .orderedSame {
            return end
        }
        return nil
    }
    
    open func matches(_ regex: NSRegularExpression) -> NSTextCheckingResult? {
        func utf16IntRange(in str: String, from: String.Index, to: String.Index) -> Range<Int> {
            let utf16View = str.utf16
            let utf16From = from.samePosition(in: utf16View)
            let utf16To = to.samePosition(in: utf16View)
            let start = utf16View.distance(from: utf16View.startIndex, to: utf16From)
            let count = utf16View.distance(from: utf16From, to: utf16To)
            return start..<(start+count)
        }
        
        let range = NSRange(utf16IntRange(in: string, from: nextIndex, to: endIndex))
        return regex.firstMatch(in: string, options: [], range: range)
    }
}



