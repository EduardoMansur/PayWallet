import XCTest
import Dependencies
@testable import PayWallet

@MainActor
final class HomeViewModelTests: XCTestCase {

    // MARK: - Load Data Tests

    func testLoadData_Success_LoadsUserProfileAndContacts() async {
        let keychainServiceMock = KeychainServiceMock()
        let userProfileServiceMock = UserProfileServiceMock()
        let contactsServiceMock = ContactsServiceMock()

        keychainServiceMock.tokenToReturn = "test_token"
        userProfileServiceMock.profileToReturn = UserProfile(
            userId: "user_456",
            name: "Jane Doe",
            email: "jane@paywallet.com",
            balance: 500.0
        )
        contactsServiceMock.contactsToReturn = [
            Contact(id: "1", name: "Contact 1", email: "c1@test.com", avatarURL: nil)
        ]

        let sut = withDependencies {
            $0.keychainService = keychainServiceMock
            $0.userProfileService = userProfileServiceMock
            $0.contactsService = contactsServiceMock
            $0.authenticationManager = AuthenticationManagerMock()
        } operation: {
            return HomeViewModel()
        }

        await sut.loadData()

        XCTAssertTrue(keychainServiceMock.getAuthTokenCalled, "Should retrieve auth token")
        XCTAssertTrue(userProfileServiceMock.getUserProfileCalled, "Should fetch user profile")
        XCTAssertTrue(contactsServiceMock.getContactsCalled, "Should fetch contacts")

        XCTAssertEqual(sut.userId, "user_456")
        XCTAssertEqual(sut.userName, "Jane Doe")
        XCTAssertEqual(sut.userEmail, "jane@paywallet.com")
        XCTAssertEqual(sut.balance, 500.0)
        XCTAssertEqual(sut.contacts.count, 1)
        XCTAssertEqual(sut.contacts.first?.name, "Contact 1")
        XCTAssertNil(sut.errorMessage)
        XCTAssertFalse(sut.isLoading)
    }

    func testLoadData_LoadsDataInParallel() async {
        let keychainServiceMock = KeychainServiceMock()
        let userProfileServiceMock = UserProfileServiceMock()
        let contactsServiceMock = ContactsServiceMock()

        keychainServiceMock.tokenToReturn = "test_token"

        let sut = withDependencies {
            $0.keychainService = keychainServiceMock
            $0.userProfileService = userProfileServiceMock
            $0.contactsService = contactsServiceMock
            $0.authenticationManager = AuthenticationManagerMock()
        } operation: {
            return HomeViewModel()
        }

        await sut.loadData()

        XCTAssertEqual(userProfileServiceMock.getUserProfileCallCount, 1)
        XCTAssertEqual(contactsServiceMock.getContactsCallCount, 1)
    }

    func testLoadData_SetsLoadingStateCorrectly() async {
        let keychainServiceMock = KeychainServiceMock()
        let userProfileServiceMock = UserProfileServiceMock()
        let contactsServiceMock = ContactsServiceMock()

        keychainServiceMock.tokenToReturn = "test_token"

        let sut = withDependencies {
            $0.keychainService = keychainServiceMock
            $0.userProfileService = userProfileServiceMock
            $0.contactsService = contactsServiceMock
            $0.authenticationManager = AuthenticationManagerMock()
        } operation: {
            return HomeViewModel()
        }

        XCTAssertFalse(sut.isLoading, "Should not be loading initially")

        await sut.loadData()

        XCTAssertFalse(sut.isLoading, "Should not be loading after completion")
    }

    func testLoadData_UsesCorrectToken() async {
        let keychainServiceMock = KeychainServiceMock()
        let userProfileServiceMock = UserProfileServiceMock()
        let contactsServiceMock = ContactsServiceMock()

        keychainServiceMock.tokenToReturn = "specific_token_123"

        let sut = withDependencies {
            $0.keychainService = keychainServiceMock
            $0.userProfileService = userProfileServiceMock
            $0.contactsService = contactsServiceMock
            $0.authenticationManager = AuthenticationManagerMock()
        } operation: {
            return HomeViewModel()
        }

        await sut.loadData()

        XCTAssertEqual(userProfileServiceMock.tokenUsed, "specific_token_123")
        XCTAssertEqual(contactsServiceMock.tokenUsed, "specific_token_123")
    }

