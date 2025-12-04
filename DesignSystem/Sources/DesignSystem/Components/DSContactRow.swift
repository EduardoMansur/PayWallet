import SwiftUI

/// A reusable contact row component displaying contact information
public struct DSContactRow: View {
    private let name: String
    private let email: String
    private let showChevron: Bool

    /// Creates a contact row
    /// - Parameters:
    ///   - name: Contact's name
    ///   - email: Contact's email address
    ///   - showChevron: Whether to show chevron icon (default: true)
    public init(
        name: String,
        email: String,
        showChevron: Bool = true
    ) {
        self.name = name
        self.email = email
        self.showChevron = showChevron
    }

    public var body: some View {
        DSCard {
            HStack(spacing: 12) {
                Circle()
                    .fill(LinearGradient(
                        colors: [DSColors.gradientBlue, DSColors.gradientPurple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(name.prefix(1))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(DSColors.textOnGradient)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.body)
                        .fontWeight(.semibold)

                    Text(email)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        DSContactRow(
            name: "Alice Johnson",
            email: "alice@example.com"
        )

        DSContactRow(
            name: "Bob Smith",
            email: "bob@example.com",
            showChevron: false
        )
    }
    .padding()
}
