import SwiftUI
import DesignSystem

struct LoginView: View {
    @State private var viewModel: LoginViewModelProtocol

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    DSColors.gradientBlue.opacity(0.6),
                    DSColors.gradientPurple.opacity(0.6)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 24) {
                    DSAuthHeader(
                        iconName: "wallet.pass.fill",
                        title: "PayWallet",
                        subtitle: "Secure Payment Solutions"
                    )

                    DSLoginForm(
                        email: $viewModel.email,
                        password: $viewModel.password,
                        isLoading: viewModel.isLoading
                    ) {
                        Task {
                            await viewModel.login()
                        }
                    }

                    hintView
                }
                Spacer()
            }
        }
        .dsAlert(
            isPresented: $viewModel.showError,
            title: "Login Failed",
            message: viewModel.errorMessage ?? "Unknown error"
        )
    }

    init() {
        self._viewModel = State(initialValue: LoginViewModel())
    }

    private var hintView: some View {
        VStack(spacing: 8) {
            Text("Demo Credentials")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(DSColors.textOnGradient.opacity(0.9))

            Text("Email: test@paywallet.com")
                .font(.caption2)
                .foregroundColor(DSColors.textOnGradient.opacity(0.8))

            Text("Password: password123")
                .font(.caption2)
                .foregroundColor(DSColors.textOnGradient.opacity(0.8))
        }
        .padding()
        .background(DSColors.textOnGradient.opacity(0.2))
        .cornerRadius(12)
        .padding(.horizontal, 24)
    }
}

#Preview {
    LoginView()
}
