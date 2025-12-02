import Foundation
import Observation

protocol HomeViewModelProtocol {
    var userName: String { get }
    var balance: Double { get }
    var contacts: [Contact] { get }
    var isLoading: Bool { get }
    var errorMessage: String? { get }

    func loadData() async
}

@Observable
final class HomeViewModel: HomeViewModelProtocol {
    private let userProfileService: UserProfileServiceProtocol
    private let contactsService: ContactsServiceProtocol
    private let keychainService: KeychainService

    var userName: String = ""
    var balance: Double = 0.0
    var contacts: [Contact] = []
    var isLoading: Bool = false
    var errorMessage: String? = nil

    init(
        userProfileService: UserProfileServiceProtocol = MockUserProfileService(),
        contactsService: ContactsServiceProtocol = MockContactsService(),
        keychainService: KeychainService = .shared
    ) {
        self.userProfileService = userProfileService
        self.contactsService = contactsService
        self.keychainService = keychainService
    }

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
            userName = profile.name
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
}
