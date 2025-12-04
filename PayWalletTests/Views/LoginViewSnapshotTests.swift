//
//  LoginViewSnapshotTests.swift
//  PayWallet
//
//  Created by Eduardo Torres Mansur Pereira on 04/12/25.
//


import XCTest
import SwiftUI
import SnapshotTesting
@testable import PayWallet

final class LoginViewSnapshotTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Set to true to record new snapshots, false to compare against existing
        // isRecording = false
    }
    
    func testLoginView_iPhone13Pro_Portrait() {
        let view = LoginView()
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(
            of: hostingController,
            as: .image(on: .iPhone13Pro),
            record: false
        )
    }
}
