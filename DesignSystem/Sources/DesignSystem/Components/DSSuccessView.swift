import SwiftUI

/// A reusable success view component for displaying transaction success
public struct DSSuccessView: View {
    private let title: String
    private let amount: Double?
    private let recipientName: String?
    private let buttonTitle: String
    private let onDismiss: () -> Void

    /// Creates a success view
    /// - Parameters:
    ///   - title: Main success message (e.g., "Transfer Successful!")
    ///   - amount: Optional transaction amount to display
    ///   - recipientName: Optional recipient name to display
    ///   - buttonTitle: Text for the dismiss button (default: "Done")
    ///   - onDismiss: Action to perform when button is tapped
    public init(
        title: String,
        amount: Double? = nil,
        recipientName: String? = nil,
        buttonTitle: String = "Done",
        onDismiss: @escaping () -> Void
    ) {
        self.title = title
        self.amount = amount
        self.recipientName = recipientName
        self.buttonTitle = buttonTitle
        self.onDismiss = onDismiss
    }

    public var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [DSColors.gradientBlue, DSColors.gradientPurple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text(title)
                .font(.title)
                .fontWeight(.bold)

            if let amount = amount, let recipientName = recipientName {
                VStack(spacing: 8) {
                    Text("You sent")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("$\(String(format: "%.2f", amount))")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("to \(recipientName)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
            }

            Spacer()

            DSButton(
                title: buttonTitle,
                style: .primary
            ) {
                onDismiss()
            }
            .padding(.horizontal)
        }
        .padding()
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var showSuccess = true

        var body: some View {
            if showSuccess {
                DSSuccessView(
                    title: "Transfer Successful!",
                    amount: 250.50,
                    recipientName: "Alice Johnson"
                ) {
                    showSuccess = false
                }
            } else {
                Text("Dismissed")
                    .font(.title)
                    .foregroundColor(.secondary)
            }
        }
    }

    return PreviewWrapper()
}
