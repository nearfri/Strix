import Foundation

public struct ParserState: Equatable {
    public var stream: Substring
    public var userState: UserState
//    public var tag: Int = 0
    
    public init(stream: Substring, userState: UserState = .init()) {
        self.stream = stream
        self.userState = userState
    }
    
    public var position: Substring.Index {
        return stream.startIndex
    }
    
    public func withStream(_ newStream: Substring) -> ParserState {
        return .init(stream: newStream, userState: userState)
    }
}
