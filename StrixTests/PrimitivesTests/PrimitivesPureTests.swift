
import XCTest
@testable import Strix

class PrimitivesPureTests: XCTestCase {
    var defaultStream: CharacterStream = CharacterStream(string: "")
    
    override func setUp() {
        super.setUp()
        defaultStream = CharacterStream(string: "")
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func test_pure_reply_success() {
        let p = pure(.success(1, []))
        checkSuccess(p.parse(defaultStream), 1)
    }
    
    func test_pure_reply_failure() {
        let p: Parser<Void> = pure(.failure([DummyError.err0]))
        checkFailure(p.parse(defaultStream), [DummyError.err0])
    }
    
    func test_pure_value() {
        let p = pure(1)
        checkSuccess(p.parse(defaultStream), 1)
    }
}



