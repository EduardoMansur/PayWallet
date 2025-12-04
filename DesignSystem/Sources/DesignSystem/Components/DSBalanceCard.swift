import SwiftUI

/// A reusable balance card component displaying user info and balance
public struct DSBalanceCard: View {
    private let userName: String
    private let userEmail: String
    private let balance: Double

    /// Creates a balance card
    /// - Parameters:
    ///   - userName: User's display name
    ///   - userEmail: User's email address
    ///   - balance: User's current balance
    public init(
        userName: String,
        userEmail: String,
        balance: Double
    ) {
        self.userName = userName
        self.userEmail = userEmail
        self.balance = balance
    }

    public var body: some View {
        DSCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Welcome back,")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 4) {
                    Text(userName)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(userEmail)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()
                    .padding(.vertical, 4)

                HStack {
                    Text("Balance")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("$\(balance, specifier: "%.2f")")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
            }
        }
    }
}

#Preview {
    DSBalanceCard(
        userName: "John Doe",
        userEmail: "test@paywallet.com",
        balance: 1234.56
    )
    .padding()
}
