import Foundation

struct Indent: CustomStringConvertible {
    var level: Int = 0
    var width: Int = 4
    
    var description: String {
        return toString()
    }
    
    func toString() -> String {
        return String(repeating: " " as Character, count: level * width)
    }
}
