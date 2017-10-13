
import Foundation

public enum StringSensitivity {
    case sensitive
    case insensitive
}

extension String {
    public func compare(_ aString: String, case caseSensitivity: StringSensitivity,
                        range: Range<String.Index>, locale: Locale? = nil) -> ComparisonResult {
        let options: String.CompareOptions
        switch caseSensitivity {
        case .sensitive:    options = []
        case .insensitive:  options = .caseInsensitive
        }
        return compare(aString, options: options, range: range, locale: locale)
    }
}

public class CharacterStream {
    public typealias UserInfo = [String: Any]
    
    public let string: String
    public let startIndex: String.Index
    public let endIndex: String.Index
    public var stateTag: Int = 0
    public private(set) var nextIndex: String.Index {
        didSet { stateTag += 1 }
    }
    public var userInfo: UserInfo = [:] {
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
    public var isAtStart: Bool { return nextIndex == startIndex }
    public var isAtEnd: Bool { return nextIndex == endIndex }
    
    public func seek(to index: String.Index) {
        precondition(index >= startIndex, "index is less than startIndex")
        precondition(index <= endIndex, "index is greater than endIndex")
        nextIndex = index
    }
}

extension CharacterStream {
    public func peek() -> Character? {
        return isAtEnd ? nil : string[nextIndex]
    }
    
    public func peek(offset: String.IndexDistance) -> Character? {
        if let i = index(from: nextIndex, offset: offset), i != endIndex {
            return string[i]
        }
        return nil
    }
    
    private func index(from i: String.Index, offset: String.IndexDistance) -> String.Index? {
        let limit = offset < 0 ? startIndex : endIndex
        return string.index(i, offsetBy: offset, limitedBy: limit)
    }
}

extension CharacterStream {
    public typealias Section = (range: Range<String.Index>, count: String.IndexDistance)
    
    public func matches(_ c: Character) -> Bool {
        return matches({ $0 == c })
    }
    
    public func matches(_ predicate: (Character) throws -> Bool) rethrows -> Bool {
        return try !isAtEnd && predicate(string[nextIndex])
    }
    
    public func matches(_ str: String, case caseSensitivity: StringSensitivity) -> Bool {
        guard let end = index(from: nextIndex, offset: str.count) else {
            return false
        }
        return string.compare(str, case: caseSensitivity, range: nextIndex..<end) == .orderedSame
    }
    
    public func matches(minCount: String.IndexDistance, maxCount: String.IndexDistance = .max,
                        while predicate: (Character) throws -> Bool) rethrows -> Section? {
        let section = try matches(maxCount: maxCount, while: predicate)
        return section.count >= minCount ? section : nil
    }
    
    public func matches(maxCount: String.IndexDistance = .max,
                        while predicate: (Character) throws -> Bool) rethrows -> Section {
        var count = 0
        var index = nextIndex
        
        while count != maxCount, index != endIndex, try predicate(string[index]) {
            count += 1
            index = string.index(after: index)
        }
        
        return (nextIndex..<index, count)
    }
    
    public func matches(_ regex: NSRegularExpression) -> NSTextCheckingResult? {
        func utf16IntRange(in str: String, from: String.Index, to: String.Index) -> Range<Int> {
            let utf16View = str.utf16
            let start = utf16View.distance(from: str.startIndex, to: from)
            let count = utf16View.distance(from: from, to: to)
            return start..<(start+count)
        }
        
        let range = NSRange(utf16IntRange(in: string, from: nextIndex, to: endIndex))
        return regex.firstMatch(in: string, options: [], range: range)
    }
}

extension CharacterStream {
    public func skip() {
        if isAtEnd { return }
        nextIndex = string.index(after: nextIndex)
    }
    
    @discardableResult
    public func skip(_ c: Character) -> Bool {
        return skip({ $0 == c })
    }
    
    @discardableResult
    public func skip(_ predicate: (Character) throws -> Bool) rethrows -> Bool {
        guard try matches(predicate) else { return false }
        nextIndex = string.index(after: nextIndex)
        return true
    }
    
    @discardableResult
    public func skip(_ str: String, case caseSensitivity: StringSensitivity) -> Bool {
        guard let end = index(from: nextIndex, offset: str.count) else {
            return false
        }
        if string.compare(str, case: caseSensitivity, range: nextIndex..<end) != .orderedSame {
            return false
        }
        nextIndex = end
        return true
    }
    
    @discardableResult
    public func skip(minCount: String.IndexDistance, maxCount: String.IndexDistance = .max,
                     while predicate: (Character) throws -> Bool) rethrows -> Section? {
        guard let result = try matches(minCount: minCount, maxCount: maxCount, while: predicate)
            else { return nil }
        nextIndex = result.range.upperBound
        return result
    }
    
    @discardableResult
    public func skip(maxCount: String.IndexDistance = .max,
                     while predicate: (Character) throws -> Bool) rethrows -> Section {
        let result = try matches(maxCount: maxCount, while: predicate)
        nextIndex = result.range.upperBound
        return result
    }
}

extension CharacterStream {
    public func read() -> Character? {
        if isAtEnd { return nil }
        let result = string[nextIndex]
        nextIndex = string.index(after: nextIndex)
        return result
    }
    
    public func readUpToNextIndex(from index: String.Index) -> Substring {
        precondition(index <= nextIndex, "index is more than nextIndex")
        precondition(index >= startIndex, "index is less than startIndex")
        return string[index..<nextIndex]
    }
    
    public func read(_ str: String, case caseSensitivity: StringSensitivity) -> Substring? {
        let start = nextIndex
        if skip(str, case: caseSensitivity) {
            return string[start..<nextIndex]
        }
        return nil
    }
    
    public func read(minCount: String.IndexDistance, maxCount: String.IndexDistance = .max,
                     while predicate: (Character) throws -> Bool) rethrows -> Substring? {
        guard let section = try skip(minCount: minCount, maxCount: maxCount, while: predicate)
            else { return nil }
        return string[section.range]
    }
    
    public func read(maxCount: String.IndexDistance = .max,
                     while predicate: (Character) throws -> Bool) rethrows -> Substring {
        let section = try skip(maxCount: maxCount, while: predicate)
        return string[section.range]
    }
}

extension CharacterStream {
    public struct State {
        fileprivate let stream: CharacterStream
        public let tag: Int
        public let index: String.Index
        public let userInfo: UserInfo
        
        public init(stream: CharacterStream) {
            self.stream = stream
            tag = stream.stateTag
            index = stream.nextIndex
            userInfo = stream.userInfo
        }
    }
    
    public var state: State {
        return State(stream: self)
    }
    
    public func backtrack(to state: State) {
        assert(state.stream === self, "stream is different")
        nextIndex = state.index
        userInfo = state.userInfo
        stateTag = state.tag
    }
}

extension CharacterStream {
    public var position: TextPosition {
        return TextPosition(string: string, index: nextIndex)
    }
}

extension CharacterStream: CustomStringConvertible {
    public var description: String {
        let pos = position
        return "CharacterStream(\(pos.lineNumber):\(pos.columnNumber), "
            + "substring: \"\(pos.substring)\", userInfo: \(userInfo))"
    }
}

extension CharacterStream.State: CustomStringConvertible {
    public var description: String {
        let pos = TextPosition(string: stream.string, index: index)
        return "CharacterStream.State(\(pos.lineNumber):\(pos.columnNumber), "
            + "substring: \"\(pos.substring)\", tag: \(tag), userInfo: \(userInfo))"
    }
}



