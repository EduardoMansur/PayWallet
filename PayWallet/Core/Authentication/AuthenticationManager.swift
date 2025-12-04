import Foundation
import Observation
import Dependencies

protocol AuthenticationManagerProtocol {
    var isAuthenticated: Bool { get }
    func setAuthenticated(_ value: Bool)
    func checkAuthStatus() async
    func logout() async throws
}

@Observable
final class AuthenticationManager: AuthenticationManagerProtocol {
    private(set) var isAuthenticated: Bool = false

    @ObservationIgnored
    @Dependency(\.authService) var authService

    @ObservationIgnored
    @Dependency(\.keychainService) var keychainService

    init() {}

    func setAuthenticated(_ value: Bool) {
        isAuthenticated = value
    }

    func checkAuthStatus() async {
        isAuthenticated = await authService.validateToken()
    }

    func logout() async throws {
        try await authService.logout()
        try await keychainService.deleteAuthToken()
        isAuthenticated = false
    }
}
