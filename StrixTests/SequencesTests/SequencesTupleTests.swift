
import XCTest
@testable import Strix

class SequencesTupleTests: XCTestCase {
    let p1s = Parser { _ -> Reply<String> in
        return .success("1", [])
    }
    let p2n = Parser { _ -> Reply<Int> in
        return .success(2, [])
    }
    let p3s = Parser { _ -> Reply<String> in
        return .success("3", [])
    }
    let p4n = Parser { _ -> Reply<Int> in
        return .success(4, [])
    }
    let p5s = Parser { _ -> Reply<String> in
        return .success("5", [])
    }
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func test_tuple2() {
        let reply2 = tuple(p1s, p2n).parse(makeEmptyStream())
        if case let .success(v, _) = reply2, v == ("1", 2) {
            
        } else {
            shouldNotEnterHere()
        }
    }
    
    func test_tuple3() {
        let reply = tuple(p1s, p2n, p3s).parse(makeEmptyStream())
        if case let .success(v, _) = reply, v == ("1", 2, "3") {
            
        } else {
            shouldNotEnterHere()
        }
    }
    
    func test_tuple4() {
        let reply = tuple(p1s, p2n, p3s, p4n).parse(makeEmptyStream())
        if case let .success(v, _) = reply, v == ("1", 2, "3", 4) {
            
        } else {
            shouldNotEnterHere()
        }
    }
    
    func test_tuple5() {
        let reply = tuple(p1s, p2n, p3s, p4n, p5s).parse(makeEmptyStream())
        if case let .success(v, _) = reply, v == ("1", 2, "3", 4, "5") {
            
        } else {
            shouldNotEnterHere()
        }
    }
}



