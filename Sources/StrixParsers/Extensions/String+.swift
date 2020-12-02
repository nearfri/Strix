import Foundation

extension String {
    func addingBackslashEncoding() -> String {
        return replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\t", with: "\\t")
    }
}
