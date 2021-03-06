import Foundation

struct ErrorMessageWriter<Target: ErrorOutputStream> {
    let input: String?
    let position: String.Index?
    let errorSplitter: ParseErrorSplitter
    
    init(input: String, position: String.Index, errors: [ParseError]) {
        self.input = input
        self.position = position
        self.errorSplitter = ParseErrorSplitter(errors)
    }
    
    init(errors: [ParseError]) {
        self.input = nil
        self.position = nil
        self.errorSplitter = ParseErrorSplitter(errors)
    }
    
    func write(to target: inout Target) {
        writePositionIfPossible(to: &target)
        
        writeExpectedErrors(to: &target)
        writeUnexpectedErrors(to: &target)
        writeGenericErrors(to: &target)
        
        writeCompoundErrors(to: &target)
        writeNestedErrors(to: &target)
        
        if !errorSplitter.hasErrors {
            print("Unknown Error(s)", to: &target)
        }
    }
    
    // MARK: - Position
    
    private func writePositionIfPossible(to target: inout Target) {
        if let input = input, let position = position {
            PositionWriter(input: input, position: position).write(to: &target)
        }
    }
    
    // MARK: - Expected, unexpected error
    
    private func writeExpectedErrors(to target: inout Target) {
        var writer = MessageListWriter(title: "Expecting: ", lastSeparator: "or")
        
        errorSplitter.expectedErrors.forEach({ writer.appendMessage($0) })
        errorSplitter.expectedStringErrors.forEach({ writer.appendMessage(withStringError: $0) })
        errorSplitter.compoundErrors.forEach({ writer.appendMessage($0.label) })
        
        writer.write(to: &target)
    }
    
    private func writeUnexpectedErrors(to target: inout Target) {
        var writer = MessageListWriter(title: "Unexpected: ", lastSeparator: "and")
        
        errorSplitter.unexpectedErrors.forEach({ writer.appendMessage($0) })
        errorSplitter.unexpectedStringErrors.forEach({ writer.appendMessage(withStringError: $0) })
        
        writer.write(to: &target)
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
            
            writeNestedErrors(error.errors, at: error.position, to: &target)
        }
    }
    
    private func writeNestedErrors(to target: inout Target) {
        for error in errorSplitter.nestedErrors {
            print("", to: &target)
            print("The parser backtracked after:", to: &target)
            
            writeNestedErrors(error.errors, at: error.position, to: &target)
        }
    }
    
    private func writeNestedErrors(_ errors: [ParseError],
                                   at position: String.Index,
                                   to target: inout Target) {
        let nestedWriter: ErrorMessageWriter = {
            guard let input = input else {
                return ErrorMessageWriter(errors: errors)
            }
            return ErrorMessageWriter(input: input, position: position, errors: errors)
        }()
        
        target.indent.level += 1
        nestedWriter.write(to: &target)
        target.indent.level -= 1
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
            print("Error at line \(line), column \(column)", to: &target)
            
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

// MARK: - Message list writer

extension ErrorMessageWriter {
    private struct MessageListWriter {
        let title: String
        let lastSeparator: String
        private var messages: [String] = []
        
        init(title: String, lastSeparator: String) {
            self.title = title
            self.lastSeparator = lastSeparator
        }
        
        mutating func appendMessage(_ message: String) {
            messages.append(message)
        }
        
        mutating func appendMessage(withStringError error: (string: String, caseSensitive: Bool)) {
            let message = "'\(error.string)'" + (error.caseSensitive ? "" : " (case-insensitive)")
            appendMessage(message)
        }
        
        func write(to target: inout Target) {
            if messages.isEmpty { return }
            
            print(title, terminator: "", to: &target)
            
            for message in messages.dropLast(2) {
                print(message, terminator: ", ", to: &target)
            }
            
            if let secondToLast = messages.dropLast().last {
                if messages.count > 2 {
                    print("\(secondToLast), \(lastSeparator) ", terminator: "", to: &target)
                } else {
                    print("\(secondToLast) \(lastSeparator) ", terminator: "", to: &target)
                }
            }
            
            if let last = messages.last {
                print(last, to: &target)
            }
        }
    }
}
