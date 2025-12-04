import Foundation

/// A shared balance manager for mock services to maintain consistent balance state
/// This allows the balance to update when transfers are made
actor MockBalanceManager {
    static let shared = MockBalanceManager()

    private var currentBalance: Double = 1234.56

    private init() {}

    func getBalance() -> Double {
        return currentBalance
    }

    func setBalance(_ newBalance: Double) {
        currentBalance = newBalance
    }

    func deductAmount(_ amount: Double) -> Double {
        currentBalance -= amount
        return currentBalance
    }

    func reset() {
        currentBalance = 1234.56
    }
}
