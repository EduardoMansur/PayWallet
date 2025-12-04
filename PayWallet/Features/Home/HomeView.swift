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
        DSCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Welcome back,")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.userName)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(viewModel.userEmail)
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

                    Text("$\(viewModel.balance, specifier: "%.2f")")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
            }
        }
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

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    init() {
        self.viewModel = HomeViewModel()
    }
}

#Preview {
    return HomeView()
}
