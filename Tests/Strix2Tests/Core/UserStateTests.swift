import XCTest
@testable import Strix2

private extension UserStateKey {
    static let isInLink: UserStateKey = "com.ukjeong.html.isInLink"
}

private extension UserState {
    var isInLink: Bool {
        get { self[.isInLink] as? Bool ?? false }
        set { self[.isInLink] = newValue }
    }
}

final class UserStateTests: XCTestCase {
    var sut: UserState = .init()
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        sut = .init()
    }
    
    func test_subscript_setAndGet() {
        // Given
        XCTAssertNil(sut["hello"])
        
        // When
        sut["hello"] = "world"
        
        // Then
        XCTAssertEqual(sut["hello"], "world")
    }
    
    func test_subscript_computedProperty() {
        // Given
        XCTAssertFalse(sut.isInLink)
        
        // When
        sut.isInLink = true
        
        // Then
        XCTAssert(sut.isInLink)
    }
}
