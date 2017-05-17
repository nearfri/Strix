
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
        
        let expectedMessages = makeExpectedMessages()
        let unexpectedMessages = makeUnexpectedMessages()
        
        writeMessages(expectedMessages, title: "Expecting: ", separator: " or ", to: &output)
        writeMessages(unexpectedMessages, title: "Unexpected: ", separator: " and ", to: &output)
        
        let otherMessageTitle = expectedMessages.isEmpty && unexpectedMessages.isEmpty
            ? nil
            : "Other error messages: "
        writeOtherMessages(title: otherMessageTitle, to: &output)
        
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
        // TODO: Note 출력 추가
    }
    
    private func makeExpectedMessages() -> [String] {
        var result = errorGroup.expectedErrors.map({ $0.label })
        result += errorGroup.expectedStringErrors.map({
            makeQuotedString($0.string, case: $0.caseSensitivity)
        })
        result += errorGroup.compoundErrors.filter({ !$0.label.isEmpty }).map({ $0.label })
        return result
    }
    
    private func makeUnexpectedMessages() -> [String] {
        var result = errorGroup.unexpectedErrors.map({ $0.label })
        result += errorGroup.unexpectedStringErrors.map({
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
        if messages.isEmpty { return }
        
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
    
    private func writeOtherMessages<Target>(title: String?,
                                    to output: inout Target) where Target: ErrorOutputStream {
        if errorGroup.genericErrors.isEmpty && errorGroup.unknownErrors.isEmpty {
            return
        }
        
        if let title = title {
            output.writeLine(title)
            output.indent.level += 1
        }
        
        errorGroup.genericErrors.forEach { output.writeLine($0.message) }
        errorGroup.unknownErrors.forEach { output.writeLine("\($0)") }
        
        if title != nil {
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



