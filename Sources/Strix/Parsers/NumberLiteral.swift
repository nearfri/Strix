import Foundation

extension NumberLiteral {
    public enum Sign: Sendable {
        case none
        case minus
        case plus
    }
    
    public enum Classification: Sendable {
        case finite
        case nan
        case infinity
    }
    
    public enum Notation: Int, Sendable {
        case decimal = 10       // no prefix
        case hexadecimal = 16   // 0x prefix
        case octal = 8          // 0o prefix
        case binary = 2         // 0b prefix
    }
}

public struct NumberLiteral: Equatable, Sendable {
    public var string: String = ""
    public var sign: Sign = .none
    public var classification: Classification = .finite
    public var notation: Notation = .decimal
    public var integerPart: String = ""
    public var fractionalPart: String = ""
    public var exponentPart: String = ""
}

extension NumberLiteral {
    public var radix: Int {
        return notation.rawValue
    }
    
    public var integerPartNumber: UInt? {
        return UInt(integerPart, radix: radix)
    }
    
    public var fractionalPartNumber: UInt? {
        return UInt(fractionalPart, radix: radix)
    }
    
    public var exponentPartNumber: Int? {
        return Int(exponentPart, radix: 10)
    }
    
    public var integerPartValue: UInt? {
        return integerPartNumber
    }
    
    public var fractionalPartValue: Double? {
        guard let number = fractionalPartNumber else { return nil }
        return Double(number) / pow(Double(radix), Double(fractionalPart.count))
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
            if integerPart.isEmpty && fractionalPart.isEmpty {
                return nil
            }
            guard let integerPartValue = integerPart.isEmpty ? 0 : integerPartValue else {
                return nil
            }
            guard let fractionalPartValue = fractionalPart.isEmpty ? 0 : fractionalPartValue else {
                return nil
            }
            guard let exponentPartValue = exponentPart.isEmpty ? 1 : exponentPartValue else {
                return nil
            }
            let signValue: T = sign == .minus ? -1 : 1
            let significandValue: T = T(integerPartValue) + T(fractionalPartValue)
            return signValue * significandValue * T(exponentPartValue)
        }
    }
    
    public func toNumber() -> NSNumber? {
        if classification != .finite || !fractionalPart.isEmpty {
            return toValue(type: Double.self).map({ $0 as NSNumber })
        }
        
        if sign != .minus {
            return toValue(type: UInt.self).map({ $0 as NSNumber })
        }
        return toValue(type: Int.self).map({ $0 as NSNumber })
    }
}
