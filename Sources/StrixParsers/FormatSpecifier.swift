import Foundation

public enum FormatSpecifier: Equatable, Sendable {
    case percentSign
    case placeholder(FormatPlaceholder)
}
