
import XCTest
import Strix

enum DummyError: Int, Error {
    case err0
    case err1
    case err2
    case err3
    case err4
    case err5
    case err6
    case err7
    case err8
    case err9
}

func shouldNotEnterHere(
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file, line: UInt = #line) {
    
    XCTFail("should not enter here - \(message())", file: file, line: line)
}

func makeEmptyStream() -> CharacterStream {
    return CharacterStream(string: "")
}

func checkSuccess(
    _ reply: Reply<Void>, _ message: @autoclosure () -> String = "",
    file: StaticString = #file, line: UInt = #line) {
    
    if case let .success(_, e) = reply {
        XCTAssertTrue(e.isEmpty, messageForNotEmptyError(e, message), file: file, line: line)
    } else {
        fail(expected: .success, actual: reply, message: message, file: file, line: line)
    }
}

func checkSuccess<E: Error & Equatable>(
    _ reply: Reply<Void>, _ errors: [E],
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file, line: UInt = #line) {
    
    if case let .success(_, e) = reply {
        XCTAssertEqual(e as! [E], errors, message, file: file, line: line)
    } else {
        fail(expected: .success, actual: reply, message: message, file: file, line: line)
    }
}

func checkSuccess<T: Equatable>(
    _ reply: Reply<T>, _ value: T,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file, line: UInt = #line) {
    
    if case let .success(v, e) = reply {
        XCTAssertEqual(v, value, message, file: file, line: line)
        XCTAssertTrue(e.isEmpty, messageForNotEmptyError(e, message), file: file, line: line)
    } else {
        fail(expected: .success, actual: reply, message: message, file: file, line: line)
    }
}

func checkSuccess<T: Equatable>(
    _ reply: Reply<T?>, _ value: T?,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file, line: UInt = #line) {
    
    if case let .success(v, e) = reply {
        XCTAssertEqual(v, value, message, file: file, line: line)
        XCTAssertTrue(e.isEmpty, messageForNotEmptyError(e, message), file: file, line: line)
    } else {
        fail(expected: .success, actual: reply, message: message, file: file, line: line)
    }
}

func checkSuccess<T: Equatable, E: Error & Equatable>(
    _ reply: Reply<T>, _ value: T, _ errors: [E],
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file, line: UInt = #line) {
    
    if case let .success(v, e) = reply {
        XCTAssertEqual(v, value, message, file: file, line: line)
        XCTAssertEqual(e as! [E], errors, message, file: file, line: line)
    } else {
        fail(expected: .success, actual: reply, message: message, file: file, line: line)
    }
}

func checkSuccess<T: Equatable, E: Error & Equatable>(
    _ reply: Reply<T?>, _ value: T?, _ errors: [E],
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file, line: UInt = #line) {
    
    if case let .success(v, e) = reply {
        XCTAssertEqual(v, value, message, file: file, line: line)
        XCTAssertEqual(e as! [E], errors, message, file: file, line: line)
    } else {
        fail(expected: .success, actual: reply, message: message, file: file, line: line)
    }
}

func checkSuccess<T: Equatable, E: Error & Equatable> (
    _ reply: Reply<[T]>, _ value: [T], _ errors: [E],
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file, line: UInt = #line) {
    
    if case let .success(v, e) = reply {
        XCTAssertEqual(v, value, message, file: file, line: line)
        XCTAssertEqual(e as! [E], errors, message, file: file, line: line)
    } else {
        fail(expected: .success, actual: reply, message: message, file: file, line: line)
    }
}

func checkFailure<T>(
    _ reply: Reply<T>,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file, line: UInt = #line) {
    
    if case .failure = reply {
        
    } else {
        fail(expected: .failure, actual: reply, message: message, file: file, line: line)
    }
}

func checkFatalFailure<T>(
    _ reply: Reply<T>,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file, line: UInt = #line) {
    
    if case .fatalFailure = reply {
        
    } else {
        fail(expected: .fatalFailure, actual: reply, message: message, file: file, line: line)
    }
}

func checkFailure<T, E: Error & Equatable>(
    _ reply: Reply<T>, _ errors: [E],
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file, line: UInt = #line) {
    
    if case let .failure(e) = reply {
        XCTAssertEqual(e as! [E], errors, message, file: file, line: line)
    } else {
        fail(expected: .failure, actual: reply, message: message, file: file, line: line)
    }
}

func checkFatalFailure<T, E: Error & Equatable>(
    _ reply: Reply<T>, _ errors: [E],
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file, line: UInt = #line) {
    
    if case let .fatalFailure(e) = reply {
        XCTAssertEqual(e as! [E], errors, message, file: file, line: line)
    } else {
        fail(expected: .fatalFailure, actual: reply, message: message, file: file, line: line)
    }
}

func checkSuccess(
    _ parseResult: ParseResult<Void>,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file, line: UInt = #line) {
    
    if case .success = parseResult {
        
    } else {
        fail(expected: .success, actual: parseResult, message: message, file: file, line: line)
    }
}

func checkSuccess<T: Equatable>(
    _ parseResult: ParseResult<T>, _ value: T,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file, line: UInt = #line) {
    
    if case let .success(v) = parseResult {
        XCTAssertEqual(v, value, message, file: file, line: line)
    } else {
        fail(expected: .success, actual: parseResult, message: message, file: file, line: line)
    }
}

func checkFailure<T>(
    _ parseResult: ParseResult<T>,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file, line: UInt = #line) {
    
    if case .failure = parseResult {
        
    } else {
        fail(expected: .failure, actual: parseResult, message: message, file: file, line: line)
    }
}

func checkFailure<T, E: Error & Equatable>(
    _ parseResult: ParseResult<T>, _ underlyingErrors: [E],
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file, line: UInt = #line) {
    
    if case let .failure(e) = parseResult {
        XCTAssertEqual(e.underlyingErrors as! [E], underlyingErrors, message,
                       file: file, line: line)
    } else {
        fail(expected: .failure, actual: parseResult, message: message, file: file, line: line)
    }
}

private func messageForNotEmptyError(
    _ errors: [Error], _ message: @autoclosure () -> String) -> String {
    
    return "expected empty error but was \(errors) - \(message())"
}

private func fail<T>(
    expected: ReplyType, actual: Reply<T>,
    message: @autoclosure () -> String,
    file: StaticString, line: UInt) {
    
    XCTFail("expected '\(expected)' but was '\(label(of: actual))' - \(message())",
        file: file, line: line)
}

private func fail<T>(
    expected: ReplyType, actual: ParseResult<T>,
    message: @autoclosure () -> String,
    file: StaticString, line: UInt) {
    
    XCTFail("expected '\(expected)' but was '\(label(of: actual))' - \(message())",
        file: file, line: line)
}

private enum ReplyType: String {
    case success, failure, fatalFailure
}

private func label<T>(of reply: Reply<T>) -> String {
    switch reply {
    case .success:
        return "success"
    case .failure:
        return "failure"
    case .fatalFailure:
        return "fatalFailure"
    }
}

private func label<T>(of parseResult: ParseResult<T>) -> String {
    switch parseResult {
    case .success:
        return "success"
    case .failure:
        return "failure"
    }
}



