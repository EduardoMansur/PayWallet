import SwiftUI
import DesignSystem

struct TransferView: View {
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
        .navigationTitle("Send Money")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Confirm Transfer", isPresented: $viewModel.showConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Confirm") {
                Task {
                    await viewModel.confirmTransfer()
                }
            }
        } message: {
            if let contact = viewModel.selectedContact,
               let amount = Double(viewModel.amount) {
                Text("Send $\(String(format: "%.2f", amount)) to \(contact.name)?")
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }

    private var transferFormView: some View {
        ScrollView {
            VStack(spacing: 24) {
                balanceCard

                contactPickerCard

                amountCard

                if viewModel.selectedContact != nil && !viewModel.amount.isEmpty {
                    transferButton
                }

                Spacer(minLength: 20)
            }
            .padding()
        }
    }

    private var balanceCard: some View {
        DSCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Available Balance")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("$\(String(format: "%.2f", currentBalance))")
                        .font(.title2)
                        .fontWeight(.bold)
                }

                Spacer()

                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 40))
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
            VStack(alignment: .leading, spacing: 12) {
                Text("Select Recipient")
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
                            Text("Choose a contact")
                                .foregroundColor(.secondary)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
            }
        }
    }

    private func selectedContactView(contact: Contact) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(LinearGradient(
                    colors: [DSColors.gradientBlue, DSColors.gradientPurple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(contact.name.prefix(1))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(DSColors.textOnGradient)
                )

            VStack(alignment: .leading, spacing: 4) {
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
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
                    .font(.title3)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var amountCard: some View {
        DSAmountInput(
            amount: $viewModel.amount,
            currentBalance: currentBalance
        )
    }

    private var transferButton: some View {
        DSButton(
            title: "Send Money",
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
            title: "Transfer Successful!",
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
