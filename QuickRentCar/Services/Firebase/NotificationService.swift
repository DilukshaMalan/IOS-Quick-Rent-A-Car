import Foundation
import FirebaseMessaging
import UserNotifications

class NotificationService {
    static let shared = NotificationService()
    private init() {}

    func updateFCMToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: Constants.UserDefaultsKeys.lastKnownFCMToken)
        Task {
            guard let userId = await AuthService.shared.currentUserId else { return }
            try? await FirestoreService.shared.updateUser(User(
                id: userId,
                email: "",
                fullName: "",
                fcmToken: token
            ))
        }
    }

    func schedulePickupReminder(bookingId: String, vehicleName: String, pickupDate: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Pickup Reminder 🚗"
        content.body = "Your \(vehicleName) is ready for pickup today!"
        content.sound = .default
        content.userInfo = ["bookingId": bookingId, "type": Constants.NotificationNames.pickupReminder]

        let triggerDate = pickupDate.adding(days: 0).addingTimeInterval(-3600)
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: "pickup-\(bookingId)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    func scheduleReturnReminder(bookingId: String, vehicleName: String, returnDate: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Return Reminder ⏰"
        content.body = "Please return your \(vehicleName) by today."
        content.sound = .default
        content.userInfo = ["bookingId": bookingId, "type": Constants.NotificationNames.returnReminder]

        let triggerDate = returnDate.adding(days: 0).addingTimeInterval(-7200)
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: "return-\(bookingId)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    func cancelNotifications(for bookingId: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["pickup-\(bookingId)", "return-\(bookingId)"]
        )
    }
}
