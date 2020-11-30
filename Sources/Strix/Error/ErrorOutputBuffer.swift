import Foundation

struct ErrorOutputBuffer: ErrorOutputStream {
    var indent: Indent = .init()
    private(set) var text: String = ""
    
    mutating func write(_ string: String) {
        var indentedString = ""
        
        string.enumerateSubstrings(
            in: string.startIndex..<string.endIndex,
            options: [.byLines, .substringNotRequired]
        ) { [self] _, _, enclosingRange, _ in
            if enclosingRange.lowerBound == string.startIndex {
                if text.isEmpty || text.last?.isNewline == true {
                    indentedString += indent.toString()
                }
            } else {
                indentedString += indent.toString()
            }
            
            indentedString += string[enclosingRange]
        }
        
        text += indentedString
    }
}
