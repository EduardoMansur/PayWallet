import SwiftUI
import DesignSystem

struct LoginView: View {
    enum Layout {
        static let iconName = "wallet.pass.fill"
        static let appTitle = "PayWallet"
        static let appSubtitle = "Secure Payment Solutions"
        static let alertTitle = "Login Failed"
        static let alertDefaultMessage = "Unknown error"
        static let demoCredentialsTitle = "Demo Credentials"
        static let demoEmail = "Email: test@paywallet.com"
        static let demoPassword = "Password: password123"

        static let gradientOpacity = 0.6
        static let outerSpacing: CGFloat = 0
        static let innerSpacing: CGFloat = 24
        static let hintSpacing: CGFloat = 8
        static let hintTitleOpacity = 0.9
        static let hintTextOpacity = 0.8
        static let hintBackgroundOpacity = 0.2
        static let hintCornerRadius: CGFloat = 12
        static let hintHorizontalPadding: CGFloat = 24
    }

    @State private var viewModel: LoginViewModelProtocol

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    DSColors.gradientBlue.opacity(Layout.gradientOpacity),
                    DSColors.gradientPurple.opacity(Layout.gradientOpacity)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: Layout.outerSpacing) {
                Spacer()

                VStack(spacing: Layout.innerSpacing) {
                    DSAuthHeader(
                        iconName: Layout.iconName,
                        title: Layout.appTitle,
                        subtitle: Layout.appSubtitle
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
            title: Layout.alertTitle,
            message: viewModel.errorMessage ?? Layout.alertDefaultMessage
        )
    }

    init() {
        self._viewModel = State(initialValue: LoginViewModel())
    }

    private var hintView: some View {
        VStack(spacing: Layout.hintSpacing) {
            Text(Layout.demoCredentialsTitle)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(DSColors.textOnGradient.opacity(Layout.hintTitleOpacity))

            Text(Layout.demoEmail)
                .font(.caption2)
                .foregroundColor(DSColors.textOnGradient.opacity(Layout.hintTextOpacity))

            Text(Layout.demoPassword)
                .font(.caption2)
                .foregroundColor(DSColors.textOnGradient.opacity(Layout.hintTextOpacity))
        }
        .padding()
        .background(DSColors.textOnGradient.opacity(Layout.hintBackgroundOpacity))
        .cornerRadius(Layout.hintCornerRadius)
        .padding(.horizontal, Layout.hintHorizontalPadding)
    }
}

#Preview {
    LoginView()
}
