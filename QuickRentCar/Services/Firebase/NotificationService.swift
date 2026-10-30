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

    private func ensureAuthorizedThenAdd(_ request: UNNotificationRequest) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                center.add(request) { error in
                    if let error {
                        print("[NotificationService] Failed to schedule \(request.identifier): \(error.localizedDescription)")
                    } else {
                        print("[NotificationService] Scheduled: \(request.identifier)")
                    }
                }
            case .notDetermined:
                center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                    guard granted else {
                        print("[NotificationService] Permission denied — cannot schedule \(request.identifier)")
                        return
                    }
                    center.add(request) { error in
                        if let error {
                            print("[NotificationService] Failed to schedule \(request.identifier): \(error.localizedDescription)")
                        } else {
                            print("[NotificationService] Scheduled after grant: \(request.identifier)")
                        }
                    }
                }
            case .denied:
                print("[NotificationService] Permission denied — cannot schedule \(request.identifier)")
            @unknown default:
                break
            }
        }
    }

    func scheduleBookingConfirmedNotification(bookingId: String, vehicleName: String, pickupDate: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Booking Confirmed! 🎉"
        content.body = "Your \(vehicleName) booking is confirmed. Pickup on \(pickupDate.formatted(.dateTime.month(.abbreviated).day().hour().minute()))."
        content.sound = .default
        content.badge = 1
        content.userInfo = ["bookingId": bookingId, "type": Constants.NotificationNames.bookingConfirmed]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
        let request = UNNotificationRequest(identifier: "confirmed-\(bookingId)", content: content, trigger: trigger)
        ensureAuthorizedThenAdd(request)
    }

    func schedulePickupReminder(bookingId: String, vehicleName: String, pickupDate: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Pickup Reminder 🚗"
        content.body = "Your \(vehicleName) is ready for pickup today! Don't forget to check in."
        content.sound = .default
        content.userInfo = ["bookingId": bookingId, "type": Constants.NotificationNames.pickupReminder]

        let triggerDate = pickupDate.addingTimeInterval(-3600)
        guard triggerDate > Date() else {
            print("[NotificationService] Skipping pickup reminder — trigger date is in the past.")
            return
        }

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: "pickup-\(bookingId)", content: content, trigger: trigger)
        ensureAuthorizedThenAdd(request)
    }

    func scheduleReturnReminder(bookingId: String, vehicleName: String, returnDate: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Return Reminder ⏰"
        content.body = "Please return your \(vehicleName) by today. Avoid late return charges!"
        content.sound = .default
        content.userInfo = ["bookingId": bookingId, "type": Constants.NotificationNames.returnReminder]

        let triggerDate = returnDate.addingTimeInterval(-7200)
        guard triggerDate > Date() else {
            print("[NotificationService] Skipping return reminder — trigger date is in the past.")
            return
        }

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: "return-\(bookingId)", content: content, trigger: trigger)
        ensureAuthorizedThenAdd(request)
    }

    func cancelNotifications(for bookingId: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["confirmed-\(bookingId)", "pickup-\(bookingId)", "return-\(bookingId)"]
        )
    }
}
