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

extension NumberLiteral {
    public func toValue<T>(type: T.Type) -> T? where T: FixedWidthInteger {
        let signValue: T = sign == .minus ? -1 : 1
        
        guard let integerPartValue = integerPartValue.flatMap({ T(exactly: $0) }) else {
            return nil
        }
        
        guard let exponentPartValue = exponentPartValue else {
            return signValue * integerPartValue
        }
        
        guard let exp = T(exactly: exponentPartValue) else {
            return nil
        }
        
        let (multipliedValue, overflow) = integerPartValue.multipliedReportingOverflow(by: exp)
        return overflow ? nil : signValue * multipliedValue
    }
    
    public func toValue<T>(type: T.Type) -> T? where T: BinaryFloatingPoint {
        switch classification {
        case .nan:
            return sign == .minus ? -T.nan : T.nan
        case .infinity:
            return sign == .minus ? -T.infinity : T.infinity
        case .finite:
            if integerPart == nil && fractionalPart == nil {
                return nil
            }
            guard let integerPartValue = integerPart == nil ? 0 : integerPartValue else {
                return nil
            }
            guard let fractionalPartValue = fractionalPart == nil ? 0 : fractionalPartValue else {
                return nil
            }
            guard let exponentPartValue = exponentPart == nil ? 1 : exponentPartValue else {
                return nil
            }
            let signValue: T = sign == .minus ? -1 : 1
            let significandValue: T = T(integerPartValue) + T(fractionalPartValue)
            return signValue * significandValue * T(exponentPartValue)
        }
    }
    
    public func toNumber() -> NSNumber? {
        if classification != .finite || fractionalPart != nil {
            return toValue(type: Double.self).map({ $0 as NSNumber })
        }
        
        if sign != .minus {
            return toValue(type: UInt.self).map({ $0 as NSNumber })
        }
        return toValue(type: Int.self).map({ $0 as NSNumber })
    }
}
