import XCTest
import Dependencies
@testable import PayWallet

@MainActor
final class TransferViewModelTests: XCTestCase {
    let testContact = Contact(id: "contact_1", name: "Alice", email: "alice@test.com", avatarURL: nil)
    let currentUserId = "user_123"
    let currentBalance = 1000.0

    // MARK: - Initial State Tests

    func testInitialState() async {
        let sut = withDependencies {
            $0.transferService = TransferServiceMock()
            $0.keychainService = KeychainServiceMock()
            $0.notificationManager = NotificationManagerMock()
        } operation: {
            return TransferViewModel()
        }

        XCTAssertNil(sut.selectedContact)
        XCTAssertEqual(sut.amount, "")
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
        XCTAssertFalse(sut.showError)
        XCTAssertFalse(sut.showConfirmation)
        XCTAssertFalse(sut.transferSuccess)
    }

    // MARK: - Validation Tests

    func testInitiateTransfer_NoContactSelected_ShowsError() async {
        let sut = withDependencies {
            $0.transferService = TransferServiceMock()
            $0.keychainService = KeychainServiceMock()
            $0.notificationManager = NotificationManagerMock()
        } operation: {
            return TransferViewModel()
        }

        sut.selectedContact = nil
        sut.amount = "100"

        await sut.initiateTransfer(currentBalance: currentBalance, currentUserId: currentUserId)

        XCTAssertTrue(sut.showError)
        XCTAssertEqual(sut.errorMessage, "Please select a contact")
        XCTAssertFalse(sut.showConfirmation)
    }

