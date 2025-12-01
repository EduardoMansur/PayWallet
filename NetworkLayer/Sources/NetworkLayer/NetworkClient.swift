import Foundation

/// Main network client for executing network requests
public actor NetworkClient {
    private let session: URLSession
    private let jsonDecoder: JSONDecoder

    /// Initialize a new NetworkClient
    /// - Parameters:
    ///   - configuration: URLSessionConfiguration (defaults to .default)
    ///   - jsonDecoder: JSONDecoder for response decoding (defaults to JSONDecoder())
    public init(
        configuration: URLSessionConfiguration = .default,
        jsonDecoder: JSONDecoder = JSONDecoder()
    ) {
        self.session = URLSession(configuration: configuration)
        self.jsonDecoder = jsonDecoder
    }

    /// Execute a network request and decode the response
    /// - Parameter request: The network request to execute
    /// - Returns: The decoded response
    /// - Throws: NetworkError if the request fails
    public func execute<T: NetworkRequest>(_ request: T) async throws -> T.Response {
        let urlRequest = try request.buildURLRequest()

        let (data, response) = try await performRequest(urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(statusCode: httpResponse.statusCode, data: data)
        }

        do {
            return try jsonDecoder.decode(T.Response.self, from: data)
        } catch {
            throw NetworkError.decodingError(error)
        }
    }

    /// Execute a network request without expecting a decoded response
    /// - Parameter request: The network request to execute
    /// - Returns: The raw data and HTTP response
    /// - Throws: NetworkError if the request fails
    public func executeRaw<T: NetworkRequest>(_ request: T) async throws -> (Data, HTTPURLResponse) {
        let urlRequest = try request.buildURLRequest()

        let (data, response) = try await performRequest(urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(statusCode: httpResponse.statusCode, data: data)
        }

        return (data, httpResponse)
    }

    /// Execute a network request and return only the status code
    /// - Parameter request: The network request to execute
    /// - Returns: The HTTP status code
    /// - Throws: NetworkError if the request fails
    public func executeStatusCode<T: NetworkRequest>(_ request: T) async throws -> Int {
        let urlRequest = try request.buildURLRequest()

        let (_, response) = try await performRequest(urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        return httpResponse.statusCode
    }

    /// Download data from a URL
    /// - Parameter url: The URL to download from
    /// - Returns: The local file URL and HTTP response
    /// - Throws: NetworkError if the download fails
    public func download(from url: URL) async throws -> (URL, HTTPURLResponse) {
        do {
            let (localURL, response) = try await session.download(from: url)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw NetworkError.httpError(statusCode: httpResponse.statusCode, data: nil)
            }

            return (localURL, httpResponse)
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.networkFailure(error)
        }
    }

    /// Upload data to a URL
    /// - Parameters:
    ///   - request: The URLRequest to upload to
    ///   - data: The data to upload
    /// - Returns: The response data and HTTP response
    /// - Throws: NetworkError if the upload fails
    public func upload(_ request: URLRequest, data: Data) async throws -> (Data, HTTPURLResponse) {
        do {
            let (responseData, response) = try await session.upload(for: request, from: data)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw NetworkError.httpError(statusCode: httpResponse.statusCode, data: responseData)
            }

            return (responseData, httpResponse)
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.networkFailure(error)
        }
    }

    // MARK: - Private Methods

    private func performRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch let urlError as URLError {
            switch urlError.code {
            case .cancelled:
                throw NetworkError.cancelled
            case .timedOut:
                throw NetworkError.timeout
            default:
                throw NetworkError.networkFailure(urlError)
            }
        } catch {
            throw NetworkError.networkFailure(error)
        }
    }
}
