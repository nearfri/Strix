import Testing
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

@Suite struct UserInfoTests {
    private var sut: UserInfo = .init()
    
    @Test mutating func subscript_computedProperty() {
        // Given
        #expect(!sut.isInLink)
        
        // When
        sut.isInLink = true
        
        // Then
        #expect(sut.isInLink)
    }
}
