
public enum Reply<T> {
    case success(T, [Error])
    case failure([Error])
}

extension Reply {
    public var value: T? {
        switch self {
        case .success(let v, _):
            return v
        case .failure:
            return nil
        }
    }
    
    public var errors: [Error] {
        get {
            switch self {
            case let .success(_, e):    return e
            case let .failure(e):       return e
            }
        }
        set {
            switch self {
            case .success(let v, _):    self = .success(v, newValue)
            case .failure(_):           self = .failure(newValue)
            }
        }
    }
    
    public func prepending(_ errors: [Error]) -> Reply {
        if errors.count == 0 { return self }
        switch self {
        case let .success(v, e):    return .success(v, errors + e)
        case let .failure(e):       return .failure(errors + e)
        }
    }
    
    public func appending(_ errors: [Error]) -> Reply {
        if errors.count == 0 { return self }
        switch self {
        case let .success(v, e):    return .success(v, e + errors)
        case let .failure(e):       return .failure(e + errors)
        }
    }
    
    public mutating func prepend(_ errors: [Error]) {
        self = prepending(errors)
    }
    
    public mutating func append(_ errors: [Error]) {
        self = appending(errors)
    }
    
    public func map<U>(_ transform: (T) throws -> U) rethrows -> Reply<U> {
        switch self {
        case let .success(v, e):    return try .success(transform(v), e)
        case let .failure(e):       return .failure(e)
        }
    }
    
    public func flatMap<U>(_ transform: (T) throws -> Reply<U>) rethrows -> Reply<U> {
        switch self {
        case let .success(v, e):    return try transform(v).prepending(e)
        case let .failure(e):       return .failure(e)
        }
    }
}



