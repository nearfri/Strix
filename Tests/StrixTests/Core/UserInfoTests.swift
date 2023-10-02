import XCTest
@testable import Strix

private struct IsInLinkUserInfoKey: UserInfoKey {
    static let defaultValue: Bool = false
}

private extension UserInfo {
    var isInLink: Bool {
        get { self[IsInLinkUserInfoKey.self] }
        set { self[IsInLinkUserInfoKey.self] = newValue }
    }
}

final class UserInfoTests: XCTestCase {
    var sut: UserInfo = .init()
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        sut = .init()
    }
    
    func test_subscript_computedProperty() {
        // Given
        XCTAssertFalse(sut.isInLink)
        
        // When
        sut.isInLink = true
        
        // Then
        XCTAssertTrue(sut.isInLink)
    }
}
