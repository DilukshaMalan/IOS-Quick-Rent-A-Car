import Foundation
import UserNotifications

@MainActor
class NotificationsViewModel: ObservableObject {
    @Published var items: [AppNotificationItem] = []
    @Published var unreadCount: Int = 0

    func load() async {
        let center = UNUserNotificationCenter.current()

        let pending = await center.pendingNotificationRequests()
        let delivered = await center.deliveredNotifications()

        var result: [AppNotificationItem] = []

        for note in delivered {
            result.append(AppNotificationItem(
                id: note.request.identifier,
                title: note.request.content.title,
                body: note.request.content.body,
                date: note.date,
                type: notificationType(from: note.request.content.userInfo),
                isDelivered: true
            ))
        }

        for req in pending {
            let fireDate = triggerDate(from: req.trigger)
            result.append(AppNotificationItem(
                id: req.identifier,
                title: req.content.title,
                body: req.content.body,
                date: fireDate,
                type: notificationType(from: req.content.userInfo),
                isDelivered: false
            ))
        }

        result.sort { ($0.date ?? .distantFuture) > ($1.date ?? .distantFuture) }
        items = result
        unreadCount = delivered.count
    }

    func clearDelivered() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        items.removeAll { $0.isDelivered }
        unreadCount = 0
    }

    private func notificationType(from userInfo: [AnyHashable: Any]) -> AppNotificationItem.NotifType {
        guard let type = userInfo["type"] as? String else { return .general }
        switch type {
        case Constants.NotificationNames.bookingConfirmed: return .confirmed
        case Constants.NotificationNames.pickupReminder:  return .pickup
        case Constants.NotificationNames.returnReminder:  return .returnReminder
        default: return .general
        }
    }

    private func triggerDate(from trigger: UNNotificationTrigger?) -> Date? {
        if let t = trigger as? UNTimeIntervalNotificationTrigger {
            return t.nextTriggerDate()
        }
        if let t = trigger as? UNCalendarNotificationTrigger {
            return t.nextTriggerDate()
        }
        return nil
    }
}

struct AppNotificationItem: Identifiable {
    enum NotifType {
        case confirmed, pickup, returnReminder, general

        var icon: String {
            switch self {
            case .confirmed:      return "checkmark.seal.fill"
            case .pickup:         return "car.fill"
            case .returnReminder: return "clock.arrow.circlepath"
            case .general:        return "bell.fill"
            }
        }

        var color: String {
            switch self {
            case .confirmed:      return "blue"
            case .pickup:         return "green"
            case .returnReminder: return "orange"
            case .general:        return "gray"
            }
        }
    }

    let id: String
    let title: String
    let body: String
    let date: Date?
    let type: NotifType
    let isDelivered: Bool
}
