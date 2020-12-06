import Foundation

public struct TextPosition {
    public var line: Int
    public var column: Int
    
    public init(line: Int, column: Int) {
        self.line = line
        self.column = column
    }
    
    public init(string: String, index: String.Index) {
        var line = 0
        var column = 1
        
        string.enumerateSubstrings(
            in: string.startIndex..<string.endIndex,
            options: [.byLines, .substringNotRequired]
        ) { _, _, enclosingRange, stop in
            line += 1
            if enclosingRange.contains(index) || enclosingRange.upperBound == string.endIndex {
                column = string.distance(from: enclosingRange.lowerBound, to: index) + 1
                stop = true
            }
        }
        
        self.line = max(line, 1)
        self.column = column
    }
}
