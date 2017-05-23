
import XCTest
@testable import Strix

private enum DummyError: Error {
    case err0
    case err1
}

class PrimitivesPureTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func test_pure_reply_success() {
        let stream = CharacterStream(string: "")
        
        let p = pure(.success(1, []))
        var passed = false
        if case let .success(v, e) = p.parse(stream) {
            XCTAssertEqual(v, 1)
            XCTAssertTrue(e.isEmpty)
            passed = true
        }
        XCTAssertTrue(passed)
    }
    
    func test_pure_reply_failure() {
        let stream = CharacterStream(string: "")
        
        let p: Parser<Void> = pure(.failure([DummyError.err0]))
        var passed = false
        if case let .failure(e) = p.parse(stream) {
            XCTAssertEqual(e as! [DummyError], [DummyError.err0])
            passed = true
        }
        XCTAssertTrue(passed)
    }
    
    func test_pure_value() {
        let stream = CharacterStream(string: "")
        let parser = pure(1)
        var passed = false
        if case let .success(v, e) = parser.parse(stream) {
            XCTAssertEqual(v, 1)
            XCTAssertTrue(e.isEmpty)
            passed = true
        }
        XCTAssertTrue(passed)
    }
}



