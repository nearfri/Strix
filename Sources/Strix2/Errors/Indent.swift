import Foundation

struct Indent: CustomStringConvertible {
    var level: Int = 0
    var width: Int = 2
    
    var description: String {
        return String(repeating: " " as Character, count: level * width)
    }
}
