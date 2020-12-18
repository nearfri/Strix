import Foundation

extension String {
    func addingBackslashEncoding() -> String {
        let backslashMap: [Character: String] = [
            "\"": #"\""#, "\n": #"\n"#, "\r": #"\r"#, "\t": #"\t"#,
            "\u{0008}": #"\b"#, "\u{000C}": #"\f"#
        ]
        
        return reduce(into: "") { result, char in
            if let mapped = backslashMap[char] {
                result += mapped
            } else {
                result.append(char)
            }
        }
    }
}
