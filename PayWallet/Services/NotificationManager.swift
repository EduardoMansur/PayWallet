import Foundation
import UserNotifications

protocol NotificationManagerProtocol {
    func requestAuthorization() async -> Bool
    func sendTransferSuccessNotification(amount: Double, recipientName: String) async
}

final class NotificationManager: NotificationManagerProtocol {
    private let notificationCenter: UNUserNotificationCenter

    init(notificationCenter: UNUserNotificationCenter = .current()) {
        self.notificationCenter = notificationCenter
    }

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            print("Failed to request notification authorization: \(error)")
            return false
        }
    }

    func sendTransferSuccessNotification(amount: Double, recipientName: String) async {
        let content = UNMutableNotificationContent()
        content.title = "Transfer Successful"
        content.body = "You successfully sent $\(String(format: "%.2f", amount)) to \(recipientName)"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
        } catch {
            print("Failed to schedule notification: \(error)")
        }
    }
}

final class MockNotificationManager: NotificationManagerProtocol {
    func requestAuthorization() async -> Bool {
        // Simulate authorization
        try? await Task.sleep(nanoseconds: 100_000_000)
        return true
    }

    func sendTransferSuccessNotification(amount: Double, recipientName: String) async {
        // Simulate notification sending
        try? await Task.sleep(nanoseconds: 100_000_000)
        print("Mock notification sent: Transfer of $\(amount) to \(recipientName)")
    }
}
