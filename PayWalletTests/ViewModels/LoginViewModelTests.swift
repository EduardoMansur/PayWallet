import XCTest
import Dependencies
@testable import PayWallet

@MainActor
final class LoginViewModelTests: XCTestCase {

    // MARK: - Initial State Tests

    func testInitialState() async {
        let sut = withDependencies {
            $0.authService = AuthServiceMock()
            $0.keychainService = KeychainServiceMock()
            $0.authenticationManager = AuthenticationManagerMock()
        } operation: {
            return LoginViewModel()
        }

        XCTAssertEqual(sut.email, "")
        XCTAssertEqual(sut.password, "")
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
        XCTAssertFalse(sut.showError)
    }

    // MARK: - Successful Login Tests

    func testLogin_ValidCredentials_Success() async {
        let authServiceMock = AuthServiceMock()
        let keychainServiceMock = KeychainServiceMock()
        let authenticationManagerMock = AuthenticationManagerMock()

        authServiceMock.loginResponseToReturn = LoginResponse(
            token: "valid_token",
            userId: "user_123",
            email: "test@example.com"
        )

        let sut = withDependencies {
            $0.authService = authServiceMock
            $0.keychainService = keychainServiceMock
            $0.authenticationManager = authenticationManagerMock
        } operation: {
            return LoginViewModel()
        }

        sut.email = "test@example.com"
        sut.password = "password123"

        await sut.login()

        XCTAssertTrue(authServiceMock.loginCalled, "Should call login service")
        XCTAssertEqual(authServiceMock.loginEmail, "test@example.com")
        XCTAssertEqual(authServiceMock.loginPassword, "password123")
        XCTAssertTrue(keychainServiceMock.saveAuthTokenCalled, "Should save token to keychain")
        XCTAssertEqual(keychainServiceMock.savedToken, "valid_token")
        XCTAssertTrue(authenticationManagerMock.setAuthenticatedCalled, "Should set authenticated")
        XCTAssertEqual(authenticationManagerMock.authenticatedValueSet, true)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
        XCTAssertFalse(sut.showError)
    }

    func testLogin_TrimmedEmail_UsesCorrectEmail() async {
        let authServiceMock = AuthServiceMock()
        let keychainServiceMock = KeychainServiceMock()
        let authenticationManagerMock = AuthenticationManagerMock()

        let sut = withDependencies {
            $0.authService = authServiceMock
            $0.keychainService = keychainServiceMock
            $0.authenticationManager = authenticationManagerMock
        } operation: {
            return LoginViewModel()
        }

        sut.email = "  test@example.com  "
        sut.password = "password123"

        await sut.login()

        XCTAssertTrue(authServiceMock.loginCalled)
        XCTAssertEqual(authServiceMock.loginEmail, "  test@example.com  ")
    }

    // MARK: - Validation Tests

    func testLogin_EmptyEmail_ShowsError() async {
        let authServiceMock = AuthServiceMock()

        let sut = withDependencies {
            $0.authService = authServiceMock
            $0.keychainService = KeychainServiceMock()
            $0.authenticationManager = AuthenticationManagerMock()
        } operation: {
            return LoginViewModel()
        }

        sut.email = ""
        sut.password = "password123"

        await sut.login()

        XCTAssertFalse(authServiceMock.loginCalled, "Should not call login service")
        XCTAssertTrue(sut.showError)
        XCTAssertEqual(sut.errorMessage, "Please enter both email and password")
    }

    func testLogin_EmptyPassword_ShowsError() async {
        let authServiceMock = AuthServiceMock()

        let sut = withDependencies {
            $0.authService = authServiceMock
            $0.keychainService = KeychainServiceMock()
            $0.authenticationManager = AuthenticationManagerMock()
        } operation: {
            return LoginViewModel()
        }

        sut.email = "test@example.com"
        sut.password = ""

        await sut.login()

        XCTAssertFalse(authServiceMock.loginCalled, "Should not call login service")
        XCTAssertTrue(sut.showError)
        XCTAssertEqual(sut.errorMessage, "Please enter both email and password")
    }

