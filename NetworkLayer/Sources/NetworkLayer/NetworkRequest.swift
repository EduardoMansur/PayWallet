import Foundation

/// Protocol defining the structure of a network request
public protocol NetworkRequest {
    associatedtype Response: Decodable

    /// The base URL for the request
    var baseURL: String { get }

    /// The path component of the URL
    var path: String { get }

    /// HTTP method for the request
    var method: HTTPMethod { get }

    /// Headers for the request
    var headers: [String: String]? { get }

    /// Query parameters for the request
    var queryParameters: [String: String]? { get }

    /// Body parameters for the request (will be JSON encoded)
    var bodyParameters: [String: Any]? { get }

    /// Encodable body for the request (alternative to bodyParameters)
    var encodableBody: Encodable? { get }

    /// Timeout interval for the request
    var timeoutInterval: TimeInterval { get }

    /// Cache policy for the request
    var cachePolicy: URLRequest.CachePolicy { get }
}

/// Default implementations for optional properties
public extension NetworkRequest {
    var headers: [String: String]? { nil }
    var queryParameters: [String: String]? { nil }
    var bodyParameters: [String: Any]? { nil }
    var encodableBody: Encodable? { nil }
    var timeoutInterval: TimeInterval { 30.0 }
    var cachePolicy: URLRequest.CachePolicy { .useProtocolCachePolicy }

    /// Builds a URLRequest from the NetworkRequest configuration
    func buildURLRequest() throws -> URLRequest {
        var urlComponents = URLComponents(string: baseURL + path)

        // Add query parameters
        if let queryParameters = queryParameters, !queryParameters.isEmpty {
            urlComponents?.queryItems = queryParameters.map { key, value in
                URLQueryItem(name: key, value: value)
            }
        }

        guard let url = urlComponents?.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.timeoutInterval = timeoutInterval
        request.cachePolicy = cachePolicy

        // Add headers
        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        // Add body if present
        if let encodableBody = encodableBody {
            do {
                request.httpBody = try JSONEncoder().encode(encodableBody)
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            } catch {
                throw NetworkError.encodingError(error)
            }
        } else if let bodyParameters = bodyParameters {
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: bodyParameters)
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            } catch {
                throw NetworkError.encodingError(error)
            }
        }

        return request
    }
}
