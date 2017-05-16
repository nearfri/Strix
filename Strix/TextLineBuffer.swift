
internal struct Indent {
    var level: Int
    var width: Int
    
    init(level: Int = 0, width: Int = 2) {
        self.level = level
        self.width = width
    }
    
    var string: String {
        return String(repeating: " ", count: level * width)
    }
}

internal struct TextLineBuffer: TextOutputStream {
    var indent: Indent = Indent()
    fileprivate(set) var text: String = ""
    fileprivate var needsIndent: Bool = true
    
    mutating func write(_ string: String) {
        if needsIndent {
            needsIndent = false
            text.write(indent.string)
        }
        text.write(string)
    }
    
    mutating func writeLine(_ string: String = "") {
        write(string)
        write("\n")
        needsIndent = true
    }
}