    func testLogin_WhitespaceOnlyEmail_ShowsError() async {
        let authServiceMock = AuthServiceMock()

        let sut = withDependencies {
            $0.authService = authServiceMock
            $0.keychainService = KeychainServiceMock()
            $0.authenticationManager = AuthenticationManagerMock()
        } operation: {
            return LoginViewModel()
        }

        sut.email = "   "
        sut.password = "password123"

        await sut.login()

        XCTAssertFalse(authServiceMock.loginCalled, "Should not call login service")
        XCTAssertTrue(sut.showError)
        XCTAssertEqual(sut.errorMessage, "Please enter both email and password")
    }

    func testLogin_BothEmpty_ShowsError() async {
        let authServiceMock = AuthServiceMock()

        let sut = withDependencies {
            $0.authService = authServiceMock
            $0.keychainService = KeychainServiceMock()
            $0.authenticationManager = AuthenticationManagerMock()
        } operation: {
            return LoginViewModel()
        }

        sut.email = ""
        sut.password = ""

        await sut.login()

        XCTAssertFalse(authServiceMock.loginCalled, "Should not call login service")
        XCTAssertTrue(sut.showError)
        XCTAssertEqual(sut.errorMessage, "Please enter both email and password")
    }

    // MARK: - Error Handling Tests

