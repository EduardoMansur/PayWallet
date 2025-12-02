import Foundation
import NetworkLayer

struct Contact: Codable, Identifiable {
    let id: String
    let name: String
    let email: String
    let avatarURL: String?
}

struct ContactsResponse: Codable {
    let contacts: [Contact]
}

protocol ContactsServiceProtocol {
    func getContacts(token: String) async throws -> [Contact]
}

final class ContactsService: ContactsServiceProtocol {
    private let networkClient: NetworkClient

    init(networkClient: NetworkClient = NetworkClient()) {
        self.networkClient = networkClient
    }

    func getContacts(token: String) async throws -> [Contact] {
        let request = ContactsRequest(token: token)

        do {
            let response: ContactsResponse = try await networkClient.execute(request)
            return response.contacts
        } catch let error as NetworkError {
            throw mapNetworkError(error)
        } catch {
            throw ContactsError.unknown
        }
    }

    private func mapNetworkError(_ error: NetworkError) -> ContactsError {
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

final class MockContactsService: ContactsServiceProtocol {
    private let networkClient: NetworkClient

    init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [ContactsMockURLProtocol.self]
        self.networkClient = NetworkClient(configuration: configuration)
    }

    func getContacts(token: String) async throws -> [Contact] {
        let request = ContactsRequest(token: token)

        do {
            let response: ContactsResponse = try await networkClient.execute(request)
            return response.contacts
        } catch let error as NetworkError {
            throw mapNetworkError(error)
        } catch {
            throw ContactsError.unknown
        }
    }

    private func mapNetworkError(_ error: NetworkError) -> ContactsError {
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

struct ContactsRequest: NetworkRequest {
    typealias Response = ContactsResponse

    let token: String

    var baseURL: String { "https://api.paywallet.com" }
    var path: String { "/contacts" }
    var method: HTTPMethod { .get }
    var headers: [String: String]? {
        ["Authorization": "Bearer \(token)"]
    }
}

enum ContactsError: LocalizedError {
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

final class ContactsMockURLProtocol: URLProtocol {
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

                if url.path == "/contacts" {
                    handleContactsRequest()
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

    private func handleContactsRequest() {
        let authHeader = request.value(forHTTPHeaderField: "Authorization")

        guard authHeader != nil else {
            sendUnauthorized()
            return
        }

        let contacts = ContactsResponse(contacts: [
            Contact(
                id: "1",
                name: "Alice Johnson",
                email: "alice@example.com",
                avatarURL: nil
            ),
            Contact(
                id: "2",
                name: "Bob Smith",
                email: "bob@example.com",
                avatarURL: nil
            ),
            Contact(
                id: "3",
                name: "Charlie Brown",
                email: "charlie@example.com",
                avatarURL: nil
            ),
            Contact(
                id: "4",
                name: "Diana Prince",
                email: "diana@example.com",
                avatarURL: nil
            ),
            Contact(
                id: "5",
                name: "Eve Wilson",
                email: "eve@example.com",
                avatarURL: nil
            )
        ])

        sendSuccess(response: contacts)
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
