import Foundation

public enum ParserResult<T> {
    case success(T, [ParseError])
    case failure([ParseError])
    
    public var isSuccess: Bool {
        switch self {
        case .success:  return true
        case .failure:  return false
        }
    }
    
    public var isFailure: Bool {
        return !isSuccess
    }
    
    public var value: T? {
        switch self {
        case .success(let value, _):    return value
        case .failure:                  return nil
        }
    }
    
    public var errors: [ParseError] {
        get {
            switch self {
            case .success(_, let errors):   return errors
            case .failure(let errors):      return errors
            }
        }
        set(newErrors) {
            switch self {
            case .success(let value, _):
                self = .success(value, newErrors)
            case .failure:
                self = .failure(newErrors)
            }
        }
    }
    
    public func map<U>(_ transform: (T) throws(ParseError) -> U) -> ParserResult<U> {
        switch self {
        case let .success(value, errors):
            do {
                return .success(try transform(value), errors)
            } catch {
                return .failure(errors + [error])
            }
        case let .failure(errors):
            return .failure(errors)
        }
    }
    
    public func withErrors(_ errors: [ParseError]) -> ParserResult<T> {
        var result = self
        result.errors = errors
        return result
    }
    
    public func appendingErrors(_ errors: [ParseError]) -> ParserResult<T> {
        if errors.isEmpty { return self }
        
        var result = self
        result.errors = self.errors + errors
        return result
    }
    
    public func prependingErrors(_ errors: [ParseError]) -> ParserResult<T> {
        if errors.isEmpty { return self }
        
        var result = self
        result.errors = errors + self.errors
        return result
    }
}
