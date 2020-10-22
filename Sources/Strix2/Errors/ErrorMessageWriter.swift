import Foundation

struct ErrorMessageWriter {
    let input: String
    let position: String.Index
    let errorSplitter: ParseErrorSplitter
    
    init(input: String, position: String.Index, errors: [ParseError]) {
        self.input = input
        self.position = position
        self.errorSplitter = ParseErrorSplitter(errors)
    }
    
    func write<Target: ErrorOutputStream>(to output: inout Target) {
        PositionWriter(input: input, position: position).write(to: &output)
        
        ExpectedErrorWriter(errorSplitter: errorSplitter).write(to: &output)
        UnexpectedErrorWriter(errorSplitter: errorSplitter).write(to: &output)
        GenericErrorWriter(errorSplitter: errorSplitter).write(to: &output)
        
        CompoundErrorWriter(input: input, errorSplitter: errorSplitter).write(to: &output)
        NestedErrorWriter(input: input, errorSplitter: errorSplitter).write(to: &output)
        
        if !errorSplitter.hasErrors {
            print("Unknown Error(s)", to: &output)
        }
    }
}

// MARK: - Position writer

extension ErrorMessageWriter {
    struct PositionWriter {
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
        
        func write<Target: ErrorOutputStream>(to output: inout Target) {
            print("Error in \(line):\(column)", to: &output)
            
            let substringTerminator = input[lineRange].last?.isNewline == true ? "" : "\n"
            print(input[lineRange], terminator: substringTerminator, to: &output)
            
            columnMarker.map({ print($0, to: &output) })
            
            note.map({ print("Note: \($0)", to: &output) })
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

// MARK: - Expected, unexpected error writer

extension ErrorMessageWriter {
    struct ExpectedErrorWriter {
        let errorSplitter: ParseErrorSplitter
        
        init(errorSplitter: ParseErrorSplitter) {
            self.errorSplitter = errorSplitter
        }
        
        func write<Target: ErrorOutputStream>(to output: inout Target) {
            let messages: [String] = errorSplitter.expectedErrors
                + errorSplitter.expectedStringErrors.map({ makeMessage(stringError: $0) })
                + errorSplitter.compoundErrors.map(\.label)
            
            let messageListWriter = MessageListWriter(title: "Expecting: ",
                                                      messages: messages,
                                                      lastSeparator: " or ")
            messageListWriter.write(to: &output)
        }
    }
    
    struct UnexpectedErrorWriter {
        let errorSplitter: ParseErrorSplitter
        
        init(errorSplitter: ParseErrorSplitter) {
            self.errorSplitter = errorSplitter
        }
        
        func write<Target: ErrorOutputStream>(to output: inout Target) {
            let messages: [String] = errorSplitter.unexpectedErrors
                + errorSplitter.unexpectedStringErrors.map({ makeMessage(stringError: $0) })
            
            let messageListWriter = MessageListWriter(title: "Unexpected: ",
                                                      messages: messages,
                                                      lastSeparator: " and ")
            messageListWriter.write(to: &output)
        }
    }
    
    private static func makeMessage(
        stringError: (string: String, caseSensitive: Bool)
    ) -> String {
        return "'\(stringError.string)'" + (stringError.caseSensitive ? "" : " (case-insensitive)")
    }
    
    struct MessageListWriter {
        let title: String
        let messages: [String]
        let lastSeparator: String
        
        init(title: String, messages: [String], lastSeparator: String) {
            self.title = title
            self.messages = messages
            self.lastSeparator = lastSeparator
        }
        
        func write<Target: ErrorOutputStream>(to output: inout Target) {
            if messages.isEmpty { return }
            
            print(title, terminator: "", to: &output)
            
            for message in messages.dropLast(2) {
                print(message, terminator: ", ", to: &output)
            }
            
            if let secondToLast = messages.dropLast().last {
                print("\(secondToLast)\(lastSeparator)", terminator: "", to: &output)
            }
            
            if let last = messages.last {
                print(last, to: &output)
            }
        }
    }
}

// MARK: - Generic error writer

extension ErrorMessageWriter {
    struct GenericErrorWriter {
        let errorSplitter: ParseErrorSplitter
        
        init(errorSplitter: ParseErrorSplitter) {
            self.errorSplitter = errorSplitter
        }
        
        func write<Target: ErrorOutputStream>(to output: inout Target) {
            if errorSplitter.genericErrors.isEmpty { return }
            
            let shouldIndent = errorSplitter.hasExpectedErrors || errorSplitter.hasUnexpectedErrors
            
            if shouldIndent {
                print("Other error messages:", to: &output)
                output.indent.level += 1
            }
            
            for message in errorSplitter.genericErrors {
                print(message, to: &output)
            }
            
            if shouldIndent {
                output.indent.level -= 1
            }
        }
    }
}

// MARK: - Compound, nested error writer

extension ErrorMessageWriter {
    struct CompoundErrorWriter {
        let input: String
        let errorSplitter: ParseErrorSplitter
        
        init(input: String, errorSplitter: ParseErrorSplitter) {
            self.input = input
            self.errorSplitter = errorSplitter
        }
        
        func write<Target: ErrorOutputStream>(to output: inout Target) {
            for error in errorSplitter.compoundErrors {
                print("", to: &output)
                print("\(error.label) could not be parsed because:", to: &output)
                
                output.indent.level += 1
                
                let innerWriter = ErrorMessageWriter(input: input,
                                                     position: error.position,
                                                     errors: error.errors)
                innerWriter.write(to: &output)
                
                output.indent.level -= 1
            }
        }
    }
    
    struct NestedErrorWriter {
        let input: String
        let errorSplitter: ParseErrorSplitter
        
        init(input: String, errorSplitter: ParseErrorSplitter) {
            self.input = input
            self.errorSplitter = errorSplitter
        }
        
        func write<Target: ErrorOutputStream>(to output: inout Target) {
            for error in errorSplitter.nestedErrors {
                print("", to: &output)
                print("The parser backtracked after:", to: &output)
                
                output.indent.level += 1
                
                let innerWriter = ErrorMessageWriter(input: input,
                                                     position: error.position,
                                                     errors: error.errors)
                innerWriter.write(to: &output)
                
                output.indent.level -= 1
            }
        }
    }
}
