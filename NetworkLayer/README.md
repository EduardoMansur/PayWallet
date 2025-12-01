# NetworkLayer

A modern, type-safe Swift networking layer built on top of URLSession with full Swift concurrency support.

## Features

- Built with Swift Concurrency (async/await)
- Type-safe request/response handling
- Protocol-oriented design
- Comprehensive error handling
- Support for all HTTP methods
- Query parameters and body encoding
- File upload/download capabilities
- Actor-based NetworkClient for thread-safety

## Requirements

- iOS 15.0+ / macOS 12.0+ / tvOS 15.0+ / watchOS 8.0+
- Swift 5.9+
- Xcode 15.0+

## Installation

### Local Package

Add this package to your Xcode project:

1. In Xcode, select File > Add Package Dependencies
2. Select "Add Local..."
3. Navigate to the NetworkLayer folder
4. Click "Add Package"

Or add it to your `Package.swift`:

```swift
dependencies: [
    .package(path: "../NetworkLayer")
]
```

## Usage

### Basic Example

```swift
import NetworkLayer

// Define your response model
struct User: Codable {
    let id: Int
    let name: String
    let email: String
}

// Create a request
struct GetUserRequest: NetworkRequest {
    typealias Response = User

    let userId: Int

    var baseURL: String { "https://api.example.com" }
    var path: String { "/users/\(userId)" }
    var method: HTTPMethod { .get }
}

// Execute the request
let client = NetworkClient()
let request = GetUserRequest(userId: 1)

Task {
    do {
        let user = try await client.execute(request)
        print("User: \(user.name)")
    } catch {
        print("Error: \(error)")
    }
}
```

### POST Request with Body

```swift
struct CreateUserRequest: NetworkRequest {
    typealias Response = User

    let name: String
    let email: String

    var baseURL: String { "https://api.example.com" }
    var path: String { "/users" }
    var method: HTTPMethod { .post }

    var bodyParameters: [String: Any]? {
        [
            "name": name,
            "email": email
        ]
    }
}

// Usage
let createRequest = CreateUserRequest(name: "John Doe", email: "john@example.com")
let newUser = try await client.execute(createRequest)
```

### Request with Encodable Body

```swift
struct LoginRequest: NetworkRequest {
    typealias Response = AuthResponse

    struct Credentials: Encodable {
        let username: String
        let password: String
    }

    let credentials: Credentials

    var baseURL: String { "https://api.example.com" }
    var path: String { "/auth/login" }
    var method: HTTPMethod { .post }

    var encodableBody: Encodable? { credentials }
}

// Usage
let credentials = LoginRequest.Credentials(username: "user", password: "pass")
let loginRequest = LoginRequest(credentials: credentials)
let authResponse = try await client.execute(loginRequest)
```

### Request with Headers and Query Parameters

```swift
struct SearchRequest: NetworkRequest {
    typealias Response = SearchResults

    let query: String
    let token: String

    var baseURL: String { "https://api.example.com" }
    var path: String { "/search" }
    var method: HTTPMethod { .get }

    var headers: [String: String]? {
        ["Authorization": "Bearer \(token)"]
    }

    var queryParameters: [String: String]? {
        ["q": query, "limit": "10"]
    }
}

// Usage
let searchRequest = SearchRequest(query: "Swift", token: "your-token")
let results = try await client.execute(searchRequest)
```

### Raw Response Handling

```swift
// Get raw data and response
let (data, response) = try await client.executeRaw(request)
print("Status code: \(response.statusCode)")

// Get only status code
let statusCode = try await client.executeStatusCode(request)
print("Status: \(statusCode)")
```

### File Download

```swift
let url = URL(string: "https://example.com/file.pdf")!
let (localURL, response) = try await client.download(from: url)
print("Downloaded to: \(localURL)")
```

### File Upload

```swift
var request = URLRequest(url: URL(string: "https://api.example.com/upload")!)
request.httpMethod = "POST"

let data = try Data(contentsOf: fileURL)
let (responseData, response) = try await client.upload(request, data: data)
```

### Custom Configuration

```swift
let configuration = URLSessionConfiguration.default
configuration.timeoutIntervalForRequest = 60
configuration.timeoutIntervalForResource = 300
configuration.waitsForConnectivity = true

let decoder = JSONDecoder()
decoder.keyDecodingStrategy = .convertFromSnakeCase
decoder.dateDecodingStrategy = .iso8601

let client = NetworkClient(
    configuration: configuration,
    jsonDecoder: decoder
)
```

### Error Handling

```swift
do {
    let user = try await client.execute(request)
    print("Success: \(user)")
} catch NetworkError.httpError(let statusCode, let data) {
    print("HTTP Error \(statusCode)")
    if let data = data, let message = String(data: data, encoding: .utf8) {
        print("Error message: \(message)")
    }
} catch NetworkError.decodingError(let error) {
    print("Failed to decode: \(error)")
} catch NetworkError.timeout {
    print("Request timed out")
} catch {
    print("Unknown error: \(error)")
}
```

## Architecture

### Components

- **HTTPMethod**: Enum representing HTTP methods (GET, POST, PUT, etc.)
- **NetworkError**: Comprehensive error types for network operations
- **NetworkRequest**: Protocol defining request structure with default implementations
- **NetworkClient**: Actor-based client for executing requests with URLSession

### Thread Safety

`NetworkClient` is implemented as an `actor`, ensuring thread-safe access to the URLSession and preventing data races in concurrent environments.

## Testing

Run tests using:

```bash
swift test
```

Or in Xcode: `Cmd+U`

## License

This is a local package for the PayWallet project.
