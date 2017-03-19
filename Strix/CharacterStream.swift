
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
    
    open func peek() -> Character? {
        return isAtEnd ? nil : string[nextIndex]
    }
    
    open func peek(offset: String.IndexDistance) -> Character? {
        let limit = offset < 0 ? startIndex : endIndex
        if let i = string.index(nextIndex, offsetBy: offset, limitedBy: limit), i != endIndex {
            return string[i]
        }
        return nil
    }
}



