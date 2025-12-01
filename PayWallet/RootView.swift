import SwiftUI

struct RootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var authenticationManager: AuthenticationManager

    init(authenticationManager: AuthenticationManager = AuthenticationManager()) {
        self._authenticationManager = State(initialValue: authenticationManager)
    }

    var body: some View {
        Group {
            if authenticationManager.isAuthenticated {
                HomeView()
            } else {
                LoginView(authenticationManager: authenticationManager)
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
