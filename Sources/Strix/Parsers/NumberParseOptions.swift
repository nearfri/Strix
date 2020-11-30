import Foundation

public struct NumberParseOptions: OptionSet {
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public static let allowPlusSign: NumberParseOptions     = .init(rawValue: 1 << 0)
    public static let allowMinusSign: NumberParseOptions    = .init(rawValue: 1 << 1)
    public static let allowNaN: NumberParseOptions          = .init(rawValue: 1 << 2)
    public static let allowInfinity: NumberParseOptions     = .init(rawValue: 1 << 3)
    public static let allowHexadecimal: NumberParseOptions  = .init(rawValue: 1 << 4)
    public static let allowOctal: NumberParseOptions        = .init(rawValue: 1 << 5)
    public static let allowBinary: NumberParseOptions       = .init(rawValue: 1 << 6)
    public static let allowFraction: NumberParseOptions     = .init(rawValue: 1 << 7)
    public static let allowExponent: NumberParseOptions     = .init(rawValue: 1 << 8)
    public static let allowUnderscore: NumberParseOptions   = .init(rawValue: 1 << 9)
    
    public static let allowSign: NumberParseOptions = [
        .allowPlusSign, .allowMinusSign
    ]
    
    public static let allowAllNotations: NumberParseOptions = [
        .allowHexadecimal, .allowOctal, .allowBinary
    ]
    
    public static let defaultSignedInteger: NumberParseOptions = [
        .allowSign, .allowAllNotations
    ]
    
    public static let defaultUnsignedInteger: NumberParseOptions = [
        .allowPlusSign, .allowAllNotations
    ]
    
    public static let defaultFloatingPoint: NumberParseOptions = [
        .allowSign, .allowNaN, .allowInfinity,
        .allowAllNotations, .allowFraction, .allowExponent
    ]
}
