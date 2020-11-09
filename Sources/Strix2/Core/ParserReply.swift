import Foundation

extension ParserReply {
    public enum Result {
        case success(T)
        case failure
        
        public var value: T? {
            switch self {
            case .success(let v):   return v
            case .failure:          return nil
            }
        }
        
        public var isSuccess: Bool {
            switch self {
            case .success:  return true
            case .failure:  return false
            }
        }
        
        public var isFailure: Bool {
            return !isSuccess
        }
    }
}

public struct ParserReply<T> {
    public var result: Result
    public var state: ParserState
    public var errors: [ParseError]
    
    public init(result: Result, state: ParserState, errors: [ParseError] = []) {
        self.result = result
        self.state = state
        self.errors = errors
    }
    
    public static func success(_ value: T,
                               _ state: ParserState,
                               _ errors: [ParseError] = []) -> ParserReply {
        return .init(result: .success(value), state: state, errors: errors)
    }
    
    public static func failure(_ state: ParserState, _ errors: [ParseError]) -> ParserReply {
        return .init(result: .failure, state: state, errors: errors)
    }
    
    public func map<U>(_ transform: (T) throws -> U) -> ParserReply<U> {
        do {
            switch result {
            case .success(let value):
                return .success(try transform(value), state, errors)
            case .failure:
                return .failure(state, errors)
            }
        } catch let parseError as ParseError {
            return .failure(state, errors + [parseError])
        } catch {
            let parseError = ParseError.generic(message: error.localizedDescription)
            return .failure(state, errors + [parseError])
        }
    }
    
    public func withErrors(_ errors: [ParseError]) -> ParserReply {
        return .init(result: result, state: state, errors: errors)
    }
    
    public func appendingErrors(_ errors: [ParseError]) -> ParserReply {
        return .init(result: result, state: state, errors: self.errors + errors)
    }
    
    public func prependingErrors(_ errors: [ParseError]) -> ParserReply {
        return .init(result: result, state: state, errors: errors + self.errors)
    }
    
    public func compareStateAndAppendingErrors<U>(of reply: ParserReply<U>) -> ParserReply {
        return state == reply.state ? appendingErrors(reply.errors) : self
    }
    
    public func compareStateAndPrependingErrors<U>(of reply: ParserReply<U>) -> ParserReply {
        return state == reply.state ? prependingErrors(reply.errors) : self
    }
}
