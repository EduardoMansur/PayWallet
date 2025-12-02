import Foundation
import Observation
import Dependencies

protocol TransferViewModelProtocol {
    var selectedContact: Contact? { get set }
    var amount: String { get set }
    var isLoading: Bool { get }
    var errorMessage: String? { get }
    var showError: Bool { get set }
    var showConfirmation: Bool { get set }
    var transferSuccess: Bool { get }

    func initiateTransfer(currentBalance: Double, currentUserId: String) async
    func confirmTransfer() async
}

@Observable
final class TransferViewModel: TransferViewModelProtocol {
    var selectedContact: Contact?
    var amount: String = ""
    private(set) var isLoading: Bool = false
    private(set) var errorMessage: String?
    var showError: Bool = false
    var showConfirmation: Bool = false
    private(set) var transferSuccess: Bool = false

    @ObservationIgnored
    @Dependency(\.transferService) var transferService

    @ObservationIgnored
    @Dependency(\.keychainService) var keychainService

    @ObservationIgnored
    @Dependency(\.notificationManager) var notificationManager

    private var currentBalance: Double = 0
    private var currentUserId: String = ""

    init() {}

    @MainActor
    func initiateTransfer(currentBalance: Double, currentUserId: String) async {
        self.currentBalance = currentBalance
        self.currentUserId = currentUserId

        // Validate inputs
        guard let contact = selectedContact else {
            showErrorMessage("Please select a contact")
            return
        }

        guard let amountValue = Double(amount), amountValue > 0 else {
            showErrorMessage(TransferError.invalidAmount.errorDescription ?? "Invalid amount")
            return
        }

        // Check if trying to send to self
        if contact.id == currentUserId {
            showErrorMessage(TransferError.cannotTransferToSelf.errorDescription ?? "Cannot transfer to yourself")
            return
        }

        // Check sufficient balance
        if amountValue > currentBalance {
            showErrorMessage(TransferError.insufficientBalance.errorDescription ?? "Insufficient balance")
            return
        }

        // Show confirmation dialog
        showConfirmation = true
    }

    @MainActor
    func confirmTransfer() async {
        showConfirmation = false
        isLoading = true
        errorMessage = nil
        showError = false
        transferSuccess = false

        guard let contact = selectedContact,
              let amountValue = Double(amount) else {
            showErrorMessage("Invalid transfer data")
            isLoading = false
            return
        }

        do {
            let token = try await keychainService.getAuthToken()
            let response = try await transferService.authorizeTransfer(
                recipientId: contact.id,
                amount: amountValue,
                token: token
            )

            if response.authorized {
                // Send notification
                await notificationManager.sendTransferSuccessNotification(
                    amount: amountValue,
                    recipientName: contact.name
                )

                transferSuccess = true
            } else {
                showErrorMessage(response.message ?? "Transfer was not authorized. Please try again later.")
            }
        } catch let error as TransferError {
            showErrorMessage(error.errorDescription ?? "Transfer failed")
        } catch {
            showErrorMessage("An unexpected error occurred: \(error.localizedDescription)")
        }

        isLoading = false
    }

    @MainActor
    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }

    func resetTransfer() {
        selectedContact = nil
        amount = ""
        transferSuccess = false
        errorMessage = nil
        showError = false
    }
}
