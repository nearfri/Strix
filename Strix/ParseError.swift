
open class ParseError: Error, CustomStringConvertible {
    public init() {
        
    }
    
    open var description: String {
        return "Unknown"
    }
}

extension ParseError {
    public class Expected: ParseError {
        public let label: String
        
        public init(_ label: String) {
            self.label = label
            super.init()
        }
        
        override public var description: String {
            return "Expected(\(label))"
        }
    }
    
    public class ExpectedString: ParseError {
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
    }
    
    public class Unexpected: ParseError {
        public let label: String
        
        public init(_ label: String) {
            self.label = label
            super.init()
        }
        
        override public var description: String {
            return "Unexpected(\(label))"
        }
    }
    
    public class UnexpectedString: ParseError {
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
    }
    
    public class Generic: ParseError {
        public let message: String
        
        public init(message: String) {
            self.message = message
            super.init()
        }
        
        override public var description: String {
            return "Generic(\(message))"
        }
    }
    
    public class Nested: ParseError {
        let position: TextPosition
        let userInfo: CharacterStream.UserInfo
        let errors: [Error]
        
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
        let label: String
        let position: TextPosition
        let userInfo: CharacterStream.UserInfo
        let errors: [Error]
        
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



