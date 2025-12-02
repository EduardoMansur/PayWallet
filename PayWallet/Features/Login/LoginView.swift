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
                    headerView

                    DSCard {
                        VStack(spacing: 20) {
                            DSTextField(
                                title: "Email",
                                placeholder: "Enter your email",
                                text: $viewModel.email
                            )
                            .keyboardType(.emailAddress)

                            DSTextField(
                                title: "Password",
                                placeholder: "Enter your password",
                                text: $viewModel.password,
                                isSecure: true
                            )

                            DSButton(
                                title: "Login",
                                style: .primary,
                                isLoading: viewModel.isLoading
                            ) {
                                Task {
                                    await viewModel.login()
                                }
                            }
                            .padding(.top, 8)
                        }
                        .padding(.vertical, 8)
                    }
                    .padding(.horizontal, 24)

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

    private var headerView: some View {
        VStack(spacing: 12) {
            Image(systemName: "wallet.pass.fill")
                .font(.system(size: 70))
                .foregroundColor(DSColors.textOnGradient)

            Text("PayWallet")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(DSColors.textOnGradient)

            Text("Secure Payment Solutions")
                .font(.subheadline)
                .foregroundColor(DSColors.textOnGradient.opacity(0.9))
        }
        .padding(.bottom, 32)
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
