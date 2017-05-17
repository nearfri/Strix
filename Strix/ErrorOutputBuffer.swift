
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

internal protocol ErrorOutputStream: TextOutputStream {
    var indent: Indent { get set }
    mutating func writeLine(_ string: String)
    mutating func writeLine()
}

internal struct ErrorOutputBuffer: ErrorOutputStream {
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
    
    mutating func writeLine(_ string: String) {
        write(string)
        write("\n")
        needsIndent = true
    }
    
    mutating func writeLine() {
        writeLine("")
    }
}