    func testInitiateTransfer_InvalidAmount_ShowsError() async {
        let sut = withDependencies {
            $0.transferService = TransferServiceMock()
            $0.keychainService = KeychainServiceMock()
            $0.notificationManager = NotificationManagerMock()
        } operation: {
            return TransferViewModel()
        }

        sut.selectedContact = testContact
        sut.amount = "invalid"

        await sut.initiateTransfer(currentBalance: currentBalance, currentUserId: currentUserId)

        XCTAssertTrue(sut.showError)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage?.contains("Please enter a valid amount greater than 0.") ?? false)
        XCTAssertFalse(sut.showConfirmation)
    }

    func testInitiateTransfer_ZeroAmount_ShowsError() async {
        let sut = withDependencies {
            $0.transferService = TransferServiceMock()
            $0.keychainService = KeychainServiceMock()
            $0.notificationManager = NotificationManagerMock()
        } operation: {
            return TransferViewModel()
        }

        sut.selectedContact = testContact
        sut.amount = "0"

        await sut.initiateTransfer(currentBalance: currentBalance, currentUserId: currentUserId)

        XCTAssertTrue(sut.showError)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertFalse(sut.showConfirmation)
    }

    func testInitiateTransfer_NegativeAmount_ShowsError() async {
        let sut = withDependencies {
            $0.transferService = TransferServiceMock()
            $0.keychainService = KeychainServiceMock()
            $0.notificationManager = NotificationManagerMock()
        } operation: {
            return TransferViewModel()
        }

        sut.selectedContact = testContact
        sut.amount = "-50"

        await sut.initiateTransfer(currentBalance: currentBalance, currentUserId: currentUserId)

        XCTAssertTrue(sut.showError)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertFalse(sut.showConfirmation)
    }

    func testInitiateTransfer_InsufficientBalance_ShowsError() async {
        let sut = withDependencies {
            $0.transferService = TransferServiceMock()
            $0.keychainService = KeychainServiceMock()
            $0.notificationManager = NotificationManagerMock()
        } operation: {
            return TransferViewModel()
        }

        sut.selectedContact = testContact
        sut.amount = "2000"

        await sut.initiateTransfer(currentBalance: currentBalance, currentUserId: currentUserId)

        XCTAssertTrue(sut.showError)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage?.contains("Insufficient balance") ?? false)
        XCTAssertFalse(sut.showConfirmation)
    }

    func testInitiateTransfer_TransferToSelf_ShowsError() async {
        let sut = withDependencies {
            $0.transferService = TransferServiceMock()
            $0.keychainService = KeychainServiceMock()
            $0.notificationManager = NotificationManagerMock()
        } operation: {
            return TransferViewModel()
        }

        let selfContact = Contact(id: currentUserId, name: "Me", email: "me@test.com", avatarURL: nil)
        sut.selectedContact = selfContact
        sut.amount = "100"

        await sut.initiateTransfer(currentBalance: currentBalance, currentUserId: currentUserId)

        XCTAssertTrue(sut.showError)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage?.contains("You cannot transfer money to yourself.") ?? false)
        XCTAssertFalse(sut.showConfirmation)
    }

    func testInitiateTransfer_ValidInputs_ShowsConfirmation() async {
        let sut = withDependencies {
            $0.transferService = TransferServiceMock()
            $0.keychainService = KeychainServiceMock()
            $0.notificationManager = NotificationManagerMock()
        } operation: {
            return TransferViewModel()
        }

        sut.selectedContact = testContact
        sut.amount = "100"

        await sut.initiateTransfer(currentBalance: currentBalance, currentUserId: currentUserId)

        XCTAssertFalse(sut.showError)
        XCTAssertNil(sut.errorMessage)
        XCTAssertTrue(sut.showConfirmation)
    }

    func testInitiateTransfer_ExactBalance_ShowsConfirmation() async {
        let sut = withDependencies {
            $0.transferService = TransferServiceMock()
            $0.keychainService = KeychainServiceMock()
            $0.notificationManager = NotificationManagerMock()
        } operation: {
            return TransferViewModel()
        }

        sut.selectedContact = testContact
        sut.amount = "1000"

        await sut.initiateTransfer(currentBalance: currentBalance, currentUserId: currentUserId)

        XCTAssertTrue(sut.showConfirmation)
        XCTAssertFalse(sut.showError)
    }

    // MARK: - Confirm Transfer Success Tests

    func testConfirmTransfer_Success_SendsNotificationAndMarksSuccess() async {
        let transferServiceMock = TransferServiceMock()
        let keychainServiceMock = KeychainServiceMock()
        let notificationManagerMock = NotificationManagerMock()

        keychainServiceMock.tokenToReturn = "auth_token"
        transferServiceMock.responseToReturn = TransferAuthorizationResponse(
            authorized: true,
            message: "Success",
            newBalance: 984.00
        )

        let sut = withDependencies {
            $0.transferService = transferServiceMock
            $0.keychainService = keychainServiceMock
            $0.notificationManager = notificationManagerMock
        } operation: {
            return TransferViewModel()
        }

        sut.selectedContact = testContact
        sut.amount = "250.50"

        await sut.confirmTransfer()

        XCTAssertTrue(keychainServiceMock.getAuthTokenCalled)
        XCTAssertTrue(transferServiceMock.authorizeTransferCalled)
        XCTAssertEqual(transferServiceMock.recipientIdUsed, "contact_1")
        XCTAssertEqual(transferServiceMock.amountUsed, 250.50)
        XCTAssertEqual(transferServiceMock.tokenUsed, "auth_token")

        XCTAssertTrue(notificationManagerMock.sendTransferSuccessNotificationCalled)
        XCTAssertEqual(notificationManagerMock.notificationAmount, 250.50)
        XCTAssertEqual(notificationManagerMock.notificationRecipientName, "Alice")

        XCTAssertTrue(sut.transferSuccess)
        XCTAssertFalse(sut.showError)
        XCTAssertNil(sut.errorMessage)
        XCTAssertFalse(sut.isLoading)
    }

    func testConfirmTransfer_NotAuthorized_ShowsErrorMessage() async {
        let transferServiceMock = TransferServiceMock()
        let keychainServiceMock = KeychainServiceMock()
        let notificationManagerMock = NotificationManagerMock()

        keychainServiceMock.tokenToReturn = "auth_token"
        transferServiceMock.responseToReturn = TransferAuthorizationResponse(
            authorized: false,
            message: "Transaction declined. This amount cannot be processed.",
            newBalance: nil
        )

        let sut = withDependencies {
            $0.transferService = transferServiceMock
            $0.keychainService = keychainServiceMock
            $0.notificationManager = notificationManagerMock
        } operation: {
            return TransferViewModel()
        }

        sut.selectedContact = testContact
        sut.amount = "403"

        await sut.confirmTransfer()

        XCTAssertTrue(transferServiceMock.authorizeTransferCalled)
        XCTAssertFalse(notificationManagerMock.sendTransferSuccessNotificationCalled)
        XCTAssertFalse(sut.transferSuccess)
        XCTAssertTrue(sut.showError)
        XCTAssertEqual(sut.errorMessage, "Transaction declined. This amount cannot be processed.")
    }

    func testConfirmTransfer_NotAuthorizedNoMessage_UsesDefaultMessage() async {
        let transferServiceMock = TransferServiceMock()
        let keychainServiceMock = KeychainServiceMock()
        let notificationManagerMock = NotificationManagerMock()

        keychainServiceMock.tokenToReturn = "auth_token"
        transferServiceMock.responseToReturn = TransferAuthorizationResponse(
            authorized: false,
            message: nil,
            newBalance: nil
        )

        let sut = withDependencies {
            $0.transferService = transferServiceMock
            $0.keychainService = keychainServiceMock
            $0.notificationManager = notificationManagerMock
        } operation: {
            return TransferViewModel()
        }

        sut.selectedContact = testContact
        sut.amount = "100"

        await sut.confirmTransfer()

        XCTAssertTrue(sut.showError)
        XCTAssertEqual(sut.errorMessage, "Transfer was not authorized. Please try again later.")
    }

    // MARK: - Confirm Transfer Error Tests

    func testConfirmTransfer_KeychainError_ShowsError() async {
        let transferServiceMock = TransferServiceMock()
        let keychainServiceMock = KeychainServiceMock()
        let notificationManagerMock = NotificationManagerMock()

        keychainServiceMock.shouldThrowOnGet = true

        let sut = withDependencies {
            $0.transferService = transferServiceMock
            $0.keychainService = keychainServiceMock
            $0.notificationManager = notificationManagerMock
        } operation: {
            return TransferViewModel()
        }

        sut.selectedContact = testContact
        sut.amount = "100"

        await sut.confirmTransfer()

        XCTAssertTrue(sut.showError)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertFalse(transferServiceMock.authorizeTransferCalled)
        XCTAssertFalse(sut.transferSuccess)
    }

    func testConfirmTransfer_ServiceError_ShowsError() async {
        let transferServiceMock = TransferServiceMock()
        let keychainServiceMock = KeychainServiceMock()
        let notificationManagerMock = NotificationManagerMock()

        keychainServiceMock.tokenToReturn = "auth_token"
        transferServiceMock.shouldThrowError = true
        transferServiceMock.errorToThrow = .networkError

        let sut = withDependencies {
            $0.transferService = transferServiceMock
            $0.keychainService = keychainServiceMock
            $0.notificationManager = notificationManagerMock
        } operation: {
            return TransferViewModel()
        }

        sut.selectedContact = testContact
        sut.amount = "100"

        await sut.confirmTransfer()

        XCTAssertTrue(sut.showError)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage?.contains("Network error") ?? false)
        XCTAssertFalse(sut.transferSuccess)
        XCTAssertFalse(notificationManagerMock.sendTransferSuccessNotificationCalled)
    }

    func testConfirmTransfer_UnauthorizedError_ShowsError() async {
        let transferServiceMock = TransferServiceMock()
        let keychainServiceMock = KeychainServiceMock()
        let notificationManagerMock = NotificationManagerMock()

        keychainServiceMock.tokenToReturn = "auth_token"
        transferServiceMock.shouldThrowError = true
        transferServiceMock.errorToThrow = .unauthorized

        let sut = withDependencies {
            $0.transferService = transferServiceMock
            $0.keychainService = keychainServiceMock
            $0.notificationManager = notificationManagerMock
        } operation: {
            return TransferViewModel()
        }

        sut.selectedContact = testContact
        sut.amount = "100"

        await sut.confirmTransfer()

        XCTAssertTrue(sut.showError)
        XCTAssertTrue(sut.errorMessage?.contains("not authorized") ?? false)
    }

    func testConfirmTransfer_InvalidData_ShowsError() async {
        let transferServiceMock = TransferServiceMock()
        let keychainServiceMock = KeychainServiceMock()
        let notificationManagerMock = NotificationManagerMock()

        let sut = withDependencies {
            $0.transferService = transferServiceMock
            $0.keychainService = keychainServiceMock
            $0.notificationManager = notificationManagerMock
        } operation: {
            return TransferViewModel()
        }

        sut.selectedContact = nil
        sut.amount = "invalid"

        await sut.confirmTransfer()

        XCTAssertTrue(sut.showError)
        XCTAssertEqual(sut.errorMessage, "Invalid transfer data")
        XCTAssertFalse(transferServiceMock.authorizeTransferCalled)
    }

    // MARK: - State Management Tests

    func testConfirmTransfer_ClearsConfirmationDialog() async {
        let transferServiceMock = TransferServiceMock()
        let keychainServiceMock = KeychainServiceMock()
        let notificationManagerMock = NotificationManagerMock()

        keychainServiceMock.tokenToReturn = "auth_token"

        let sut = withDependencies {
            $0.transferService = transferServiceMock
            $0.keychainService = keychainServiceMock
            $0.notificationManager = notificationManagerMock
        } operation: {
            return TransferViewModel()
        }

        sut.selectedContact = testContact
        sut.amount = "100"
        sut.showConfirmation = true

        await sut.confirmTransfer()

        XCTAssertFalse(sut.showConfirmation)
    }

    func testConfirmTransfer_ClearsErrorsBeforeAttempt() async {
        let transferServiceMock = TransferServiceMock()
        let keychainServiceMock = KeychainServiceMock()
        let notificationManagerMock = NotificationManagerMock()

        keychainServiceMock.shouldThrowOnGet = true

        let sut = withDependencies {
            $0.transferService = transferServiceMock
            $0.keychainService = keychainServiceMock
            $0.notificationManager = notificationManagerMock
        } operation: {
            return TransferViewModel()
        }

        sut.selectedContact = testContact
        sut.amount = "100"

        await sut.confirmTransfer()

        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.showError)

        keychainServiceMock.shouldThrowOnGet = false
        keychainServiceMock.tokenToReturn = "auth_token"

        await sut.confirmTransfer()

        XCTAssertNil(sut.errorMessage)
        XCTAssertFalse(sut.showError)
    }

    func testConfirmTransfer_SetsLoadingState() async {
        let transferServiceMock = TransferServiceMock()
        let keychainServiceMock = KeychainServiceMock()
        let notificationManagerMock = NotificationManagerMock()

        keychainServiceMock.tokenToReturn = "auth_token"

        let sut = withDependencies {
            $0.transferService = transferServiceMock
            $0.keychainService = keychainServiceMock
            $0.notificationManager = notificationManagerMock
        } operation: {
            return TransferViewModel()
        }

        sut.selectedContact = testContact
        sut.amount = "100"

        XCTAssertFalse(sut.isLoading)

        let task = Task {
            await sut.confirmTransfer()
        }

        await task.value

        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - Reset Transfer Tests

    func testResetTransfer_ClearsAllState() async {
        let transferServiceMock = TransferServiceMock()
        let keychainServiceMock = KeychainServiceMock()
        let notificationManagerMock = NotificationManagerMock()

        keychainServiceMock.tokenToReturn = "auth_token"

        let sut = withDependencies {
            $0.transferService = transferServiceMock
            $0.keychainService = keychainServiceMock
            $0.notificationManager = notificationManagerMock
        } operation: {
            return TransferViewModel()
        }

        sut.selectedContact = testContact
        sut.amount = "100"

        await sut.confirmTransfer()

        XCTAssertTrue(sut.transferSuccess)

        sut.resetTransfer()

        XCTAssertNil(sut.selectedContact)
        XCTAssertEqual(sut.amount, "")
        XCTAssertFalse(sut.transferSuccess)
        XCTAssertNil(sut.errorMessage)
        XCTAssertFalse(sut.showError)
    }

    // MARK: - Integration Tests

    func testFullTransferFlow_Success() async {
        let transferServiceMock = TransferServiceMock()
        let keychainServiceMock = KeychainServiceMock()
        let notificationManagerMock = NotificationManagerMock()

        keychainServiceMock.tokenToReturn = "integration_token"

        let sut = withDependencies {
            $0.transferService = transferServiceMock
            $0.keychainService = keychainServiceMock
            $0.notificationManager = notificationManagerMock
        } operation: {
            return TransferViewModel()
        }

        sut.selectedContact = testContact
        sut.amount = "500"

        await sut.initiateTransfer(currentBalance: currentBalance, currentUserId: currentUserId)

        XCTAssertTrue(sut.showConfirmation)
        XCTAssertFalse(sut.showError)

        await sut.confirmTransfer()

        XCTAssertTrue(transferServiceMock.authorizeTransferCalled)
        XCTAssertEqual(transferServiceMock.amountUsed, 500.0)
        XCTAssertEqual(transferServiceMock.recipientIdUsed, "contact_1")
        XCTAssertTrue(notificationManagerMock.sendTransferSuccessNotificationCalled)
        XCTAssertTrue(sut.transferSuccess)
        XCTAssertFalse(sut.isLoading)
    }

    func testFullTransferFlow_Declined() async {
        let transferServiceMock = TransferServiceMock()
        let keychainServiceMock = KeychainServiceMock()
        let notificationManagerMock = NotificationManagerMock()

        keychainServiceMock.tokenToReturn = "integration_token"
        transferServiceMock.responseToReturn = TransferAuthorizationResponse(
            authorized: false,
            message: "Declined",
            newBalance: nil
        )

        let sut = withDependencies {
            $0.transferService = transferServiceMock
            $0.keychainService = keychainServiceMock
            $0.notificationManager = notificationManagerMock
        } operation: {
            return TransferViewModel()
        }

        sut.selectedContact = testContact
        sut.amount = "403"

        await sut.initiateTransfer(currentBalance: currentBalance, currentUserId: currentUserId)

        XCTAssertTrue(sut.showConfirmation)

        await sut.confirmTransfer()

        XCTAssertFalse(sut.transferSuccess)
        XCTAssertTrue(sut.showError)
        XCTAssertEqual(sut.errorMessage, "Declined")
        XCTAssertFalse(notificationManagerMock.sendTransferSuccessNotificationCalled)
    }

    // MARK: - Edge Cases

    func testInitiateTransfer_DecimalAmount_HandlesCorrectly() async {
        let sut = withDependencies {
            $0.transferService = TransferServiceMock()
            $0.keychainService = KeychainServiceMock()
            $0.notificationManager = NotificationManagerMock()
        } operation: {
            return TransferViewModel()
        }

        sut.selectedContact = testContact
        sut.amount = "99.99"

        await sut.initiateTransfer(currentBalance: currentBalance, currentUserId: currentUserId)

        XCTAssertTrue(sut.showConfirmation)
    }

    func testInitiateTransfer_SmallAmount_Allowed() async {
        let sut = withDependencies {
            $0.transferService = TransferServiceMock()
            $0.keychainService = KeychainServiceMock()
            $0.notificationManager = NotificationManagerMock()
        } operation: {
            return TransferViewModel()
        }

        sut.selectedContact = testContact
        sut.amount = "0.01"

        await sut.initiateTransfer(currentBalance: currentBalance, currentUserId: currentUserId)

        XCTAssertTrue(sut.showConfirmation)
        XCTAssertFalse(sut.showError)
    }

    func testConfirmTransfer_LargeAmount_ProcessedCorrectly() async {
        let transferServiceMock = TransferServiceMock()
        let keychainServiceMock = KeychainServiceMock()
        let notificationManagerMock = NotificationManagerMock()

        keychainServiceMock.tokenToReturn = "auth_token"

        let sut = withDependencies {
            $0.transferService = transferServiceMock
            $0.keychainService = keychainServiceMock
            $0.notificationManager = notificationManagerMock
        } operation: {
            return TransferViewModel()
        }

        sut.selectedContact = testContact
        sut.amount = "999.99"

        await sut.confirmTransfer()

        XCTAssertEqual(transferServiceMock.amountUsed, 999.99)
        XCTAssertTrue(sut.transferSuccess)
    }
}
