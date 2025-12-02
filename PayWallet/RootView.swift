import SwiftUI
import Dependencies

struct RootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var authenticationManager: AuthenticationManager

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
}

#Preview {
    RootView()
}
