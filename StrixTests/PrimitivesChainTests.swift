
import XCTest
@testable import Strix

class PrimitivesChainTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func test_operator_flatMap_success() {
        let numberString = Parser { (_) -> Reply<String> in
            return .success("1", [])
        }
        let toInt = { (str: String) -> Parser<Int> in
            return Parser { (_) -> Reply<Int> in
                return .success(Int(str)!, [])
            }
        }
        let p = numberString >>- toInt
        let reply = p.parse(CharacterStream(string: ""))
        XCTAssertEqual(reply.value, 1)
    }
    
    func test_operator_flatMap_failure() {
        let numberString = Parser { (_) -> Reply<String> in
            return .failure([DummyError.err0])
        }
        let toInt = { (str: String) -> Parser<Int> in
            XCTFail()
            return Parser { (_) -> Reply<Int> in
                return .success(Int(str)!, [])
            }
        }
        let p = numberString >>- toInt
        let reply = p.parse(CharacterStream(string: ""))
        XCTAssertNil(reply.value)
        XCTAssertEqual(reply.errors as! [DummyError], [DummyError.err0])
    }
    
    func test_operator_map_success() {
        let numberString = Parser { (_) -> Reply<String> in
            return .success("1", [])
        }
        let toInt = { (str: String) -> Int in
            return Int(str)!
        }
        let p = numberString |>> toInt
        let reply = p.parse(CharacterStream(string: ""))
        XCTAssertEqual(reply.value, 1)
    }
    
    func test_operator_map_failure() {
        let numberString = Parser { (_) -> Reply<String> in
            return .failure([DummyError.err0])
        }
        let toInt = { (str: String) -> Int in
            XCTFail()
            return Int(str)!
        }
        let p = numberString |>> toInt
        let reply = p.parse(CharacterStream(string: ""))
        XCTAssertNil(reply.value)
        XCTAssertEqual(reply.errors as! [DummyError], [DummyError.err0])
    }
    
    func test_operator_another_map_success() {
        let numberString = Parser { (_) -> Reply<String> in
            return .success("1", [])
        }
        let toInt = { (str: String) -> Reply<Int> in
            return .success(Int(str)!, [])
        }
        let p = numberString ^>> toInt
        let reply = p.parse(CharacterStream(string: ""))
        XCTAssertEqual(reply.value, 1)
    }
    
    func test_operator_another_map_failure() {
        let numberString = Parser { (_) -> Reply<String> in
            return .failure([DummyError.err0])
        }
        let toInt = { (str: String) -> Reply<Int> in
            XCTFail()
            return .success(Int(str)!, [])
        }
        let p = numberString ^>> toInt
        let reply = p.parse(CharacterStream(string: ""))
        XCTAssertNil(reply.value)
        XCTAssertEqual(reply.errors as! [DummyError], [DummyError.err0])
    }
    
    func test_operator_just_success() {
        var passed = false
        let numberString = Parser { (_) -> Reply<String> in
            passed = true
            return .success("1", [])
        }
        let p = numberString >>% 2
        let reply = p.parse(CharacterStream(string: ""))
        XCTAssertEqual(reply.value, 2)
        XCTAssertTrue(passed)
    }
    
    func test_operator_just_failure() {
        var passed = false
        let numberString = Parser { (_) -> Reply<String> in
            passed = true
            return .failure([DummyError.err0])
        }
        let p = numberString >>% 2
        let reply = p.parse(CharacterStream(string: ""))
        XCTAssertNil(reply.value)
        XCTAssertEqual(reply.errors as! [DummyError], [DummyError.err0])
        XCTAssertTrue(passed)
    }
    
    func test_operator_right_success() {
        var passed = false
        let p1 = Parser { (_) -> Reply<String> in
            passed = true
            return .success("1", [])
        }
        let p2 = Parser { (_) -> Reply<Int> in
            return .success(2, [])
        }
        let p = p1 >>! p2
        let reply = p.parse(CharacterStream(string: ""))
        XCTAssertEqual(reply.value, 2)
        XCTAssertTrue(passed)
    }
    
    func test_operator_right_failure() {
        var passed = false
        let p1 = Parser { (_) -> Reply<String> in
            passed = true
            return .failure([DummyError.err0])
        }
        let p2 = Parser { (_) -> Reply<Int> in
            XCTFail()
            return .success(2, [])
        }
        let p = p1 >>! p2
        let reply = p.parse(CharacterStream(string: ""))
        XCTAssertNil(reply.value)
        XCTAssertEqual(reply.errors as! [DummyError], [DummyError.err0])
        XCTAssertTrue(passed)
    }
    
    func test_operator_left_success() {
        let p1 = Parser { (_) -> Reply<String> in
            return .success("1", [])
        }
        var passed = false
        let p2 = Parser { (_) -> Reply<Int> in
            passed = true
            return .success(2, [])
        }
        let p = p1 !>> p2
        let reply = p.parse(CharacterStream(string: ""))
        XCTAssertEqual(reply.value, "1")
        XCTAssertTrue(passed)
    }
    
    func test_operator_left_failure() {
        let p1 = Parser { (_) -> Reply<String> in
            return .failure([DummyError.err0])
        }
        let p2 = Parser { (_) -> Reply<Int> in
            XCTFail()
            return .success(2, [])
        }
        let p = p1 !>> p2
        let reply = p.parse(CharacterStream(string: ""))
        XCTAssertNil(reply.value)
        XCTAssertEqual(reply.errors as! [DummyError], [DummyError.err0])
    }
    
    func test_operator_both_success() {
        let p1 = Parser { (_) -> Reply<String> in
            return .success("1", [])
        }
        let p2 = Parser { (_) -> Reply<Int> in
            return .success(2, [])
        }
        let p = p1 !>>! p2
        let reply = p.parse(CharacterStream(string: ""))
        XCTAssertEqual(reply.value?.0, "1")
        XCTAssertEqual(reply.value?.1, 2)
    }
    
    func test_operator_both_failure_left() {
        let p1 = Parser { (_) -> Reply<String> in
            return .failure([DummyError.err0])
        }
        let p2 = Parser { (_) -> Reply<Int> in
            XCTFail()
            return .success(2, [])
        }
        let p = p1 !>>! p2
        let reply = p.parse(CharacterStream(string: ""))
        XCTAssertNil(reply.value)
        XCTAssertEqual(reply.errors as! [DummyError], [DummyError.err0])
    }
    
    func test_operator_both_failure_right() {
        var passed = false
        let p1 = Parser { (_) -> Reply<String> in
            passed = true
            return .success("1", [])
        }
        let p2 = Parser { (_) -> Reply<Int> in
            return .failure([DummyError.err0])
        }
        let p = p1 !>>! p2
        let reply = p.parse(CharacterStream(string: ""))
        XCTAssertNil(reply.value)
        XCTAssertEqual(reply.errors as! [DummyError], [DummyError.err0])
        XCTAssertTrue(passed)
    }
    
    func test_between_success() {
        var passed = [false, false]
        let open = Parser { (_) -> Reply<String> in
            passed[0] = true
            return .success("{", [])
        }
        let close = Parser { (_) -> Reply<String> in
            passed[1] = true
            return .success("}", [])
        }
        let three = Parser { (_) -> Reply<Int> in
            return .success(3, [])
        }
        let p = between(open: open, close: close, parser: three)
        let reply = p.parse(CharacterStream(string: ""))
        XCTAssertEqual(reply.value, 3)
        XCTAssertTrue(passed[0])
        XCTAssertTrue(passed[1])
    }
    
    func test_between_failure_open() {
        var passed = false
        let open = Parser { (_) -> Reply<String> in
            passed = true
            return .failure([DummyError.err0])
        }
        let close = Parser { (_) -> Reply<String> in
            XCTFail()
            return .success("}", [])
        }
        let three = Parser { (_) -> Reply<Int> in
            XCTFail()
            return .success(3, [])
        }
        let p = between(open: open, close: close, parser: three)
        let reply = p.parse(CharacterStream(string: ""))
        XCTAssertNil(reply.value)
        XCTAssertEqual(reply.errors as! [DummyError], [DummyError.err0])
        XCTAssertTrue(passed)
    }
    
    func test_between_failure_parser() {
        var passed = false
        let open = Parser { (_) -> Reply<String> in
            passed = true
            return .success("{", [])
        }
        let close = Parser { (_) -> Reply<String> in
            XCTFail()
            return .success("}", [])
        }
        let three = Parser { (_) -> Reply<Int> in
            return .failure([DummyError.err0])
        }
        let p = between(open: open, close: close, parser: three)
        let reply = p.parse(CharacterStream(string: ""))
        XCTAssertNil(reply.value)
        XCTAssertEqual(reply.errors as! [DummyError], [DummyError.err0])
        XCTAssertTrue(passed)
    }
    
    func test_between_failure_close() {
        var passed = [false, false]
        let open = Parser { (_) -> Reply<String> in
            passed[0] = true
            return .success("{", [])
        }
        let close = Parser { (_) -> Reply<String> in
            return .failure([DummyError.err0])
        }
        let three = Parser { (_) -> Reply<Int> in
            passed[1] = true
            return .success(3, [])
        }
        let p = between(open: open, close: close, parser: three)
        let reply = p.parse(CharacterStream(string: ""))
        XCTAssertNil(reply.value)
        XCTAssertEqual(reply.errors as! [DummyError], [DummyError.err0])
        XCTAssertTrue(passed[0])
        XCTAssertTrue(passed[1])
    }
    
    func test_pipe2_success() {
        let p1 = Parser { (_) -> Reply<String> in
            return .success("1", [])
        }
        let p2 = Parser { (_) -> Reply<Int> in
            return .success(2, [])
        }
        let p = pipe(p1, p2) { (v1, v2) -> String in
            return v1 + String(v2)
        }
        let reply = p.parse(CharacterStream(string: ""))
        XCTAssertEqual(reply.value, "12")
    }
    
    func test_pipe2_failure1() {
        let p1 = Parser { (_) -> Reply<String> in
            return .failure([DummyError.err0])
        }
        let p2 = Parser { (_) -> Reply<Int> in
            XCTFail()
            return .success(2, [])
        }
        let p = pipe(p1, p2) { (v1, v2) -> String in
            XCTFail()
            return v1 + String(v2)
        }
        let reply = p.parse(CharacterStream(string: ""))
        XCTAssertNil(reply.value)
        XCTAssertEqual(reply.errors as! [DummyError], [DummyError.err0])
    }
    
    func test_pipe2_failure2() {
        var passed = false
        let p1 = Parser { (_) -> Reply<String> in
            passed = true
            return .success("1", [])
        }
        let p2 = Parser { (_) -> Reply<Int> in
            return .failure([DummyError.err0])
        }
        let p = pipe(p1, p2) { (v1, v2) -> String in
            XCTFail()
            return v1 + String(v2)
        }
        let reply = p.parse(CharacterStream(string: ""))
        XCTAssertNil(reply.value)
        XCTAssertEqual(reply.errors as! [DummyError], [DummyError.err0])
        XCTAssertTrue(passed)
    }
    
    func test_pipe3_success() {
        let p1 = Parser { (_) -> Reply<String> in
            return .success("1", [])
        }
        let p2 = Parser { (_) -> Reply<Int> in
            return .success(2, [])
        }
        let p3 = Parser { (_) -> Reply<String> in
            return .success("3", [])
        }
        let p = pipe(p1, p2, p3) { (v1, v2, v3) -> String in
            return v1 + String(v2) + v3
        }
        let reply = p.parse(CharacterStream(string: ""))
        XCTAssertEqual(reply.value, "123")
    }
    
    func test_pipe3_failure() {
        var passed = [false, false]
        let p1 = Parser { (_) -> Reply<String> in
            passed[0] = true
            return .success("1", [])
        }
        let p2 = Parser { (_) -> Reply<Int> in
            passed[1] = true
            return .success(2, [])
        }
        let p3 = Parser { (_) -> Reply<String> in
            return .failure([DummyError.err0])
        }
        let p = pipe(p1, p2, p3) { (v1, v2, v3) -> String in
            XCTFail()
            return v1 + String(v2) + v3
        }
        let reply = p.parse(CharacterStream(string: ""))
        XCTAssertNil(reply.value)
        XCTAssertEqual(reply.errors as! [DummyError], [DummyError.err0])
        XCTAssertTrue(passed[0])
        XCTAssertTrue(passed[1])
    }
    
    func test_pipe4_success() {
        let p1 = Parser { (_) -> Reply<String> in
            return .success("1", [])
        }
        let p2 = Parser { (_) -> Reply<Int> in
            return .success(2, [])
        }
        let p3 = Parser { (_) -> Reply<String> in
            return .success("3", [])
        }
        let p4 = Parser { (_) -> Reply<Int> in
            return .success(4, [])
        }
        let f = { (v1: String, v2: Int, v3: String, v4: Int) -> String in
            return v1 + String(v2) + v3 + String(v4)
        }
        let p = pipe(p1, p2, p3, p4, f)
        let reply = p.parse(CharacterStream(string: ""))
        XCTAssertEqual(reply.value, "1234")
    }
    
    func test_pipe4_failure() {
        var passed = [false, false]
        let p1 = Parser { (_) -> Reply<String> in
            passed[0] = true
            return .success("1", [])
        }
        let p2 = Parser { (_) -> Reply<Int> in
            passed[1] = true
            return .success(2, [])
        }
        let p3 = Parser { (_) -> Reply<String> in
            return .failure([DummyError.err0])
        }
        let p4 = Parser { (_) -> Reply<Int> in
            XCTFail()
            return .success(4, [])
        }
        let f = { (v1: String, v2: Int, v3: String, v4: Int) -> String in
            XCTFail()
            return v1 + String(v2) + v3 + String(v4)
        }
        let p = pipe(p1, p2, p3, p4, f)
        let reply = p.parse(CharacterStream(string: ""))
        XCTAssertNil(reply.value)
        XCTAssertEqual(reply.errors as! [DummyError], [DummyError.err0])
        XCTAssertTrue(passed[0])
        XCTAssertTrue(passed[1])
    }
    
    func test_pipe5_success() {
        let p1 = Parser { (_) -> Reply<String> in
            return .success("1", [])
        }
        let p2 = Parser { (_) -> Reply<Int> in
            return .success(2, [])
        }
        let p3 = Parser { (_) -> Reply<String> in
            return .success("3", [])
        }
        let p4 = Parser { (_) -> Reply<Int> in
            return .success(4, [])
        }
        let p5 = Parser { (_) -> Reply<String> in
            return .success("5", [])
        }
        let f = { (v1: String, v2: Int, v3: String, v4: Int, v5: String) -> String in
            return v1 + String(v2) + v3 + String(v4) + v5
        }
        let p = pipe(p1, p2, p3, p4, p5, f)
        let reply = p.parse(CharacterStream(string: ""))
        XCTAssertEqual(reply.value, "12345")
    }
    
    func test_pipe5_failure() {
        var passed = [false, false, false]
        let p1 = Parser { (_) -> Reply<String> in
            passed[0] = true
            return .success("1", [])
        }
        let p2 = Parser { (_) -> Reply<Int> in
            passed[1] = true
            return .success(2, [])
        }
        let p3 = Parser { (_) -> Reply<String> in
            passed[2] = true
            return .success("3", [])
        }
        let p4 = Parser { (_) -> Reply<Int> in
            .failure([DummyError.err0])
        }
        let p5 = Parser { (_) -> Reply<String> in
            XCTFail()
            return .success("5", [])
        }
        let f = { (v1: String, v2: Int, v3: String, v4: Int, v5: String) -> String in
            XCTFail()
            return v1 + String(v2) + v3 + String(v4) + v5
        }
        let p = pipe(p1, p2, p3, p4, p5, f)
        let reply = p.parse(CharacterStream(string: ""))
        XCTAssertNil(reply.value)
        XCTAssertEqual(reply.errors as! [DummyError], [DummyError.err0])
        XCTAssertTrue(passed[0])
        XCTAssertTrue(passed[1])
        XCTAssertTrue(passed[2])
    }
}



