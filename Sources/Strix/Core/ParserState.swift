import Foundation

public struct ParserState: Equatable {
    public var stream: Substring
    public var userInfo: UserInfo
//    public var tag: Int = 0
    
    public init(stream: Substring, userInfo: UserInfo = .init()) {
        self.stream = stream
        self.userInfo = userInfo
    }
    
    public var position: Substring.Index {
        return stream.startIndex
    }
    
    public func withStream(_ newStream: Substring) -> ParserState {
        return .init(stream: newStream, userInfo: userInfo)
    }
}
