import Foundation

@dynamicMemberLookup
public enum JSON: Equatable {
    case object([String: JSON])
    case array([JSON])
    case string(String)
    case number(NSNumber)
    case bool(Bool)
    case null
    
    public subscript(dynamicMember member: String) -> JSON? {
        return self[member]
    }
}

// MARK: -

extension JSON {
    public subscript(key: String) -> JSON? {
        if case .object(let obj) = self {
            return obj[key]
        }
        return nil
    }
    
    public subscript(index: Int) -> JSON? {
        if case .array(let arr) = self {
            return index < arr.count ? arr[index] : nil
        }
        return nil
    }
    
    public var stringValue: String? {
        if case .string(let str) = self {
            return str
        }
        return nil
    }
    
    public var numberValue: NSNumber? {
        if case .number(let num) = self {
            return num
        }
        return nil
    }
    
    public var doubleValue: Double? {
        return self.numberValue?.doubleValue
    }
    
    public var intValue: Int? {
        return self.numberValue?.intValue
    }
    
    public var boolValue: Bool? {
        if case .bool(let boolean) = self {
            return boolean
        }
        return nil
    }
}

// MARK: -

extension JSON {
    public init(data: Data) throws {
        let jsonObject = try JSONSerialization.jsonObject(with: data)
        try self.init(jsonObject: jsonObject)
    }
    
    public init(jsonObject: Any) throws {
        switch jsonObject {
        case is NSNull:
            self = .null
        case let bool as CFBoolean where CFGetTypeID(bool) == CFBooleanGetTypeID():
            // number는 boolean으로 변환될 수 있으므로 타입까지 체크.
            self = .bool(CFBooleanGetValue(bool))
        case let number as NSNumber:
            self = .number(number)
        case let string as String:
            self = .string(string)
        case let array as [Any]:
            self = .array(try array.map { try JSON(jsonObject: $0) })
        case let object as [String: Any]:
            self = .object(try object.mapValues { try JSON(jsonObject: $0) })
        default:
            throw InvalidTypeError(type: type(of: jsonObject), value: jsonObject)
        }
    }
    
    public struct InvalidTypeError: Error {
        let type: Any.Type
        let value: Any
    }
}

// MARK: -

extension JSON: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, JSON)...) {
        self = .object(Dictionary(uniqueKeysWithValues: elements))
    }
}

extension JSON: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: JSON...) {
        self = .array(elements)
    }
}

extension JSON: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .string(value)
    }
}

extension JSON: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self = .number(NSNumber(value: value))
    }
}

extension JSON: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .number(NSNumber(value: value))
    }
}

extension JSON: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self = .bool(value)
    }
}

// MARK: -

extension JSON: CustomStringConvertible {
    public var description: String {
        return JSONFormatter.string(from: self)
    }
}

private struct JSONFormatter {
    private var text: String = ""
    private var indent: Indent = Indent()
    
    static func string(from json: JSON, indentWidth: Int = 4) -> String {
        var formatter = JSONFormatter()
        formatter.indent.width = indentWidth
        formatter.write(json)
        return formatter.text
    }
    
    private init() {}
    
    private mutating func write(_ json: JSON) {
        switch json {
        case .object(let obj):
            self.write(obj)
        case .array(let arr):
            self.write(arr)
        case .string(let str):
            self.text.write("\"\(str)\"")
        case .number(let num):
            self.text.write(num.description)
        case .bool(let boolean):
            self.text.write(boolean.description)
        case .null:
            self.text.write("null")
        }
    }
    
    private mutating func write(_ object: [String: JSON]) {
        if object.isEmpty {
            self.text.write("{}")
            return
        }
        
        self.text.write("{\n")
        self.indent.level += 1
        
        for (index, (key, json)) in object.enumerated() {
            let isLastElement = index + 1 == object.count
            self.text.write("\(self.indent.string)\"\(key)\": ")
            self.write(json)
            self.text.write(isLastElement ? "\n" : ",\n")
        }
        
        self.indent.level -= 1
        self.text.write("\(self.indent.string)}")
    }
    
    private mutating func write(_ array: [JSON]) {
        if array.isEmpty {
            self.text.write("[]")
            return
        }
        
        self.text.write("[\n")
        self.indent.level += 1
        
        for (index, json) in array.enumerated() {
            let isLastElement = index + 1 == array.count
            self.text.write(self.indent.string)
            self.write(json)
            self.text.write(isLastElement ? "\n" : ",\n")
        }
        
        self.indent.level -= 1
        self.text.write("\(self.indent.string)]")
    }
}

private struct Indent {
    var level: Int = 0
    var width: Int = 4
    
    var string: String {
        return String(repeating: " ", count: level * width)
    }
}
