import Foundation
import NetworkLayer

struct LoginResponse: Codable {
    let token: String
    let userId: String
    let email: String
}

struct LoginCredentials: Codable {
    let email: String
    let password: String
}

protocol AuthServiceProtocol {
    func login(email: String, password: String) async throws -> LoginResponse
    func logout() async throws
    func validateToken() async -> Bool
}

final class AuthService: AuthServiceProtocol {
    private let networkClient: NetworkClient
    private let keychainService: KeychainServiceProtocol

    init(networkClient: NetworkClient = NetworkClient(), keychainService: KeychainServiceProtocol = KeychainService.shared) {
        self.networkClient = networkClient
        self.keychainService = keychainService
    }

    func login(email: String, password: String) async throws -> LoginResponse {
        let credentials = LoginCredentials(email: email, password: password)
        let request = LoginRequest(credentials: credentials)

        do {
            return try await networkClient.execute(request)
        } catch let error as NetworkError {
            throw mapNetworkError(error)
        } catch {
            throw AuthError.unknown
        }
    }

    func logout() async throws {
        let request = LogoutRequest()

        do {
            _ = try await networkClient.executeStatusCode(request)
        } catch let error as NetworkError {
            throw mapNetworkError(error)
        } catch {
            throw AuthError.unknown
        }
    }

    func validateToken() async -> Bool {
        do {
            let token = try await keychainService.getAuthToken()
            let request = ValidateTokenRequest(token: token)

            let response: ValidateTokenResponse = try await networkClient.execute(request)
            return response.isValid
        } catch {
            return false
        }
    }

    private func mapNetworkError(_ error: NetworkError) -> AuthError {
        switch error {
        case .httpError(let statusCode, _):
            if statusCode == 401 || statusCode == 403 {
                return .invalidCredentials
            }
            return .networkError
        case .networkFailure, .timeout:
            return .networkError
        default:
            return .unknown
        }
    }
}

final class MockAuthService: AuthServiceProtocol {
    private let networkClient: NetworkClient
    private let keychainService: KeychainServiceProtocol

    init(keychainService: KeychainServiceProtocol = KeychainService.shared) {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        self.networkClient = NetworkClient(configuration: configuration)
        self.keychainService = keychainService
    }

    func login(email: String, password: String) async throws -> LoginResponse {
        let credentials = LoginCredentials(email: email, password: password)
        let request = LoginRequest(credentials: credentials)

        do {
            let response = try await networkClient.execute(request)
            return response
        } catch let error as NetworkError {
            switch error {
            case .httpError(let statusCode, _):
                if statusCode == 401 {
                    throw AuthError.invalidCredentials
                }
                throw AuthError.networkError
            default:
                throw AuthError.networkError
            }
        } catch {
            throw AuthError.unknown
        }
    }

    func logout() async throws {
        try await Task.sleep(nanoseconds: 500_000_000)
    }

    func validateToken() async -> Bool {
        do {
            let token = try await keychainService.getAuthToken()
            let request = ValidateTokenRequest(token: token)

            let response: ValidateTokenResponse = try await networkClient.execute(request)
            return response.isValid
        } catch {
            return false
        }
    }
}

struct LoginRequest: NetworkRequest {
    typealias Response = LoginResponse

    let credentials: LoginCredentials

    var baseURL: String { "https://api.paywallet.com" }
    var path: String { "/auth/login" }
    var method: HTTPMethod { .post }
    var encodableBody: Encodable? { credentials }
}

struct LogoutRequest: NetworkRequest {
    typealias Response = EmptyResponse

    var baseURL: String { "https://api.paywallet.com" }
    var path: String { "/auth/logout" }
    var method: HTTPMethod { .post }
}

struct ValidateTokenRequest: NetworkRequest {
    typealias Response = ValidateTokenResponse

    let token: String

    var baseURL: String { "https://api.paywallet.com" }
    var path: String { "/auth/validate" }
    var method: HTTPMethod { .get }
    var headers: [String: String]? {
        ["Authorization": "Bearer \(token)"]
    }
}

struct ValidateTokenResponse: Codable {
    let isValid: Bool
}

struct EmptyResponse: Codable {}

enum AuthError: LocalizedError {
    case invalidCredentials
    case networkError
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password. Try test@paywallet.com / password123"
        case .networkError:
            return "Network error occurred. Please try again."
        case .unknown:
            return "An unknown error occurred."
        }
    }
}

