import SwiftUI
import DesignSystem

struct TransferView: View {
    enum Layout {
        static let navigationTitle = "Send Money"
        static let confirmAlertTitle = "Confirm Transfer"
        static let cancelButton = "Cancel"
        static let confirmButton = "Confirm"
        static let errorAlertTitle = "Error"
        static let errorAlertButton = "OK"
        static let availableBalanceLabel = "Available Balance"
        static let balanceIcon = "dollarsign.circle.fill"
        static let selectRecipientLabel = "Select Recipient"
        static let chooseContactPlaceholder = "Choose a contact"
        static let chevronDownIcon = "chevron.down"
        static let removeContactIcon = "xmark.circle.fill"
        static let sendMoneyButton = "Send Money"
        static let successTitle = "Transfer Successful!"
        static let currencyFormat = "%.2f"
        static let alertMessageFormat = "Send $%.2f to %@?"

        static let formSpacing: CGFloat = 24
        static let spacerMinLength: CGFloat = 20
        static let balanceCardSpacing: CGFloat = 4
        static let balanceIconSize: CGFloat = 40
        static let contactPickerSpacing: CGFloat = 12
        static let contactAvatarSize: CGFloat = 50
        static let selectedContactSpacing: CGFloat = 12
        static let selectedContactAvatarSpacing: CGFloat = 4
        static let pickerCornerRadius: CGFloat = 12
    }

    @State private var viewModel: TransferViewModel
    let contacts: [Contact]
    let currentBalance: Double
    let currentUserId: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            if viewModel.transferSuccess {
                successView
            } else {
                transferFormView
            }
        }
        .navigationTitle(Layout.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .alert(Layout.confirmAlertTitle, isPresented: $viewModel.showConfirmation) {
            Button(Layout.cancelButton, role: .cancel) {}
            Button(Layout.confirmButton) {
                Task {
                    await viewModel.confirmTransfer()
                }
            }
        } message: {
            if let contact = viewModel.selectedContact,
               let amount = Double(viewModel.amount) {
                Text(String(format: Layout.alertMessageFormat, amount, contact.name))
            }
        }
        .alert(Layout.errorAlertTitle, isPresented: $viewModel.showError) {
            Button(Layout.errorAlertButton, role: .cancel) {}
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }

    private var transferFormView: some View {
        ScrollView {
            VStack(spacing: Layout.formSpacing) {
                balanceCard

                contactPickerCard

                amountCard

                if viewModel.selectedContact != nil && !viewModel.amount.isEmpty {
                    transferButton
                }

                Spacer(minLength: Layout.spacerMinLength)
            }
            .padding()
        }
    }

    private var balanceCard: some View {
        DSCard {
            HStack {
                VStack(alignment: .leading, spacing: Layout.balanceCardSpacing) {
                    Text(Layout.availableBalanceLabel)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("$\(String(format: Layout.currencyFormat, currentBalance))")
                        .font(.title2)
                        .fontWeight(.bold)
                }

                Spacer()

                Image(systemName: Layout.balanceIcon)
                    .font(.system(size: Layout.balanceIconSize))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [DSColors.gradientBlue, DSColors.gradientPurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        }
    }

    private var contactPickerCard: some View {
        DSCard {
            VStack(alignment: .leading, spacing: Layout.contactPickerSpacing) {
                Text(Layout.selectRecipientLabel)
                    .font(.headline)

                if let selectedContact = viewModel.selectedContact {
                    selectedContactView(contact: selectedContact)
                } else {
                    Menu {
                        ForEach(contacts) { contact in
                            Button(action: {
                                viewModel.selectedContact = contact
                            }) {
                                HStack {
                                    Text(contact.name)
                                    Spacer()
                                    Text(contact.email)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(Layout.chooseContactPlaceholder)
                                .foregroundColor(.secondary)
                            Spacer()
                            Image(systemName: Layout.chevronDownIcon)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(Layout.pickerCornerRadius)
                    }
                }
            }
        }
    }

    private func selectedContactView(contact: Contact) -> some View {
        HStack(spacing: Layout.selectedContactSpacing) {
            Circle()
                .fill(LinearGradient(
                    colors: [DSColors.gradientBlue, DSColors.gradientPurple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: Layout.contactAvatarSize, height: Layout.contactAvatarSize)
                .overlay(
                    Text(contact.name.prefix(1))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(DSColors.textOnGradient)
                )

            VStack(alignment: .leading, spacing: Layout.selectedContactAvatarSpacing) {
                Text(contact.name)
                    .font(.body)
                    .fontWeight(.semibold)

                Text(contact.email)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: {
                viewModel.selectedContact = nil
            }) {
                Image(systemName: Layout.removeContactIcon)
                    .foregroundColor(.secondary)
                    .font(.title3)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(Layout.pickerCornerRadius)
    }

    private var amountCard: some View {
        DSAmountInput(
            amount: $viewModel.amount,
            currentBalance: currentBalance
        )
    }

    private var transferButton: some View {
        DSButton(
            title: Layout.sendMoneyButton,
            style: .primary,
            isLoading: viewModel.isLoading
        ) {
            Task {
                await viewModel.initiateTransfer(
                    currentBalance: currentBalance,
                    currentUserId: currentUserId
                )
            }
        }
        .disabled(viewModel.isLoading)
    }

    private var successView: some View {
        DSSuccessView(
            title: Layout.successTitle,
            amount: Double(viewModel.amount),
            recipientName: viewModel.selectedContact?.name
        ) {
            viewModel.resetTransfer()
            dismiss()
        }
    }

    init(contacts: [Contact], currentBalance: Double, currentUserId: String, preselectedContact: Contact? = nil) {
        self.contacts = contacts
        self.currentBalance = currentBalance
        self.currentUserId = currentUserId
        let vm = TransferViewModel()
        if let preselectedContact = preselectedContact {
            vm.selectedContact = preselectedContact
        }
        self.viewModel = vm
    }
}

#Preview {
    NavigationStack {
        TransferView(
            contacts: [
                Contact(id: "1", name: "Alice Johnson", email: "alice@example.com", avatarURL: nil),
                Contact(id: "2", name: "Bob Smith", email: "bob@example.com", avatarURL: nil)
            ],
            currentBalance: 1234.56,
            currentUserId: "user_123"
        )
    }
}
