//
//  HomeViewSnapshotTests.swift
//  PayWallet
//
//  Created by Eduardo Torres Mansur Pereira on 04/12/25.
//

import XCTest
import SwiftUI
import SnapshotTesting
import Dependencies
@testable import PayWallet

final class HomeViewSnapshotTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Set to true to record new snapshots, false to compare against existing
        // isRecording = false
    }
    
    
    func testHomeView_iPhone13Pro_WithData() {
        let view = createHomeViewWithData()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(
            of: hostingController,
            as: .image(on: .iPhone13Pro),
            record: false
        )
    }
        
    func testHomeView_iPhone13Pro_EmptyContacts() {
        let view = createHomeViewEmptyContacts()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(
            of: hostingController,
            as: .image(on: .iPhone13Pro),
            record: false
        )
    }
    
    // MARK: - Helper Methods

    private func createHomeViewWithData() -> some View {
        withDependencies {
            $0.userProfileService = createUserProfileServiceMock()
            $0.contactsService = createContactsServiceMock()
            $0.keychainService = createKeychainServiceMock()
            $0.authenticationManager = createAuthenticationManagerMock()
        } operation: {
            let viewModel = HomeViewModel()
            // Simulate loaded state
            Task { @MainActor in
                await viewModel.loadData()
            }
            return HomeView()
        }
    }

    private func createHomeViewEmptyContacts() -> some View {
        withDependencies {
            $0.userProfileService = createUserProfileServiceMock()
            $0.contactsService = createEmptyContactsServiceMock()
            $0.keychainService = createKeychainServiceMock()
            $0.authenticationManager = createAuthenticationManagerMock()
        } operation: {
            let viewModel = HomeViewModel()
            Task { @MainActor in
                await viewModel.loadData()
            }
            return HomeView()
        }
    }

    private func createUserProfileServiceMock() -> UserProfileServiceMock {
        let mock = UserProfileServiceMock()
        mock.profileToReturn = UserProfile(
            userId: "user_123",
            name: "John Doe",
            email: "test@paywallet.com",
            balance: 1234.56
        )
        return mock
    }

    private func createContactsServiceMock() -> ContactsServiceMock {
        let mock = ContactsServiceMock()
        mock.contactsToReturn = [
            Contact(id: "1", name: "Alice Johnson", email: "alice@example.com", avatarURL: nil),
            Contact(id: "2", name: "Bob Smith", email: "bob@example.com", avatarURL: nil),
            Contact(id: "3", name: "Charlie Brown", email: "charlie@example.com", avatarURL: nil)
        ]
        return mock
    }

    private func createEmptyContactsServiceMock() -> ContactsServiceMock {
        let mock = ContactsServiceMock()
        mock.contactsToReturn = []
        return mock
    }

    private func createKeychainServiceMock() -> KeychainServiceMock {
        let mock = KeychainServiceMock()
        mock.tokenToReturn = "test_token"
        return mock
    }

    private func createAuthenticationManagerMock() -> AuthenticationManagerMock {
        let mock = AuthenticationManagerMock()
        mock.isAuthenticatedToReturn = true
        return mock
    }
    
}
