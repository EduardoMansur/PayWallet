import SwiftUI
import Dependencies

struct RootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var authenticationManager: AuthenticationManager
    @State private var hasRequestedNotificationPermission = false

    init() {
        @Dependency(\.authenticationManager) var manager
        self._authenticationManager = State(initialValue: manager as! AuthenticationManager)
    }

    var body: some View {
        Group {
            if authenticationManager.isAuthenticated {
                HomeView()
            } else {
                LoginView()
            }
        }
        .task {
            await authenticationManager.checkAuthStatus()
            if !hasRequestedNotificationPermission {
                await requestNotificationPermission()
                hasRequestedNotificationPermission = true
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                Task {
                    await handleAppBecameActive()
                }
            }
        }
    }

    private func handleAppBecameActive() async {
        await authenticationManager.checkAuthStatus()
    }

    private func requestNotificationPermission() async {
        @Dependency(\.notificationManager) var notificationManager
        _ = await notificationManager.requestAuthorization()
    }
}

#Preview {
    RootView()
}
