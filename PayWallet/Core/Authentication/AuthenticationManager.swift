import Foundation
import Observation
import Dependencies

protocol AuthenticationManagerProtocol {
    var isAuthenticated: Bool { get }
    func setAuthenticated(_ value: Bool)
    func checkAuthStatus() async
}

@Observable
final class AuthenticationManager: AuthenticationManagerProtocol {
    private(set) var isAuthenticated: Bool = false

    @ObservationIgnored
    @Dependency(\.authService) var authService

    init() {}

    func setAuthenticated(_ value: Bool) {
        isAuthenticated = value
    }

    func checkAuthStatus() async {
        isAuthenticated = await authService.validateToken()
    }
}
