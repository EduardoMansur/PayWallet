import Dependencies
import Foundation

// MARK: - KeychainService Dependency
extension DependencyValues {
    var keychainService: KeychainServiceProtocol {
        get { self[KeychainServiceKey.self] }
        set { self[KeychainServiceKey.self] = newValue }
    }
}

private enum KeychainServiceKey: DependencyKey {
    static let liveValue: KeychainServiceProtocol = KeychainService.shared
    static let testValue: KeychainServiceProtocol = KeychainService.shared
}

// MARK: - AuthenticationManager Dependency
extension DependencyValues {
    var authenticationManager: AuthenticationManagerProtocol {
        get { self[AuthenticationManagerKey.self] }
        set { self[AuthenticationManagerKey.self] = newValue }
    }
}

private enum AuthenticationManagerKey: DependencyKey {
    static let liveValue: AuthenticationManagerProtocol = AuthenticationManager()
    static let testValue: AuthenticationManagerProtocol = AuthenticationManager()
}

// MARK: - AuthService Dependency
extension DependencyValues {
    var authService: AuthServiceProtocol {
        get { self[AuthServiceKey.self] }
        set { self[AuthServiceKey.self] = newValue }
    }
}

private enum AuthServiceKey: DependencyKey {
    static let liveValue: AuthServiceProtocol = MockAuthService()
    static let testValue: AuthServiceProtocol = MockAuthService()
}

// MARK: - UserProfileService Dependency
extension DependencyValues {
    var userProfileService: UserProfileServiceProtocol {
        get { self[UserProfileServiceKey.self] }
        set { self[UserProfileServiceKey.self] = newValue }
    }
}

private enum UserProfileServiceKey: DependencyKey {
    static let liveValue: UserProfileServiceProtocol = MockUserProfileService()
    static let testValue: UserProfileServiceProtocol = MockUserProfileService()
}

// MARK: - ContactsService Dependency
extension DependencyValues {
    var contactsService: ContactsServiceProtocol {
        get { self[ContactsServiceKey.self] }
        set { self[ContactsServiceKey.self] = newValue }
    }
}

private enum ContactsServiceKey: DependencyKey {
    static let liveValue: ContactsServiceProtocol = MockContactsService()
    static let testValue: ContactsServiceProtocol = MockContactsService()
}

// MARK: - TransferService Dependency
extension DependencyValues {
    var transferService: TransferServiceProtocol {
        get { self[TransferServiceKey.self] }
        set { self[TransferServiceKey.self] = newValue }
    }
}

private enum TransferServiceKey: DependencyKey {
    static let liveValue: TransferServiceProtocol = MockTransferService()
    static let testValue: TransferServiceProtocol = MockTransferService()
}

// MARK: - NotificationManager Dependency
extension DependencyValues {
    var notificationManager: NotificationManagerProtocol {
        get { self[NotificationManagerKey.self] }
        set { self[NotificationManagerKey.self] = newValue }
    }
}

private enum NotificationManagerKey: DependencyKey {
    static let liveValue: NotificationManagerProtocol = NotificationManager()
    static let testValue: NotificationManagerProtocol = MockNotificationManager()
}
