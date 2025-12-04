import Foundation
import Observation
import Dependencies

protocol HomeViewModelProtocol {
    var userId: String { get }
    var userName: String { get }
    var userEmail: String { get }
    var balance: Double { get }
    var contacts: [Contact] { get }
    var isLoading: Bool { get }
    var errorMessage: String? { get }

    func loadData() async
    func logout() async
}

@Observable
final class HomeViewModel: HomeViewModelProtocol {
    @ObservationIgnored
    @Dependency(\.userProfileService) var userProfileService

    @ObservationIgnored
    @Dependency(\.contactsService) var contactsService

    @ObservationIgnored
    @Dependency(\.keychainService) var keychainService

    @ObservationIgnored
    @Dependency(\.authenticationManager) var authenticationManager

    var userId: String = ""
    var userName: String = ""
    var userEmail: String = ""
    var balance: Double = 0.0
    var contacts: [Contact] = []
    var isLoading: Bool = false
    var errorMessage: String? = nil

    init() {}

    @MainActor
    func loadData() async {
        isLoading = true
        errorMessage = nil

        do {
            let token = try await keychainService.getAuthToken()

            async let profileResult = loadUserProfile(token: token)
            async let contactsResult = loadContacts(token: token)

            let _ = await (profileResult, contactsResult)
        } catch {
            errorMessage = "Failed to retrieve authentication token"
        }

        isLoading = false
    }

    @MainActor
    private func loadUserProfile(token: String) async {
        do {
            let profile = try await userProfileService.getUserProfile(token: token)
            userId = profile.userId
            userName = profile.name
            userEmail = profile.email
            balance = profile.balance
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func loadContacts(token: String) async {
        do {
            contacts = try await contactsService.getContacts(token: token)
        } catch {
            if errorMessage == nil {
                errorMessage = error.localizedDescription
            }
        }
    }

    @MainActor
    func logout() async {
        do {
            try await authenticationManager.logout()
        } catch {
            errorMessage = "Failed to logout: \(error.localizedDescription)"
        }
    }
}
