import Foundation
import NetworkLayer

struct UserProfile: Codable {
    let userId: String
    let name: String
    let balance: Double
}

protocol UserProfileServiceProtocol {
    func getUserProfile(token: String) async throws -> UserProfile
}

final class UserProfileService: UserProfileServiceProtocol {
    private let networkClient: NetworkClient

    init(networkClient: NetworkClient = NetworkClient()) {
        self.networkClient = networkClient
    }

    func getUserProfile(token: String) async throws -> UserProfile {
        let request = UserProfileRequest(token: token)

        do {
            return try await networkClient.execute(request)
        } catch let error as NetworkError {
            throw mapNetworkError(error)
        } catch {
            throw UserProfileError.unknown
        }
    }

    private func mapNetworkError(_ error: NetworkError) -> UserProfileError {
        switch error {
        case .httpError(let statusCode, _):
            if statusCode == 401 || statusCode == 403 {
                return .unauthorized
            }
            return .networkError
        case .networkFailure, .timeout:
            return .networkError
        default:
            return .unknown
        }
    }
}

final class MockUserProfileService: UserProfileServiceProtocol {
    private let networkClient: NetworkClient

    init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [UserProfileMockURLProtocol.self]
        self.networkClient = NetworkClient(configuration: configuration)
    }

    func getUserProfile(token: String) async throws -> UserProfile {
        let request = UserProfileRequest(token: token)

        do {
            return try await networkClient.execute(request)
        } catch let error as NetworkError {
            throw mapNetworkError(error)
        } catch {
            throw UserProfileError.unknown
        }
    }

    private func mapNetworkError(_ error: NetworkError) -> UserProfileError {
        switch error {
        case .httpError(let statusCode, _):
            if statusCode == 401 || statusCode == 403 {
                return .unauthorized
            }
            return .networkError
        case .networkFailure, .timeout:
            return .networkError
        default:
            return .unknown
        }
    }
}

struct UserProfileRequest: NetworkRequest {
    typealias Response = UserProfile

    let token: String

    var baseURL: String { "https://api.paywallet.com" }
    var path: String { "/user/profile" }
    var method: HTTPMethod { .get }
    var headers: [String: String]? {
        ["Authorization": "Bearer \(token)"]
    }
}

enum UserProfileError: LocalizedError {
    case unauthorized
    case networkError
    case unknown

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Unauthorized. Please log in again."
        case .networkError:
            return "Network error occurred. Please try again."
        case .unknown:
            return "An unknown error occurred."
        }
    }
}

final class UserProfileMockURLProtocol: URLProtocol {
    private var activeTask: Task<Void, Never>?

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canInit(with task: URLSessionTask) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        activeTask = Task { @MainActor in
            do {
                try await Task.sleep(nanoseconds: 500_000_000)

                guard let url = request.url else {
                    sendError()
                    return
                }

                if url.path == "/user/profile" {
                    handleUserProfileRequest()
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

    private func handleUserProfileRequest() {
        let authHeader = request.value(forHTTPHeaderField: "Authorization")

        guard authHeader != nil else {
            sendUnauthorized()
            return
        }

        // Get current balance from shared manager
        Task {
            let currentBalance = await MockBalanceManager.shared.getBalance()

            let profile = UserProfile(
                userId: "user_123",
                name: "John Doe",
                balance: currentBalance
            )

            await MainActor.run {
                sendSuccess(response: profile)
            }
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

        let errorBody = "{\"error\": \"Unauthorized\"}".data(using: .utf8) ?? Data()

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
