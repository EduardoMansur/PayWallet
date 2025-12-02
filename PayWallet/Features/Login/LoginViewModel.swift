import Foundation
import Observation
import Dependencies

protocol LoginViewModelProtocol {
    var email: String { get set }
    var password: String { get set }
    var isLoading: Bool { get }
    var errorMessage: String? { get }
    var showError: Bool { get set }

    func login() async
}

@Observable
final class LoginViewModel: LoginViewModelProtocol {
    var email: String = ""
    var password: String = ""
    private(set) var isLoading: Bool = false
    private(set) var errorMessage: String?
    var showError: Bool = false

    @ObservationIgnored
    @Dependency(\.authService) var authService

    @ObservationIgnored
    @Dependency(\.authenticationManager) var authenticationManager

    @ObservationIgnored
    @Dependency(\.keychainService) var keychainService

    init() {}

    @MainActor
    func login() async {
        guard validateInputs() else {
            showErrorMessage("Please enter both email and password")
            return
        }

        isLoading = true
        errorMessage = nil
        showError = false

        do {
            let response = try await authService.login(email: email, password: password)
            try await keychainService.saveAuthToken(response.token)
            authenticationManager.setAuthenticated(true)
        } catch let error as AuthError {
            showErrorMessage(error.errorDescription ?? "Login failed")
        } catch {
            showErrorMessage("An unexpected error occurred: \(error.localizedDescription)")
        }

        isLoading = false
    }

    private func validateInputs() -> Bool {
        return !email.trimmingCharacters(in: .whitespaces).isEmpty &&
               !password.isEmpty
    }

    @MainActor
    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }
}
