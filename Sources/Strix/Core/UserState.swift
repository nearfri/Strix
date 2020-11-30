import Foundation

public struct UserStateKey: Hashable, ExpressibleByStringLiteral {
    public var rawValue: String
    
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
    
    public init(stringLiteral value: String) {
        self.rawValue = value
    }
}

public struct UserState: Equatable {
    private var dictionary: [UserStateKey: AnyHashable] = [:]
    
    public init() {}
    
    public subscript(key: UserStateKey) -> AnyHashable? {
        get { dictionary[key] }
        set { dictionary[key] = newValue }
    }
}
