import Foundation

// https://developer.apple.com/library/archive/documentation/CoreFoundation/Conceptual/CFStrings/formatSpecifiers.html
// https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPInternational/StringsdictFileFormat/StringsdictFileFormat.html
// https://en.wikipedia.org/wiki/Printf_format_string
// https://pubs.opengroup.org/onlinepubs/9699919799/functions/printf.html
// http://man.openbsd.org/printf.3

public struct FormatPlaceholder: Equatable {
    public var index: Index?
    public var flags: [Flag] = []
    public var width: Width?
    public var precision: Precision?
    public var length: Length?
    public var conversion: Conversion
    public var variableName: String? // variable in stringsdict
    
    public init(index: FormatPlaceholder.Index? = nil,
                flags: [FormatPlaceholder.Flag] = [],
                width: FormatPlaceholder.Width? = nil,
                precision: FormatPlaceholder.Precision? = nil,
                length: FormatPlaceholder.Length? = nil,
                conversion: FormatPlaceholder.Conversion,
                variableName: String? = nil
    ) {
        self.index = index
        self.flags = flags
        self.width = width
        self.precision = precision
        self.length = length
        self.conversion = conversion
        self.variableName = variableName
    }
}

extension FormatPlaceholder {
    public typealias Index = Int
    
    public enum Flag: Character, CaseIterable {
        case minus = "-"
        case plus = "+"
        case space = " "
        case zero = "0"
        case apostrophe = "'"
        case hash = "#"
    }
    
    public enum Width: Equatable {
        case `static`(Int)
        case dynamic(Index?)
    }
    
    public typealias Precision = Width
    
    public enum Length: String, CaseIterable {
        case char = "hh" // char or unsigned char
        case short = "h" // short or unsigned short
        case long = "l" // long or unsigned long
        case longLong = "ll" // long long or unsigned long long
        case longDouble = "L" // long double
        case size = "z" // size_t
        case intmax = "j" // intmax_t or uintmax_t
        case ptrdiff = "t" // ptrdiff_t
        
        // Apple-specific
        case quadword = "q" // quad_t
    }
    
    public enum Conversion: Character, CaseIterable {
        case decimal = "d" // int
        case int = "i" // int
        case unsigned = "u" // unsigned int
        case float = "f" // double
        case FLOAT = "F" // double
        case scientific = "e" // double
        case SCIENTIFIC = "E" // double
        case generalFloat = "g" // double
        case GENERALFLOAT = "G" // double
        case hex = "x" // unsigned int
        case HEX = "X" // unsigned int
        case octal = "o" // unsigned int
        case cString = "s" // unsigned char *
        case CSTRING = "S" // unichar *
        case char = "c" // unsigned char
        case CHAR = "C" // unichar
        case pointer = "p" // void *
        case hexFloat = "a" // double
        case HEXFLOAT = "A" // double
        case writtenCount = "n" // int *
        
        // Apple-specific
        case DECIMAL = "D" // int
        case UNSIGNED = "U" // unsigned int
        case OCTAL = "O" // unsigned int
        case object = "@" // object
    }
}

extension FormatPlaceholder {
    public var valueType: Any.Type {
        switch conversion {
        case .decimal, .DECIMAL, .int:
            switch length {
            case nil:           return CInt.self
            case .char:         return CSignedChar.self
            case .short:        return CShort.self
            case .long:         return CLong.self
            case .longLong:     return CLongLong.self
            case .quadword:     return quad_t.self
            case .longDouble:   return CInt.self // invalid length
            case .size:         return ssize_t.self
            case .intmax:       return intmax_t.self
            case .ptrdiff:      return ptrdiff_t.self
            }
        case .unsigned, .UNSIGNED, .hex, .HEX, .octal, .OCTAL:
            switch length {
            case nil:           return CUnsignedInt.self
            case .char:         return CUnsignedChar.self
            case .short:        return CUnsignedShort.self
            case .long:         return CUnsignedLong.self
            case .longLong:     return CUnsignedLongLong.self
            case .quadword:     return u_quad_t.self
            case .longDouble:   return CUnsignedInt.self // invalid length
            case .size:         return size_t.self
            case .intmax:       return uintmax_t.self
            case .ptrdiff:      return ptrdiff_t.self
            }
        case .float, .scientific, .generalFloat, .hexFloat,
             .FLOAT, .SCIENTIFIC, .GENERALFLOAT, .HEXFLOAT:
            switch length {
            case .long:         return CDouble.self
            case .longDouble:   return CLongDouble.self
            default:            return CDouble.self // invalid length
            }
        case .writtenCount:
            switch length {
            case nil:           return UnsafeMutablePointer<CInt>.self
            case .char:         return UnsafeMutablePointer<CSignedChar>.self
            case .short:        return UnsafeMutablePointer<CShort>.self
            case .long:         return UnsafeMutablePointer<CLong>.self
            case .longLong:     return UnsafeMutablePointer<CLongLong>.self
            case .quadword:     return UnsafeMutablePointer<quad_t>.self
            case .longDouble:   return UnsafeMutablePointer<CInt>.self // invalid length
            case .size:         return UnsafeMutablePointer<ssize_t>.self
            case .intmax:       return UnsafeMutablePointer<intmax_t>.self
            case .ptrdiff:      return UnsafeMutablePointer<ptrdiff_t>.self
            }
        case .cString:      return UnsafePointer<CUnsignedChar>.self
        case .CSTRING:      return UnsafePointer<UniChar>.self
        case .char:         return CUnsignedChar.self
        case .CHAR:         return UniChar.self
        case .pointer:      return UnsafeRawPointer.self
        case .object:       return NSObject.self
        }
    }
}
