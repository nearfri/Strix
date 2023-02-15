import Foundation

public protocol JSONConvertibleValue {}

extension Optional: JSONConvertibleValue where Wrapped: JSONConvertibleValue {}

extension Dictionary<String, JSONConvertibleValue>: JSONConvertibleValue {}

extension Array<JSONConvertibleValue>: JSONConvertibleValue {}

extension String: JSONConvertibleValue {}

extension Double: JSONConvertibleValue {}

extension Int: JSONConvertibleValue {}

extension Bool: JSONConvertibleValue {}
