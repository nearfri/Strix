
import XCTest
@testable import Strix

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
        if case let .success(v, e) = p.parse(stream) {
            XCTAssertEqual(v, 1)
            XCTAssertTrue(e.isEmpty)
        } else {
            XCTFail()
        }
    }
    
    func test_pure_reply_failure() {
        let stream = CharacterStream(string: "")
        
        let p: Parser<Void> = pure(.failure([DummyError.err0]))
        if case let .failure(e) = p.parse(stream) {
            XCTAssertEqual(e as! [DummyError], [DummyError.err0])
        } else {
            XCTFail()
        }
    }
    
    func test_pure_value() {
        let stream = CharacterStream(string: "")
        let parser = pure(1)
        if case let .success(v, e) = parser.parse(stream) {
            XCTAssertEqual(v, 1)
            XCTAssertTrue(e.isEmpty)
        } else {
            XCTFail()
        }
    }
}



