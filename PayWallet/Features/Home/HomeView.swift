import SwiftUI
import DesignSystem

struct HomeView: View {
    enum Layout {
        static let navigationTitle = "Home"
        static let logoutIcon = "rectangle.portrait.and.arrow.right"
        static let logoutText = "Logout"
        static let transferIcon = "paperplane.fill"
        static let errorAlertTitle = "Error"
        static let errorAlertButton = "OK"
        static let contactsSectionTitle = "Contacts"
        static let emptyContactsMessage = "No contacts available"

        static let contentSpacing: CGFloat = 20
        static let loadingTopPadding: CGFloat = 40
        static let logoutButtonSpacing: CGFloat = 4
        static let contactsListSpacing: CGFloat = 12
        static let contactsTitlePadding: CGFloat = 4
        static let minimumBalance: Double = 0
    }

    @State private var viewModel: HomeViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Layout.contentSpacing) {
                    if viewModel.isLoading {
                        ProgressView()
                            .padding(.top, Layout.loadingTopPadding)
                    } else {
                        balanceCard
                        contactsList
                    }
                }
                .padding()
            }
            .navigationTitle(Layout.navigationTitle)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        Task {
                            await viewModel.logout()
                        }
                    }) {
                        HStack(spacing: Layout.logoutButtonSpacing) {
                            Image(systemName: Layout.logoutIcon)
                                .font(.body)
                            Text(Layout.logoutText)
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
                        Image(systemName: Layout.transferIcon)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [DSColors.gradientBlue, DSColors.gradientPurple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .disabled(viewModel.contacts.isEmpty || viewModel.balance <= Layout.minimumBalance)
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
            .alert(Layout.errorAlertTitle, isPresented: .constant(viewModel.errorMessage != nil)) {
                Button(Layout.errorAlertButton) {
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
        VStack(alignment: .leading, spacing: Layout.contactsListSpacing) {
            Text(Layout.contactsSectionTitle)
                .font(.headline)
                .padding(.horizontal, Layout.contactsTitlePadding)

            if viewModel.contacts.isEmpty {
                DSCard {
                    Text(Layout.emptyContactsMessage)
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
