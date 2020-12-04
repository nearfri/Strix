import Foundation

struct Indent {
    var level: Int = 0
    var width: Int = 4
    
    var string: String {
        return String(repeating: " ", count: level * width)
    }
}