    func testLogin_InvalidCredentials_ShowsError() async {
        let authServiceMock = AuthServiceMock()
        let keychainServiceMock = KeychainServiceMock()
        let authenticationManagerMock = AuthenticationManagerMock()

        authServiceMock.shouldThrowOnLogin = true
        authServiceMock.loginErrorToThrow = .invalidCredentials

        let sut = withDependencies {
            $0.authService = authServiceMock
            $0.keychainService = keychainServiceMock
            $0.authenticationManager = authenticationManagerMock
        } operation: {
            return LoginViewModel()
        }

        sut.email = "test@example.com"
        sut.password = "wrongpassword"

        await sut.login()

        XCTAssertTrue(authServiceMock.loginCalled)
        XCTAssertFalse(keychainServiceMock.saveAuthTokenCalled, "Should not save token")
        XCTAssertFalse(authenticationManagerMock.setAuthenticatedCalled, "Should not set authenticated")
        XCTAssertTrue(sut.showError)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage?.contains("Invalid email or password") ?? false)
        XCTAssertFalse(sut.isLoading)
    }

    func testLogin_NetworkError_ShowsError() async {
        let authServiceMock = AuthServiceMock()
        let authenticationManagerMock = AuthenticationManagerMock()

        authServiceMock.shouldThrowOnLogin = true
        authServiceMock.loginErrorToThrow = .networkError

        let sut = withDependencies {
            $0.authService = authServiceMock
            $0.keychainService = KeychainServiceMock()
            $0.authenticationManager = authenticationManagerMock
        } operation: {
            return LoginViewModel()
        }

        sut.email = "test@example.com"
        sut.password = "password123"

        await sut.login()

        XCTAssertTrue(sut.showError)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage?.contains("Network error") ?? false)
        XCTAssertFalse(authenticationManagerMock.setAuthenticatedCalled)
    }

    func testLogin_UnknownError_ShowsError() async {
        let authServiceMock = AuthServiceMock()
        let authenticationManagerMock = AuthenticationManagerMock()

        authServiceMock.shouldThrowOnLogin = true
        authServiceMock.loginErrorToThrow = .unknown

        let sut = withDependencies {
            $0.authService = authServiceMock
            $0.keychainService = KeychainServiceMock()
            $0.authenticationManager = authenticationManagerMock
        } operation: {
            return LoginViewModel()
        }

        sut.email = "test@example.com"
        sut.password = "password123"

        await sut.login()

        XCTAssertTrue(sut.showError)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertFalse(authenticationManagerMock.setAuthenticatedCalled)
    }

    func testLogin_KeychainSaveError_ShowsError() async {
        let authServiceMock = AuthServiceMock()
        let keychainServiceMock = KeychainServiceMock()
        let authenticationManagerMock = AuthenticationManagerMock()

        keychainServiceMock.shouldThrowOnSave = true

        let sut = withDependencies {
            $0.authService = authServiceMock
            $0.keychainService = keychainServiceMock
            $0.authenticationManager = authenticationManagerMock
        } operation: {
            return LoginViewModel()
        }

        sut.email = "test@example.com"
        sut.password = "password123"

        await sut.login()

        XCTAssertTrue(authServiceMock.loginCalled)
        XCTAssertTrue(keychainServiceMock.saveAuthTokenCalled)
        XCTAssertTrue(sut.showError)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertFalse(authenticationManagerMock.setAuthenticatedCalled)
    }

    // MARK: - Loading State Tests

    func testLogin_SetsLoadingState() async {
        let sut = withDependencies {
            $0.authService = AuthServiceMock()
            $0.keychainService = KeychainServiceMock()
            $0.authenticationManager = AuthenticationManagerMock()
        } operation: {
            return LoginViewModel()
        }

        sut.email = "test@example.com"
        sut.password = "password123"

        XCTAssertFalse(sut.isLoading, "Should not be loading initially")

        await sut.login()

        XCTAssertFalse(sut.isLoading, "Should not be loading after completion")
    }

    func testLogin_ClearsErrorsBeforeNewAttempt() async {
        let authServiceMock = AuthServiceMock()
        let keychainServiceMock = KeychainServiceMock()
        let authenticationManagerMock = AuthenticationManagerMock()

        authServiceMock.shouldThrowOnLogin = true
        authServiceMock.loginErrorToThrow = .networkError

        let sut = withDependencies {
            $0.authService = authServiceMock
            $0.keychainService = keychainServiceMock
            $0.authenticationManager = authenticationManagerMock
        } operation: {
            return LoginViewModel()
        }

        sut.email = "test@example.com"
        sut.password = "password123"

        await sut.login()

        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.showError)

        authServiceMock.shouldThrowOnLogin = false

        await sut.login()

        XCTAssertNil(sut.errorMessage)
        XCTAssertFalse(sut.showError)
    }

    // MARK: - Integration Tests

    func testLogin_FullFlow_SavesTokenAndAuthenticates() async {
        let authServiceMock = AuthServiceMock()
        let keychainServiceMock = KeychainServiceMock()
        let authenticationManagerMock = AuthenticationManagerMock()

        authServiceMock.loginResponseToReturn = LoginResponse(
            token: "integration_token",
            userId: "user_456",
            email: "user@test.com"
        )

        let sut = withDependencies {
            $0.authService = authServiceMock
            $0.keychainService = keychainServiceMock
            $0.authenticationManager = authenticationManagerMock
        } operation: {
            return LoginViewModel()
        }

        sut.email = "user@test.com"
        sut.password = "securepass"

        await sut.login()

        XCTAssertTrue(authServiceMock.loginCalled)
        XCTAssertEqual(authServiceMock.loginEmail, "user@test.com")
        XCTAssertEqual(authServiceMock.loginPassword, "securepass")

        XCTAssertTrue(keychainServiceMock.saveAuthTokenCalled)
        XCTAssertEqual(keychainServiceMock.savedToken, "integration_token")

        XCTAssertTrue(authenticationManagerMock.setAuthenticatedCalled)
        XCTAssertEqual(authenticationManagerMock.authenticatedValueSet, true)

        XCTAssertNil(sut.errorMessage)
        XCTAssertFalse(sut.showError)
        XCTAssertFalse(sut.isLoading)
    }

    func testLogin_MultipleAttempts_CallsServiceEachTime() async {
        let authServiceMock = AuthServiceMock()

        let sut = withDependencies {
            $0.authService = authServiceMock
            $0.keychainService = KeychainServiceMock()
            $0.authenticationManager = AuthenticationManagerMock()
        } operation: {
            return LoginViewModel()
        }

        sut.email = "test@example.com"
        sut.password = "password123"

        await sut.login()
        await sut.login()
        await sut.login()

        XCTAssertTrue(authServiceMock.loginCalled)
    }
}
