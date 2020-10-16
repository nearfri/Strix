import Foundation

public struct RunError: Error {
    public var input: String
    public var position: String.Index
    public var underlyingErrors: [ParseError]
}
