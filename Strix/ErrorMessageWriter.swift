
internal struct ErrorMessageWriter {
    private let position: TextPosition
    private let errorGroup: ParseErrorGroup
    
    private init(position: TextPosition, errors: [Error]) {
        self.position = position
        self.errorGroup = ParseErrorGroup(errors)
    }
    
    static func write<Target>(position: TextPosition, errors: [Error],
                      to output: inout Target) where Target: ErrorOutputStream {
        let writer = ErrorMessageWriter(position: position, errors: errors)
        writer.write(to: &output)
    }
    
    private func write<Target: ErrorOutputStream>(to output: inout Target) {
        writePosition(to: &output)
        
        let writingResultExpected = writeExpectedMessages(to: &output)
        let writingResultUnexpected = writeUnexpectedMessages(to: &output)
        
        let didWriteMessageExpected = writingResultExpected == .messagesWritten
        let didWriteMessageUnexpected = writingResultUnexpected == .messagesWritten
        let shouldIndentOtherMessages = didWriteMessageExpected || didWriteMessageUnexpected
        
        writeOtherMessages(indented: shouldIndentOtherMessages, to: &output)
        
        writeCompoundErrors(to: &output)
        writeNestedErrors(to: &output)
        
        if errorGroup.isEmpty {
            output.writeLine("Unknown Error(s)")
        }
    }
    
    private func writePosition<Target: ErrorOutputStream>(to output: inout Target) {
        output.writeLine("Error in \(position.lineNumber):\(position.columnNumber)")
        output.writeLine("\(position.substring)")
        if let columnMarker = position.columnMarker {
            output.writeLine("\(columnMarker)")
        }
        
        let note: String?
        if position.index == position.string.endIndex {
            note = "The error occurred at the end of the input stream."
        } else if position.substring.isEmpty {
            note = "The error occurred on an empty line."
        } else if position.columnNumber == position.substring.count + 1 {
            note = "The error occurred at the end of the line."
        } else {
            note = nil
        }
        
        if let note = note {
            output.writeLine("Note: \(note)")
        }
    }
    
    private func writeExpectedMessages<Target: ErrorOutputStream>(
        to output: inout Target) -> WritingResult {
        
        let messages = makeExpectedMessages()
        if messages.isEmpty {
            return .nothingWritten
        }
        
        writeMessages(messages, title: "Expecting: ", separator: " or ", to: &output)
        return .messagesWritten
    }
    
    private func writeUnexpectedMessages<Target: ErrorOutputStream>(
        to output: inout Target) -> WritingResult {
        
        let messages = makeUnexpectedMessages()
        if messages.isEmpty {
            return .nothingWritten
        }
        
        writeMessages(messages, title: "Unexpected: ", separator: " and ", to: &output)
        return .messagesWritten
    }
    
    private func makeExpectedMessages() -> [String] {
        var result = errorGroup.expectedErrors.map({ $0.label }).filter({ !$0.isEmpty })
        result += errorGroup.expectedStringErrors.filter({ !$0.string.isEmpty }).map({
            makeQuotedString($0.string, case: $0.caseSensitivity)
        })
        result += errorGroup.compoundErrors.map({ $0.label }).filter({ !$0.isEmpty })
        return result
    }
    
    private func makeUnexpectedMessages() -> [String] {
        var result = errorGroup.unexpectedErrors.map({ $0.label }).filter({ !$0.isEmpty })
        result += errorGroup.unexpectedStringErrors.filter({ !$0.string.isEmpty }).map({
            makeQuotedString($0.string, case: $0.caseSensitivity)
        })
        return result
    }
    
    private func makeQuotedString(_ string: String,
                                  case caseSensitivity: StringSensitivity) -> String {
        switch caseSensitivity {
        case .sensitive:    return "'\(string)'"
        case .insensitive:  return "'\(string)' (case-insensitive)"
        }
    }
    
    private func writeMessages<Target>(_ messages: [String], title: String, separator: String,
                               to output: inout Target) where Target: ErrorOutputStream {
        output.write(title)
        for message in messages.dropLast(2) {
            output.write("\(message), ")
        }
        if let secondLast = messages.dropLast().last {
            output.write("\(secondLast)\(separator)")
        }
        if let last = messages.last {
            output.write(last)
        }
        output.writeLine()
    }
    
    private func writeOtherMessages<Target: ErrorOutputStream>(
        indented: Bool, to output: inout Target) {
        
        if errorGroup.genericErrors.isEmpty && errorGroup.userDefinedErrors.isEmpty {
            return
        }
        
        if indented {
            output.writeLine("Other error messages: ")
            output.indent.level += 1
        }
        
        errorGroup.genericErrors.forEach { output.writeLine($0.message) }
        errorGroup.userDefinedErrors.forEach { output.writeLine("\($0)") }
        
        if indented {
            output.indent.level -= 1
        }
    }
    
    private func writeCompoundErrors<Target: ErrorOutputStream>(to output: inout Target) {
        for error in errorGroup.compoundErrors {
            output.writeLine()
            output.writeLine("\(error.label) could not be parsed because: ")
            output.indent.level += 1
            ErrorMessageWriter.write(position: error.position, errors: error.errors, to: &output)
            output.indent.level -= 1
        }
    }
    
    private func writeNestedErrors<Target: ErrorOutputStream>(to output: inout Target) {
        for error in errorGroup.nestedErrors {
            output.writeLine()
            output.writeLine("The parser backtracked after: ")
            output.indent.level += 1
            ErrorMessageWriter.write(position: error.position, errors: error.errors, to: &output)
            output.indent.level -= 1
        }
    }
}

extension ErrorMessageWriter {
    private enum WritingResult {
        case nothingWritten
        case messagesWritten
    }
}



