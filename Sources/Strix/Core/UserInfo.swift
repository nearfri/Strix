import Foundation

public protocol UserInfoKey {
    associatedtype Value: Hashable
    
    static var defaultValue: Value { get }
}

public struct UserInfo: Equatable {
    private var dictionary: [ObjectIdentifier: AnyHashable] = [:]
    
    public init() {}
    
    public subscript<Key: UserInfoKey>(key: Key.Type) -> Key.Value {
        get {
            let id = ObjectIdentifier(Key.self)
            return (dictionary[id]?.base as? Key.Value) ?? Key.defaultValue
        }
        set {
            let id = ObjectIdentifier(Key.self)
            dictionary[id] = AnyHashable(newValue)
        }
    }
}
