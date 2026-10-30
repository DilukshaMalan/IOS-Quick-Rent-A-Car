import SwiftUI
import UserNotifications

struct HomeTopBarView: View {
    let userName: String
    @State private var unreadCount: Int = 0

    var body: some View {
        HStack(alignment: .center) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.fallbackBlue)
                        .frame(width: 36, height: 36)
                    Image(systemName: "car.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text("QuickRentCar")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Color.fallbackNavy)
                    Text("Drive Your Next Adventure")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            NavigationLink(destination: NotificationsView()) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.fallbackNavy)
                        .frame(width: 40, height: 40)
                        .background(Color.gray.opacity(0.09))
                        .clipShape(Circle())

                    if unreadCount > 0 {
                        ZStack {
                            Circle()
                                .fill(.red)
                                .frame(width: unreadCount > 9 ? 18 : 14, height: 14)
                            Text(unreadCount > 9 ? "9+" : "\(unreadCount)")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        .offset(x: 2, y: -1)
                    } else {
                        Circle()
                            .fill(.red)
                            .frame(width: 9, height: 9)
                            .offset(x: 1, y: 0)
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, .spacingM)
        .padding(.top, .spacingS)
        .padding(.bottom, 4)
        .task { await refreshBadge() }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            Task { await refreshBadge() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshNotificationBadge)) { _ in
            Task { await refreshBadge() }
        }
    }

    private func refreshBadge() async {
        let delivered = await UNUserNotificationCenter.current().deliveredNotifications()
        unreadCount = delivered.count
    }
}

extension Notification.Name {
    static let refreshNotificationBadge = Notification.Name("refreshNotificationBadge")
}

#Preview {
    HomeTopBarView(userName: "Diluksha")
        .padding(.vertical)
}
