import Foundation
import Security

enum KeychainError: Error {
    case duplicateItem
    case itemNotFound
    case invalidItemFormat
    case unexpectedStatus(OSStatus)
}

protocol KeychainServiceProtocol {
    func save(key: String, value: String) async throws
    func retrieve(key: String) async throws -> String
    func delete(key: String) async throws
    func saveAuthToken(_ token: String) async throws
    func getAuthToken() async throws -> String
    func deleteAuthToken() async throws
    func hasAuthToken() async -> Bool
}

actor KeychainService: KeychainServiceProtocol {
    static let shared = KeychainService()

    private init() {}

    private let service = Bundle.main.bundleIdentifier ?? "com.paywallet.app"

    func save(key: String, value: String) async throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.invalidItemFormat
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        if status == errSecDuplicateItem {
            try await update(key: key, value: value)
        } else if status != errSecSuccess {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    func retrieve(key: String) async throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            throw status == errSecItemNotFound ? KeychainError.itemNotFound : KeychainError.unexpectedStatus(status)
        }

        guard let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidItemFormat
        }

        return value
    }

    func delete(key: String) async throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    private func update(key: String, value: String) async throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.invalidItemFormat
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
}

extension KeychainService {
    private static let tokenKey = "authToken"

    func saveAuthToken(_ token: String) async throws {
        try await save(key: Self.tokenKey, value: token)
    }

    func getAuthToken() async throws -> String {
        try await retrieve(key: Self.tokenKey)
    }

    func deleteAuthToken() async throws {
        try await delete(key: Self.tokenKey)
    }

    func hasAuthToken() async -> Bool {
        do {
            _ = try await retrieve(key: Self.tokenKey)
            return true
        } catch {
            return false
        }
    }
}
