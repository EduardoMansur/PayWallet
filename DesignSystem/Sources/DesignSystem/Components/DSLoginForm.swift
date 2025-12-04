import SwiftUI

/// A reusable login form component with email, password fields and a login button
public struct DSLoginForm: View {
    @Binding private var email: String
    @Binding private var password: String
    private let isLoading: Bool
    private let onLogin: () -> Void

    /// Creates a login form
    /// - Parameters:
    ///   - email: Binding to email text
    ///   - password: Binding to password text
    ///   - isLoading: Whether the login action is in progress
    ///   - onLogin: Action to perform when login button is tapped
    public init(
        email: Binding<String>,
        password: Binding<String>,
        isLoading: Bool,
        onLogin: @escaping () -> Void
    ) {
        self._email = email
        self._password = password
        self.isLoading = isLoading
        self.onLogin = onLogin
    }

    public var body: some View {
        DSCard {
            VStack(spacing: 20) {
                DSTextField(
                    title: "Email",
                    placeholder: "Enter your email",
                    text: $email
                )
                .keyboardType(.emailAddress)

                DSTextField(
                    title: "Password",
                    placeholder: "Enter your password",
                    text: $password,
                    isSecure: true
                )

                DSButton(
                    title: "Login",
                    style: .primary,
                    isLoading: isLoading
                ) {
                    onLogin()
                }
                .padding(.top, 8)
            }
            .padding(.vertical, 8)
        }
        .padding(.horizontal, 24)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var email = ""
        @State private var password = ""
        @State private var isLoading = false

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

                DSLoginForm(
                    email: $email,
                    password: $password,
                    isLoading: isLoading
                ) {
                    isLoading = true
                    Task {
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                        isLoading = false
                    }
                }
            }
        }
    }

    return PreviewWrapper()
}
