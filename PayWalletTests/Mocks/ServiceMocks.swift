import Foundation
@testable import PayWallet

// MARK: - KeychainService Mock/Spy
final class KeychainServiceMock: KeychainServiceProtocol {
    // Spy properties
    var saveCalled = false
    var retrieveCalled = false
    var deleteCalled = false
    var saveAuthTokenCalled = false
    var getAuthTokenCalled = false
    var deleteAuthTokenCalled = false
    var hasAuthTokenCalled = false

    var savedToken: String?
    var savedKey: String?
    var savedValue: String?
    var getAuthTokenCallCount = 0

    // Stub properties
    var tokenToReturn: String = "mock_token_123"
    var shouldThrowOnGet = false
    var shouldThrowOnSave = false
    var shouldThrowOnRetrieve = false
    var shouldThrowOnDelete = false
    var hasTokenToReturn = true

    func save(key: String, value: String) async throws {
        saveCalled = true
        savedKey = key
        savedValue = value
        if shouldThrowOnSave {
            throw KeychainError.unexpectedStatus(0)
        }
    }

    func retrieve(key: String) async throws -> String {
        retrieveCalled = true
        if shouldThrowOnRetrieve {
            throw KeychainError.itemNotFound
        }
        return tokenToReturn
    }

    func delete(key: String) async throws {
        deleteCalled = true
        if shouldThrowOnDelete {
            throw KeychainError.unexpectedStatus(0)
        }
    }

    func saveAuthToken(_ token: String) async throws {
        saveAuthTokenCalled = true
        savedToken = token
        if shouldThrowOnSave {
            throw KeychainError.unexpectedStatus(0)
        }
    }

    func getAuthToken() async throws -> String {
        getAuthTokenCalled = true
        getAuthTokenCallCount += 1
        if shouldThrowOnGet {
            throw KeychainError.itemNotFound
        }
        return tokenToReturn
    }

    func deleteAuthToken() async throws {
        deleteAuthTokenCalled = true
        if shouldThrowOnDelete {
            throw KeychainError.unexpectedStatus(0)
        }
    }

    func hasAuthToken() async -> Bool {
        hasAuthTokenCalled = true
        return hasTokenToReturn
    }
}

// MARK: - AuthService Mock/Spy
final class AuthServiceMock: AuthServiceProtocol {
    // Spy properties
    var loginCalled = false
    var logoutCalled = false
    var validateTokenCalled = false

    var loginEmail: String?
    var loginPassword: String?
    var validateTokenCallCount = 0

    // Stub properties
    var loginResponseToReturn: LoginResponse = LoginResponse(
        token: "mock_token_123",
        userId: "user_123",
        email: "test@example.com"
    )
    var shouldThrowOnLogin = false
    var loginErrorToThrow: AuthError = .invalidCredentials
    var shouldThrowOnLogout = false
    var isTokenValidToReturn = true

    func login(email: String, password: String) async throws -> LoginResponse {
        loginCalled = true
        loginEmail = email
        loginPassword = password

        if shouldThrowOnLogin {
            throw loginErrorToThrow
        }

        return loginResponseToReturn
    }

    func logout() async throws {
        logoutCalled = true

        if shouldThrowOnLogout {
            throw AuthError.networkError
        }
    }

    func validateToken() async -> Bool {
        validateTokenCalled = true
        validateTokenCallCount += 1
        return isTokenValidToReturn
    }
}

// MARK: - UserProfileService Mock/Spy
final class UserProfileServiceMock: UserProfileServiceProtocol {
    // Spy properties
    var getUserProfileCalled = false
    var getUserProfileCallCount = 0
    var tokenUsed: String?

    // Stub properties
    var profileToReturn: UserProfile = UserProfile(
        userId: "user_123",
        name: "John Doe",
        balance: 1234.56
    )
    var shouldThrowError = false
    var errorToThrow: UserProfileError = .networkError

    func getUserProfile(token: String) async throws -> UserProfile {
        getUserProfileCalled = true
        getUserProfileCallCount += 1
        tokenUsed = token

        if shouldThrowError {
            throw errorToThrow
        }

        return profileToReturn
    }
}

// MARK: - ContactsService Mock/Spy
final class ContactsServiceMock: ContactsServiceProtocol {
    // Spy properties
    var getContactsCalled = false
    var getContactsCallCount = 0
    var tokenUsed: String?

    // Stub properties
    var contactsToReturn: [Contact] = [
        Contact(id: "1", name: "Alice Johnson", email: "alice@example.com", avatarURL: nil),
        Contact(id: "2", name: "Bob Smith", email: "bob@example.com", avatarURL: nil)
    ]
    var shouldThrowError = false
    var errorToThrow: ContactsError = .networkError

    func getContacts(token: String) async throws -> [Contact] {
        getContactsCalled = true
        getContactsCallCount += 1
        tokenUsed = token

        if shouldThrowError {
            throw errorToThrow
        }

        return contactsToReturn
    }
}

// MARK: - TransferService Mock/Spy
final class TransferServiceMock: TransferServiceProtocol {
    // Spy properties
    var authorizeTransferCalled = false
    var authorizeTransferCallCount = 0
    var recipientIdUsed: String?
    var amountUsed: Double?
    var tokenUsed: String?

    // Stub properties
    var responseToReturn: TransferAuthorizationResponse = TransferAuthorizationResponse(
        authorized: true,
        message: "Transfer authorized successfully"
    )
    var shouldThrowError = false
    var errorToThrow: TransferError = .networkError

    func authorizeTransfer(recipientId: String, amount: Double, token: String) async throws -> TransferAuthorizationResponse {
        authorizeTransferCalled = true
        authorizeTransferCallCount += 1
        recipientIdUsed = recipientId
        amountUsed = amount
        tokenUsed = token

        if shouldThrowError {
            throw errorToThrow
        }

        return responseToReturn
    }
}

// MARK: - NotificationManager Mock/Spy
final class NotificationManagerMock: NotificationManagerProtocol {
    // Spy properties
    var requestAuthorizationCalled = false
    var sendTransferSuccessNotificationCalled = false
    var notificationAmount: Double?
    var notificationRecipientName: String?
    var requestAuthorizationCallCount = 0
    var sendNotificationCallCount = 0

    // Stub properties
    var authorizationToReturn = true

    func requestAuthorization() async -> Bool {
        requestAuthorizationCalled = true
        requestAuthorizationCallCount += 1
        return authorizationToReturn
    }

    func sendTransferSuccessNotification(amount: Double, recipientName: String) async {
        sendTransferSuccessNotificationCalled = true
        sendNotificationCallCount += 1
        notificationAmount = amount
        notificationRecipientName = recipientName
    }
}

// MARK: - AuthenticationManager Mock/Spy
final class AuthenticationManagerMock: AuthenticationManagerProtocol {
    // Spy properties
    var setAuthenticatedCalled = false
    var checkAuthStatusCalled = false
    var authenticatedValueSet: Bool?
    var checkAuthStatusCallCount = 0

    // Stub properties
    private(set) var isAuthenticated: Bool = false
    var isAuthenticatedToReturn = false

    func setAuthenticated(_ value: Bool) {
        setAuthenticatedCalled = true
        authenticatedValueSet = value
        isAuthenticated = value
    }

    func checkAuthStatus() async {
        checkAuthStatusCalled = true
        checkAuthStatusCallCount += 1
        isAuthenticated = isAuthenticatedToReturn
    }
}