final class MockURLProtocol: URLProtocol {
    private static let requestBodyKey = "MockURLProtocol.requestBody"
    private var activeTask: Task<Void, Never>?

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canInit(with task: URLSessionTask) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        guard let mutableRequest = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest else {
            return request
        }

        // Capture the body data before URLSession consumes it
        if let bodyData = request.httpBody {
            URLProtocol.setProperty(bodyData, forKey: requestBodyKey, in: mutableRequest)
        } else if let bodyStream = request.httpBodyStream {
            // Read from stream if httpBody is not available
            bodyStream.open()
            let bufferSize = 4096
            var buffer = [UInt8](repeating: 0, count: bufferSize)
            var data = Data()

            while bodyStream.hasBytesAvailable {
                let bytesRead = bodyStream.read(&buffer, maxLength: bufferSize)
                if bytesRead > 0 {
                    data.append(buffer, count: bytesRead)
                } else {
                    break
                }
            }
            bodyStream.close()

            if !data.isEmpty {
                URLProtocol.setProperty(data, forKey: requestBodyKey, in: mutableRequest)
            }
        }

        return mutableRequest as URLRequest
    }

    override func startLoading() {
        activeTask = Task { @MainActor in
            do {
                try await Task.sleep(nanoseconds: 1_500_000_000)

                guard let url = request.url else {
                    sendError()
                    return
                }

                if url.path == "/auth/login" {
                    handleLoginRequest()
                } else if url.path == "/auth/logout" {
                    handleLogoutRequest()
                } else if url.path == "/auth/validate" {
                    handleValidateTokenRequest()
                } else {
                    sendError()
                }
            } catch {
                sendError()
            }
        }
    }

    override func stopLoading() {
        activeTask?.cancel()
        activeTask = nil
    }

    private func handleLoginRequest() {
        // Try to get body from stored property, fallback to httpBody
        let bodyData = URLProtocol.property(forKey: Self.requestBodyKey, in: request) as? Data
            ?? request.httpBody

        guard let body = bodyData else {
            sendError()
            return
        }

        guard let credentials = try? JSONDecoder().decode(LoginCredentials.self, from: body) else {
            sendError()
            return
        }

        if credentials.email == "test@paywallet.com" && credentials.password == "password123" {
            let response = LoginResponse(
                token: "mock_token_\(UUID().uuidString)",
                userId: "user_123",
                email: credentials.email
            )

            sendSuccess(response: response)
        } else {
            sendUnauthorized()
        }
    }

    private func handleLogoutRequest() {
        sendSuccess(response: EmptyResponse())
    }

    private func handleValidateTokenRequest() {
        let authHeader = request.value(forHTTPHeaderField: "Authorization")

        // Check if token is present and follows the Bearer format
        guard let authHeader = authHeader,
              authHeader.hasPrefix("Bearer ") else {
            sendUnauthorized()
            return
        }

        let token = authHeader.replacingOccurrences(of: "Bearer ", with: "")

        // For mock purposes, accept any token that starts with "mock_token_"
        if token.hasPrefix("mock_token_") {
            let response = ValidateTokenResponse(isValid: true)
            sendSuccess(response: response)
        } else {
            let response = ValidateTokenResponse(isValid: false)
            sendSuccess(response: response)
        }
    }

    private func sendSuccess<T: Encodable>(response: T) {
        guard let url = request.url else {
            sendError()
            return
        }

        guard let data = try? JSONEncoder().encode(response) else {
            sendError()
            return
        }

        guard let httpResponse = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        ) else {
            sendError()
            return
        }

        client?.urlProtocol(self, didReceive: httpResponse, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    private func sendUnauthorized() {
        guard let url = request.url else {
            sendError()
            return
        }

        guard let httpResponse = HTTPURLResponse(
            url: url,
            statusCode: 401,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        ) else {
            sendError()
            return
        }

        let errorBody = "{\"error\": \"Invalid credentials\"}".data(using: .utf8) ?? Data()

        client?.urlProtocol(self, didReceive: httpResponse, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: errorBody)
        client?.urlProtocolDidFinishLoading(self)
    }

    private func sendError() {
        let error = NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorUnknown,
            userInfo: [NSLocalizedDescriptionKey: "Mock request failed"]
        )
        client?.urlProtocol(self, didFailWithError: error)
    }
}
