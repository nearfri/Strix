
import Foundation

public struct NumberComponents {
    public var string: String? = nil
    public var sign: Sign = .none
    public var classification: Classification = .finite
    public var notation: Notation = .decimal
    public var integer: String? = nil
    public var fraction: String? = nil
    public var exponent: String? = nil
    
    public var radix: Int {
        return notation.rawValue
    }
}

extension NumberComponents: Equatable {
    public static func == (lhs: NumberComponents, rhs: NumberComponents) -> Bool {
        return lhs.string == rhs.string
            && lhs.sign == rhs.sign
            && lhs.classification == rhs.classification
            && lhs.notation == rhs.notation
            && lhs.integer == rhs.integer
            && lhs.fraction == rhs.fraction
            && lhs.exponent == rhs.exponent
    }
}

extension NumberComponents {
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
        case binary = 2         // 0b prefix
        case octal = 8          // 0o prefix
        case hexadecimal = 16   // 0x prefix
    }
}

extension NumberComponents {
    public var integerValue: Int? {
        guard let text = integer else { return nil }
        return Int(text, radix: radix)
    }
    
    public var fractionValue: Double? {
        guard let text = fraction, let value = Int(text, radix: radix) else {
            return nil
        }
        return Double(value) / pow(Double(radix), Double(text.count))
    }
    
    public var significandValue: Double? {
        let integerValue = self.integerValue
        let fractionValue = self.fractionValue
        if integerValue == nil && fractionValue == nil {
            return nil
        }
        return Double(integerValue ?? 0) + (fractionValue ?? 0)
    }
    
    public var exponentValue: Double? {
        let value: () -> Double? = {
            guard let text = self.exponent else { return nil }
            return Double(text)
        }
        
        switch notation {
        case .decimal:
            return value().map({ pow(10, $0) })
        case .hexadecimal:
            return value().map({ pow(2, $0) })
        case .octal, .binary:
            return nil
        }
    }
}



