import Foundation

/// Errors that can occur during network operations
public enum NetworkError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, data: Data?)
    case decodingError(Error)
    case encodingError(Error)
    case noData
    case networkFailure(Error)
    case cancelled
    case timeout
    case unknown

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The URL provided was invalid."
        case .invalidResponse:
            return "The server response was invalid."
        case .httpError(let statusCode, _):
            return "HTTP error occurred with status code: \(statusCode)."
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Failed to encode request: \(error.localizedDescription)"
        case .noData:
            return "No data was returned from the server."
        case .networkFailure(let error):
            return "Network request failed: \(error.localizedDescription)"
        case .cancelled:
            return "The request was cancelled."
        case .timeout:
            return "The request timed out."
        case .unknown:
            return "An unknown error occurred."
        }
    }
}
