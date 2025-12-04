//
//  TransferViewSnapshotTests.swift
//  PayWallet
//
//  Created by Eduardo Torres Mansur Pereira on 04/12/25.
//


import XCTest
import SwiftUI
import SnapshotTesting
import Dependencies
@testable import PayWallet

final class TransferViewSnapshotTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Set to true to record new snapshots, false to compare against existing
        // isRecording = false
    }
    
    // MARK: - Test Data
    
    private let testContacts = [
        Contact(id: "1", name: "Alice Johnson", email: "alice@example.com", avatarURL: nil),
        Contact(id: "2", name: "Bob Smith", email: "bob@example.com", avatarURL: nil),
        Contact(id: "3", name: "Charlie Brown", email: "charlie@example.com", avatarURL: nil)
    ]
    
    private let testBalance: Double = 1234.56
    private let testUserId = "user_123"
    
    // MARK: - iPhone 16 Pro Tests
    
    func testTransferView_iPhone13Pro_InitialState() {
        let view = createTransferView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(
            of: hostingController,
            as: .image(on: .iPhone13Pro),
            record: false
        )
    }
    
    func testTransferView_iPhone13Pro_WithSelectedContact() {
        let view = createTransferViewWithSelectedContact()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(
            of: hostingController,
            as: .image(on: .iPhone13Pro),
            record: false
        )
    }
    
    func testTransferView_iPhone13Pro_WithoutSelectedContact() {
        let view = createTransferViewWithoutContact()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(
            of: hostingController,
            as: .image(on: .iPhone13Pro),
            record: false
        )
    }

    // MARK: - Helper Methods

    private func createTransferView() -> some View {
        withDependencies {
            $0.transferService = TransferServiceMock()
            $0.keychainService = createKeychainServiceMock()
            $0.notificationManager = NotificationManagerMock()
        } operation: {
            TransferView(
                contacts: testContacts,
                currentBalance: testBalance,
                currentUserId: testUserId
            )
        }
    }

    private func createTransferViewWithSelectedContact() -> some View {
        withDependencies {
            $0.transferService = TransferServiceMock()
            $0.keychainService = createKeychainServiceMock()
            $0.notificationManager = NotificationManagerMock()
        } operation: {
            TransferView(
                contacts: testContacts,
                currentBalance: testBalance,
                currentUserId: testUserId,
                preselectedContact: testContacts[0]
            )
        }
    }

    private func createTransferViewWithoutContact() -> some View {
        withDependencies {
            $0.transferService = TransferServiceMock()
            $0.keychainService = createKeychainServiceMock()
            $0.notificationManager = NotificationManagerMock()
        } operation: {
            let view = TransferView(
                contacts: testContacts,
                currentBalance: testBalance,
                currentUserId: testUserId
            )
            return view
        }
    }

    private func createTransferViewInsufficientBalance() -> some View {
        withDependencies {
            $0.transferService = TransferServiceMock()
            $0.keychainService = createKeychainServiceMock()
            $0.notificationManager = NotificationManagerMock()
        } operation: {
            TransferView(
                contacts: testContacts,
                currentBalance: 50.0, // Low balance
                currentUserId: testUserId,
                preselectedContact: testContacts[0]
            )
        }
    }

    private func createTransferViewSuccess() -> some View {
        withDependencies {
            $0.transferService = createSuccessfulTransferServiceMock()
            $0.keychainService = createKeychainServiceMock()
            $0.notificationManager = NotificationManagerMock()
        } operation: {
            let view = TransferView(
                contacts: testContacts,
                currentBalance: testBalance,
                currentUserId: testUserId,
                preselectedContact: testContacts[0]
            )
            // Note: To capture the success state, you would need to trigger the transfer
            // This is a simplified version
            return view
        }
    }

    private func createKeychainServiceMock() -> KeychainServiceMock {
        let mock = KeychainServiceMock()
        mock.tokenToReturn = "test_token"
        return mock
    }

    private func createSuccessfulTransferServiceMock() -> TransferServiceMock {
        let mock = TransferServiceMock()
        mock.responseToReturn = TransferAuthorizationResponse(
            authorized: true,
            message: "Transfer successful",
            newBalance: testBalance - 100.0
        )
        return mock
    }

}
