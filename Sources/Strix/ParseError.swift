
open class ParseError: Error, CustomStringConvertible {
    public init() {
        
    }
    
    open var description: String {
        return "Unknown"
    }
}

extension ParseError {
    public class Expected: ParseError, Comparable {
        public let label: String
        
        public init(_ label: String) {
            self.label = label
            super.init()
        }
        
        override public var description: String {
            return "Expected(\(label))"
        }
        
        public static func == (lhs: Expected, rhs: Expected) -> Bool {
            return lhs.label == rhs.label
        }
        
        public static func < (lhs: Expected, rhs: Expected) -> Bool {
            return lhs.label < rhs.label
        }
    }
    
    public class ExpectedString: ParseError, Comparable {
        public let string: String
        public let caseSensitivity: StringSensitivity
        
        public init(_ string: String, case caseSensitivity: StringSensitivity) {
            self.string = string
            self.caseSensitivity = caseSensitivity
            super.init()
        }
        
        override public var description: String {
            switch caseSensitivity {
            case .sensitive:
                return "ExpectedCaseSensitive(\(string))"
            case .insensitive:
                return "ExpectedCaseInsensitive(\(string))"
            }
        }
        
        public static func == (lhs: ExpectedString, rhs: ExpectedString) -> Bool {
            return lhs.caseSensitivity == rhs.caseSensitivity
                && lhs.string == rhs.string
        }
        
        public static func < (lhs: ExpectedString, rhs: ExpectedString) -> Bool {
            switch (lhs.caseSensitivity, rhs.caseSensitivity) {
            case (.sensitive, .sensitive), (.insensitive, .insensitive):
                return lhs.string < rhs.string
            case (.sensitive, .insensitive):
                return true
            case (.insensitive, .sensitive):
                return false
            }
        }
    }
    
    public class Unexpected: ParseError, Comparable {
        public let label: String
        
        public init(_ label: String) {
            self.label = label
            super.init()
        }
        
        override public var description: String {
            return "Unexpected(\(label))"
        }
        
        public static func == (lhs: Unexpected, rhs: Unexpected) -> Bool {
            return lhs.label == rhs.label
        }
        
        public static func < (lhs: Unexpected, rhs: Unexpected) -> Bool {
            return lhs.label < rhs.label
        }
    }
    
    public class UnexpectedString: ParseError, Comparable {
        public let string: String
        public let caseSensitivity: StringSensitivity
        
        public init(_ string: String, case caseSensitivity: StringSensitivity) {
            self.string = string
            self.caseSensitivity = caseSensitivity
            super.init()
        }
        
        override public var description: String {
            switch caseSensitivity {
            case .sensitive:
                return "UnexpectedCaseSensitive(\(string))"
            case .insensitive:
                return "UnexpectedCaseInsensitive(\(string))"
            }
        }
        
        public static func == (lhs: UnexpectedString, rhs: UnexpectedString) -> Bool {
            return lhs.caseSensitivity == rhs.caseSensitivity
                && lhs.string == rhs.string
        }
        
        public static func < (lhs: UnexpectedString, rhs: UnexpectedString) -> Bool {
            switch (lhs.caseSensitivity, rhs.caseSensitivity) {
            case (.sensitive, .sensitive), (.insensitive, .insensitive):
                return lhs.string < rhs.string
            case (.sensitive, .insensitive):
                return true
            case (.insensitive, .sensitive):
                return false
            }
        }
    }
    
    public class Generic: ParseError, Comparable {
        public let message: String
        
        public init(message: String) {
            self.message = message
            super.init()
        }
        
        override public var description: String {
            return "Generic(\(message))"
        }
        
        public static func == (lhs: Generic, rhs: Generic) -> Bool {
            return lhs.message == rhs.message
        }
        
        public static func < (lhs: Generic, rhs: Generic) -> Bool {
            return lhs.message < rhs.message
        }
    }
    
    public class Nested: ParseError {
        public let position: TextPosition
        public let userInfo: CharacterStream.UserInfo
        public let errors: [Error]
        
        public init(position: TextPosition,
                    userInfo: CharacterStream.UserInfo,
                    errors: [Error]) {
            self.position = position
            self.userInfo = userInfo
            self.errors = errors
            super.init()
        }
        
        override public var description: String {
            return "Nested(\(position.lineNumber):\(position.columnNumber), \(errors))"
        }
    }
    
    public class Compound: ParseError {
        public let label: String
        public let position: TextPosition
        public let userInfo: CharacterStream.UserInfo
        public let errors: [Error]
        
        public init(label: String,
                    position: TextPosition,
                    userInfo: CharacterStream.UserInfo,
                    errors: [Error]) {
            self.label = label
            self.position = position
            self.userInfo = userInfo
            self.errors = errors
            super.init()
        }
        
        override public var description: String {
            return "Compound(\(label), \(position.lineNumber):\(position.columnNumber), \(errors))"
        }
    }
}



