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

    private let authService: AuthServiceProtocol

    init(authService: AuthServiceProtocol = MockAuthService()) {
        self.authService = authService
    }

    func setAuthenticated(_ value: Bool) {
        isAuthenticated = value
    }

    func checkAuthStatus() async {
        isAuthenticated = await authService.validateToken()
    }
}
