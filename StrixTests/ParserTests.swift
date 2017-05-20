
import XCTest
@testable import Strix

class ParserTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func test_run_whenSuccess_returnSuccess() {
        let parser = Parser { (_) -> Reply<Int> in
            return .success(7, [])
        }
        let result = parser.run("")
        if case .success(let v) = result {
            XCTAssertEqual(v, 7)
        } else {
            XCTFail()
        }
    }
    
    func test_run_whenFailure_returnFailure() {
        let underlyingErrors: [NSError] = [
            NSError(domain: "", code: 1, userInfo: nil)
        ]
        
        let parser = Parser { (_) -> Reply<Int> in
            return .failure(underlyingErrors)
        }
        
        let result = parser.run("")
        if case .failure(let e) = result {
            XCTAssertEqual(e.underlyingErrors as [NSError], underlyingErrors)
        } else {
            XCTFail()
        }
    }
    
    func test_run_whenFailure_returnFatalFailure() {
        let underlyingErrors: [NSError] = [
            NSError(domain: "", code: 1, userInfo: nil)
        ]
        
        let parser = Parser { (_) -> Reply<Int> in
            return .fatalFailure(underlyingErrors)
        }
        
        let result = parser.run("")
        if case .failure(let e) = result {
            XCTAssertEqual(e.underlyingErrors as [NSError], underlyingErrors)
        } else {
            XCTFail()
        }
    }
}



