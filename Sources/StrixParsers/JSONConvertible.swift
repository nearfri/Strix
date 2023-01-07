import Foundation

public protocol JSONConvertible {
    func jsonValue() -> JSON
}

extension Dictionary<String, JSONConvertible>: JSONConvertible {
    public func jsonValue() -> JSON {
        return .dictionary(mapValues({ $0.jsonValue() }))
    }
}

extension Array<JSONConvertible>: JSONConvertible {
    public func jsonValue() -> JSON {
        return .array(map({ $0.jsonValue() }))
    }
}

extension String: JSONConvertible {
    public func jsonValue() -> JSON {
        return .string(self)
    }
}

extension Double: JSONConvertible {
    public func jsonValue() -> JSON {
        return .number(NSNumber(value: self))
    }
}

extension Int: JSONConvertible {
    public func jsonValue() -> JSON {
        return .number(NSNumber(value: self))
    }
}

extension Bool: JSONConvertible {
    public func jsonValue() -> JSON {
        return .bool(self)
    }
}

extension NSNull: JSONConvertible {
    public func jsonValue() -> JSON {
        return .null
    }
}
