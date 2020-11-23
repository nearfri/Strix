import Foundation

extension NumberLiteral {
    public enum Sign {
        case none
        case minus
        case plus
    }
    
    public enum Classification {
        case finite
        case nan
        case infinity
    }
    
    public enum Notation: Int {
        case decimal = 10       // no prefix
        case hexadecimal = 16   // 0x prefix
        case octal = 8          // 0o prefix
        case binary = 2         // 0b prefix
    }
}

public struct NumberLiteral: Equatable {
    public var string: String? = nil
    public var sign: Sign = .none
    public var classification: Classification = .finite
    public var notation: Notation = .decimal
    public var integerPart: String? = nil
    public var fractionalPart: String? = nil
    public var exponentPart: String? = nil
}

extension NumberLiteral {
    public var radix: Int {
        return notation.rawValue
    }
    
    public var integerPartNumber: UInt? {
        return integerPart.flatMap({ UInt($0, radix: radix) })
    }
    
    public var fractionalPartNumber: UInt? {
        return fractionalPart.flatMap({ UInt($0, radix: radix) })
    }
    
    public var exponentPartNumber: Int? {
        return exponentPart.flatMap({ Int($0, radix: 10) })
    }
    
    public var integerPartValue: UInt? {
        return integerPartNumber
    }
    
    public var fractionalPartValue: Double? {
        guard let text = fractionalPart, let number = fractionalPartNumber else { return nil }
        return Double(number) / pow(Double(radix), Double(text.count))
    }
    
    public var exponentPartValue: Double? {
        guard let exp = exponentPartNumber, let base = baseOfExponentiation else { return nil }
        return pow(Double(base), Double(exp))
    }
    
    public var baseOfExponentiation: Int? {
        switch notation {
        case .decimal:      return 10
        case .hexadecimal:  return 2
        case .octal:        return nil
        case .binary:       return nil
        }
    }
}
