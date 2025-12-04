import Foundation
import NetworkLayer

struct TransferRequest: Codable {
    let recipientId: String
    let amount: Double
}

struct TransferAuthorizationResponse: Codable {
    let authorized: Bool
    let message: String?
    let newBalance: Double?
}

protocol TransferServiceProtocol {
    func authorizeTransfer(recipientId: String, amount: Double, token: String) async throws -> TransferAuthorizationResponse
}

final class TransferService: TransferServiceProtocol {
    private let networkClient: NetworkClient
    private let keychainService: KeychainServiceProtocol

    init(networkClient: NetworkClient = NetworkClient(), keychainService: KeychainServiceProtocol = KeychainService.shared) {
        self.networkClient = networkClient
        self.keychainService = keychainService
    }

    func authorizeTransfer(recipientId: String, amount: Double, token: String) async throws -> TransferAuthorizationResponse {
        let transferRequest = TransferRequest(recipientId: recipientId, amount: amount)
        let request = TransferAuthorizationRequest(transferRequest: transferRequest, token: token)

        do {
            return try await networkClient.execute(request)
        } catch let error as NetworkError {
            throw mapNetworkError(error)
        } catch {
            throw TransferError.unknown
        }
    }

    private func mapNetworkError(_ error: NetworkError) -> TransferError {
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

final class MockTransferService: TransferServiceProtocol {
    private let networkClient: NetworkClient
    private let keychainService: KeychainServiceProtocol

    init(keychainService: KeychainServiceProtocol = KeychainService.shared) {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [TransferMockURLProtocol.self]
        self.networkClient = NetworkClient(configuration: configuration)
        self.keychainService = keychainService
    }

    func authorizeTransfer(recipientId: String, amount: Double, token: String) async throws -> TransferAuthorizationResponse {
        let transferRequest = TransferRequest(recipientId: recipientId, amount: amount)
        let request = TransferAuthorizationRequest(transferRequest: transferRequest, token: token)

        do {
            return try await networkClient.execute(request)
        } catch let error as NetworkError {
            throw mapNetworkError(error)
        } catch {
            throw TransferError.unknown
        }
    }

    private func mapNetworkError(_ error: NetworkError) -> TransferError {
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

struct TransferAuthorizationRequest: NetworkRequest {
    typealias Response = TransferAuthorizationResponse

    let transferRequest: TransferRequest
    let token: String

    var baseURL: String { "https://api.paywallet.com" }
    var path: String { "/transfer/authorize" }
    var method: HTTPMethod { .post }
    var headers: [String: String]? {
        ["Authorization": "Bearer \(token)"]
    }
    var encodableBody: Encodable? { transferRequest }
}

enum TransferError: LocalizedError {
    case unauthorized
    case networkError
    case unknown
    case insufficientBalance
    case invalidAmount
    case cannotTransferToSelf

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Transfer not authorized. Please try again."
        case .networkError:
            return "Network error occurred. Please check your connection."
        case .unknown:
            return "An unknown error occurred."
        case .insufficientBalance:
            return "Insufficient balance to complete this transfer."
        case .invalidAmount:
            return "Please enter a valid amount greater than 0."
        case .cannotTransferToSelf:
            return "You cannot transfer money to yourself."
        }
    }
}

final class TransferMockURLProtocol: URLProtocol {
    private static let requestBodyKey = "TransferMockURLProtocol.requestBody"
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
                try await Task.sleep(nanoseconds: 800_000_000)

                guard let url = request.url else {
                    sendError()
                    return
                }

                if url.path == "/transfer/authorize" {
                    handleTransferAuthorizationRequest()
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

    private func handleTransferAuthorizationRequest() {
        let authHeader = request.value(forHTTPHeaderField: "Authorization")

        guard authHeader != nil else {
            sendUnauthorized()
            return
        }

        // Try to get body from stored property, fallback to httpBody
        let bodyData = URLProtocol.property(forKey: Self.requestBodyKey, in: request) as? Data
            ?? request.httpBody

        guard let bodyData = bodyData,
              let transferRequest = try? JSONDecoder().decode(TransferRequest.self, from: bodyData) else {
            sendError()
            return
        }

        // Handle the transfer asynchronously to use the actor
        Task {
            // Simulate authorization failure for amount equal to 403
            if transferRequest.amount == 403 {
                let response = TransferAuthorizationResponse(
                    authorized: false,
                    message: "Transaction declined. This amount cannot be processed at this time.",
                    newBalance: nil
                )
                await MainActor.run {
                    sendSuccess(response: response)
                }
            } else {
                // Deduct the amount from the shared balance
                let newBalance = await MockBalanceManager.shared.deductAmount(transferRequest.amount)

                let response = TransferAuthorizationResponse(
                    authorized: true,
                    message: "Transfer authorized successfully",
                    newBalance: newBalance
                )
                await MainActor.run {
                    sendSuccess(response: response)
                }
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
