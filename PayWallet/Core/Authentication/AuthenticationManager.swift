import Foundation
import Observation

protocol AuthenticationManagerProtocol {
    var isAuthenticated: Bool { get }
    func setAuthenticated(_ value: Bool)
    func checkAuthStatus() async
}

@Observable
final class AuthenticationManager: AuthenticationManagerProtocol {
    private(set) var isAuthenticated: Bool = false

    private let keychainService: KeychainService

    init(keychainService: KeychainService = .shared) {
        self.keychainService = keychainService
    }

    func setAuthenticated(_ value: Bool) {
        isAuthenticated = value
    }

    func checkAuthStatus() async {
        isAuthenticated = await keychainService.hasAuthToken()
    }
}
