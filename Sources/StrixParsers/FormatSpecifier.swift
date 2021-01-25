import Foundation

public enum FormatSpecifier: Equatable {
    case percentSign
    case placeholder(FormatPlaceholder)
}
