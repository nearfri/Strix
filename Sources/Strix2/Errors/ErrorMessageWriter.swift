import Foundation

struct ErrorMessageWriter<Target: ErrorOutputStream> {
    let input: String
    let position: String.Index
    let errorSplitter: ParseErrorSplitter
    
    init(input: String, position: String.Index, errors: [ParseError]) {
        self.input = input
        self.position = position
        self.errorSplitter = ParseErrorSplitter(errors)
    }
    
    func write(to target: inout Target) {
        PositionWriter(input: input, position: position).write(to: &target)
        
        writeExpectedErrors(to: &target)
        writeUnexpectedErrors(to: &target)
        writeGenericErrors(to: &target)
        
        writeCompoundErrors(to: &target)
        writeNestedErrors(to: &target)
        
        if !errorSplitter.hasErrors {
            print("Unknown Error(s)", to: &target)
        }
    }
    
    // MARK: - Expected, unexpected error
    
    private func writeExpectedErrors(to target: inout Target) {
        let messages: [String] = errorSplitter.expectedErrors
            + errorSplitter.expectedStringErrors.map({ makeMessage(stringError: $0) })
            + errorSplitter.compoundErrors.map(\.label)
        
        writeMessages(messages, title: "Expecting: ", lastSeparator: " or ", to: &target)
    }
    
    private func writeUnexpectedErrors(to target: inout Target) {
        let messages: [String] = errorSplitter.unexpectedErrors
            + errorSplitter.unexpectedStringErrors.map({ makeMessage(stringError: $0) })
        
        writeMessages(messages, title: "Unexpected: ", lastSeparator: " and ", to: &target)
    }
    
    private func makeMessage(stringError: (string: String, caseSensitive: Bool)) -> String {
        return "'\(stringError.string)'" + (stringError.caseSensitive ? "" : " (case-insensitive)")
    }
    
    private func writeMessages(
        _ messages: [String],
        title: String,
        lastSeparator: String,
        to target: inout Target
    ) {
        if messages.isEmpty { return }
        
        print(title, terminator: "", to: &target)
        
        for message in messages.dropLast(2) {
            print(message, terminator: ", ", to: &target)
        }
        
        if let secondToLast = messages.dropLast().last {
            print("\(secondToLast)\(lastSeparator)", terminator: "", to: &target)
        }
        
        if let last = messages.last {
            print(last, to: &target)
        }
    }
    
    // MARK: - Generic error
    
    private func writeGenericErrors(to target: inout Target) {
        if errorSplitter.genericErrors.isEmpty { return }
        
        let shouldIndent = errorSplitter.hasExpectedErrors || errorSplitter.hasUnexpectedErrors
        
        if shouldIndent {
            print("Other error messages:", to: &target)
            target.indent.level += 1
        }
        
        for message in errorSplitter.genericErrors {
            print(message, to: &target)
        }
        
        if shouldIndent {
            target.indent.level -= 1
        }
    }
    
    // MARK: - Compound, nested error
    
    private func writeCompoundErrors(to target: inout Target) {
        for error in errorSplitter.compoundErrors {
            print("", to: &target)
            print("\(error.label) could not be parsed because:", to: &target)
            
            target.indent.level += 1
            Self(input: input, position: error.position, errors: error.errors).write(to: &target)
            target.indent.level -= 1
        }
    }
    
    private func writeNestedErrors(to target: inout Target) {
        for error in errorSplitter.nestedErrors {
            print("", to: &target)
            print("The parser backtracked after:", to: &target)
            
            target.indent.level += 1
            Self(input: input, position: error.position, errors: error.errors).write(to: &target)
            target.indent.level -= 1
        }
    }
}

// MARK: - Position writer

extension ErrorMessageWriter {
    private struct PositionWriter {
        let input: String
        let position: String.Index
        let line: Int
        let column: Int
        
        init(input: String, position: String.Index) {
            let textPosition = TextPosition(string: input, index: position)
            self.input = input
            self.position = position
            self.line = textPosition.line
            self.column = textPosition.column
        }
        
        func write(to target: inout Target) {
            print("Error in \(line):\(column)", to: &target)
            
            let substringTerminator = input[lineRange].last?.isNewline == true ? "" : "\n"
            print(input[lineRange], terminator: substringTerminator, to: &target)
            
            columnMarker.map({ print($0, to: &target) })
            
            note.map({ print("Note: \($0)", to: &target) })
        }
        
        private var lineRange: Range<String.Index> {
            return input.lineRange(for: position..<position)
        }
        
        private var columnMarker: String? {
            let tab: Character = "\t"
            let printableASCIIRange: ClosedRange<Character> = " "..."~"
            
            var result = ""
            for character in input[lineRange].prefix(column - 1) {
                // ASCII 외의 문자는 프린트 시 폭이 다를 수 있으므로 nil을 리턴한다
                guard character.isASCII else { return nil }
                
                switch character {
                case tab:
                    result.append(tab)
                case printableASCIIRange:
                    result.append(" ")
                default:
                    // 그 외 제어 문자는 프린트 되지 않으므로 아무 것도 더하지 않는다
                    break
                }
            }
            
            result.append("^")
            
            return result
        }
        
        private var note: String? {
            if position == input.endIndex {
                return "The error occurred at the end of the input stream."
            }
            
            if input[position].isNewline {
                if input[lineRange].count == 1 {
                    return "The error occurred on an empty line."
                }
                return "The error occurred at the end of the line."
            }
            
            return nil
        }
    }
}
