import SwiftUI
import DesignSystem

struct HomeView: View {
    @State private var viewModel: HomeViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if viewModel.isLoading {
                        ProgressView()
                            .padding(.top, 40)
                    } else {
                        balanceCard
                        contactsList
                    }
                }
                .padding()
            }
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        Task {
                            await viewModel.logout()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.body)
                            Text("Logout")
                                .font(.body)
                        }
                        .foregroundColor(.red)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        TransferView(
                            contacts: viewModel.contacts,
                            currentBalance: viewModel.balance,
                            currentUserId: viewModel.userId
                        )
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [DSColors.gradientBlue, DSColors.gradientPurple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .disabled(viewModel.contacts.isEmpty || viewModel.balance <= 0)
                }
            }
            .task {
                await viewModel.loadData()
            }
            .refreshable {
                await viewModel.loadData()
            }
            .onReceive(NotificationCenter.default.publisher(for: .transferCompleted)) { _ in
                Task {
                    await viewModel.loadData()
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }

    private var balanceCard: some View {
        DSBalanceCard(
            userName: viewModel.userName,
            userEmail: viewModel.userEmail,
            balance: viewModel.balance
        )
    }

    private var contactsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Contacts")
                .font(.headline)
                .padding(.horizontal, 4)

            if viewModel.contacts.isEmpty {
                DSCard {
                    Text("No contacts available")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
            } else {
                ForEach(viewModel.contacts) { contact in
                    NavigationLink {
                        TransferView(
                            contacts: viewModel.contacts,
                            currentBalance: viewModel.balance,
                            currentUserId: viewModel.userId,
                            preselectedContact: contact
                        )
                    } label: {
                        contactRow(contact: contact)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    private func contactRow(contact: Contact) -> some View {
        DSContactRow(
            name: contact.name,
            email: contact.email
        )
    }

    init() {
        self.viewModel = HomeViewModel()
    }
}

#Preview {
    return HomeView()
}