    // MARK: - Error Handling Tests

    func testLoadData_KeychainError_SetsErrorMessage() async {
        let keychainServiceMock = KeychainServiceMock()
        let userProfileServiceMock = UserProfileServiceMock()
        let contactsServiceMock = ContactsServiceMock()

        keychainServiceMock.shouldThrowOnGet = true

        let sut = withDependencies {
            $0.keychainService = keychainServiceMock
            $0.userProfileService = userProfileServiceMock
            $0.contactsService = contactsServiceMock
            $0.authenticationManager = AuthenticationManagerMock()
        } operation: {
            return HomeViewModel()
        }

        await sut.loadData()

        XCTAssertEqual(sut.errorMessage, "Failed to retrieve authentication token")
        XCTAssertFalse(userProfileServiceMock.getUserProfileCalled, "Should not call profile service")
        XCTAssertFalse(contactsServiceMock.getContactsCalled, "Should not call contacts service")
    }

    func testLoadData_UserProfileError_SetsErrorMessage() async {
        let keychainServiceMock = KeychainServiceMock()
        let userProfileServiceMock = UserProfileServiceMock()
        let contactsServiceMock = ContactsServiceMock()

        keychainServiceMock.tokenToReturn = "test_token"
        userProfileServiceMock.shouldThrowError = true
        userProfileServiceMock.errorToThrow = .networkError

        let sut = withDependencies {
            $0.keychainService = keychainServiceMock
            $0.userProfileService = userProfileServiceMock
            $0.contactsService = contactsServiceMock
            $0.authenticationManager = AuthenticationManagerMock()
        } operation: {
            return HomeViewModel()
        }

        await sut.loadData()

        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage?.contains("Network error") ?? false)
        XCTAssertEqual(sut.userId, "")
        XCTAssertEqual(sut.userName, "")
        XCTAssertEqual(sut.balance, 0.0)
    }

    func testLoadData_ContactsError_SetsErrorMessage() async {
        let keychainServiceMock = KeychainServiceMock()
        let userProfileServiceMock = UserProfileServiceMock()
        let contactsServiceMock = ContactsServiceMock()

        keychainServiceMock.tokenToReturn = "test_token"
        contactsServiceMock.shouldThrowError = true
        contactsServiceMock.errorToThrow = .unauthorized

        let sut = withDependencies {
            $0.keychainService = keychainServiceMock
            $0.userProfileService = userProfileServiceMock
            $0.contactsService = contactsServiceMock
            $0.authenticationManager = AuthenticationManagerMock()
        } operation: {
            return HomeViewModel()
        }

        await sut.loadData()

        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(contactsServiceMock.getContactsCalled)
        XCTAssertEqual(sut.contacts.count, 0)
    }

    func testLoadData_ProfileSucceedsContactsFails_LoadsProfileOnly() async {
        let keychainServiceMock = KeychainServiceMock()
        let userProfileServiceMock = UserProfileServiceMock()
        let contactsServiceMock = ContactsServiceMock()

        keychainServiceMock.tokenToReturn = "test_token"
        userProfileServiceMock.profileToReturn = UserProfile(
            userId: "user_789",
            name: "Test User",
            email: "testuser@paywallet.com",
            balance: 100.0
        )
        contactsServiceMock.shouldThrowError = true

        let sut = withDependencies {
            $0.keychainService = keychainServiceMock
            $0.userProfileService = userProfileServiceMock
            $0.contactsService = contactsServiceMock
            $0.authenticationManager = AuthenticationManagerMock()
        } operation: {
            return HomeViewModel()
        }

        await sut.loadData()

        XCTAssertEqual(sut.userId, "user_789")
        XCTAssertEqual(sut.userName, "Test User")
        XCTAssertEqual(sut.balance, 100.0)
        XCTAssertEqual(sut.contacts.count, 0)
        XCTAssertNotNil(sut.errorMessage)
    }

    func testLoadData_ContactsSucceedsProfileFails_LoadsContactsOnly() async {
        let keychainServiceMock = KeychainServiceMock()
        let userProfileServiceMock = UserProfileServiceMock()
        let contactsServiceMock = ContactsServiceMock()

        keychainServiceMock.tokenToReturn = "test_token"
        userProfileServiceMock.shouldThrowError = true
        contactsServiceMock.contactsToReturn = [
            Contact(id: "1", name: "Contact 1", email: "c1@test.com", avatarURL: nil)
        ]

        let sut = withDependencies {
            $0.keychainService = keychainServiceMock
            $0.userProfileService = userProfileServiceMock
            $0.contactsService = contactsServiceMock
            $0.authenticationManager = AuthenticationManagerMock()
        } operation: {
            return HomeViewModel()
        }

        await sut.loadData()

        XCTAssertEqual(sut.userId, "")
        XCTAssertEqual(sut.userName, "")
        XCTAssertEqual(sut.balance, 0.0)
        XCTAssertEqual(sut.contacts.count, 1)
        XCTAssertNotNil(sut.errorMessage)
    }

    // MARK: - Initial State Tests

    func testInitialState() async {
        let sut = withDependencies {
            $0.keychainService = KeychainServiceMock()
            $0.userProfileService = UserProfileServiceMock()
            $0.contactsService = ContactsServiceMock()
        } operation: {
            return HomeViewModel()
        }

        XCTAssertEqual(sut.userId, "")
        XCTAssertEqual(sut.userName, "")
        XCTAssertEqual(sut.userEmail, "")
        XCTAssertEqual(sut.balance, 0.0)
        XCTAssertEqual(sut.contacts.count, 0)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }

    func testLoadData_EmptyContacts_HandledCorrectly() async {
        let keychainServiceMock = KeychainServiceMock()
        let userProfileServiceMock = UserProfileServiceMock()
        let contactsServiceMock = ContactsServiceMock()

        keychainServiceMock.tokenToReturn = "test_token"
        contactsServiceMock.contactsToReturn = []

        let sut = withDependencies {
            $0.keychainService = keychainServiceMock
            $0.userProfileService = userProfileServiceMock
            $0.contactsService = contactsServiceMock
            $0.authenticationManager = AuthenticationManagerMock()
        } operation: {
            return HomeViewModel()
        }

        await sut.loadData()

        XCTAssertEqual(sut.contacts.count, 0)
        XCTAssertNil(sut.errorMessage)
    }

    func testLoadData_MultipleContacts_LoadsAll() async {
        let keychainServiceMock = KeychainServiceMock()
        let userProfileServiceMock = UserProfileServiceMock()
        let contactsServiceMock = ContactsServiceMock()

        keychainServiceMock.tokenToReturn = "test_token"
        contactsServiceMock.contactsToReturn = [
            Contact(id: "1", name: "Alice", email: "alice@test.com", avatarURL: nil),
            Contact(id: "2", name: "Bob", email: "bob@test.com", avatarURL: nil),
            Contact(id: "3", name: "Charlie", email: "charlie@test.com", avatarURL: nil)
        ]

        let sut = withDependencies {
            $0.keychainService = keychainServiceMock
            $0.userProfileService = userProfileServiceMock
            $0.contactsService = contactsServiceMock
            $0.authenticationManager = AuthenticationManagerMock()
        } operation: {
            return HomeViewModel()
        }

        await sut.loadData()

        XCTAssertEqual(sut.contacts.count, 3)
        XCTAssertEqual(sut.contacts[0].name, "Alice")
        XCTAssertEqual(sut.contacts[1].name, "Bob")
        XCTAssertEqual(sut.contacts[2].name, "Charlie")
    }
}
