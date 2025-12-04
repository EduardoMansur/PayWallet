import SwiftUI

/// A reusable amount input component for monetary values
public struct DSAmountInput: View {
    @Binding private var amount: String
    private let currentBalance: Double?
    private let showValidation: Bool

    /// Creates an amount input field
    /// - Parameters:
    ///   - amount: Binding to amount text
    ///   - currentBalance: Optional current balance for validation (shows error if amount exceeds balance)
    ///   - showValidation: Whether to show validation messages (default: true)
    public init(
        amount: Binding<String>,
        currentBalance: Double? = nil,
        showValidation: Bool = true
    ) {
        self._amount = amount
        self.currentBalance = currentBalance
        self.showValidation = showValidation
    }

    public var body: some View {
        DSCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Amount")
                    .font(.headline)

                HStack {
                    Text("$")
                        .font(.title2)
                        .foregroundColor(.secondary)

                    TextField("0.00", text: $amount)
                        .keyboardType(.decimalPad)
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                if showValidation, let amountValue = Double(amount), amountValue > 0 {
                    if let balance = currentBalance, amountValue > balance {
                        Label("Insufficient balance", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var amount1 = ""
        @State private var amount2 = "1500.00"

        var body: some View {
            VStack(spacing: 20) {
                DSAmountInput(
                    amount: $amount1,
                    currentBalance: 1000.0
                )

                DSAmountInput(
                    amount: $amount2,
                    currentBalance: 1000.0
                )

                DSAmountInput(
                    amount: $amount1,
                    showValidation: false
                )
            }
            .padding()
        }
    }

    return PreviewWrapper()
}
