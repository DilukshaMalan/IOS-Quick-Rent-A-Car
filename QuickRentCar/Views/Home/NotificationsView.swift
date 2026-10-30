import SwiftUI

struct NotificationsView: View {
    @StateObject private var viewModel = NotificationsViewModel()

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()

            if viewModel.items.isEmpty {
                emptyState
            } else {
                notificationList
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if !viewModel.items.filter(\.isDelivered).isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Clear All") {
                        withAnimation {
                            viewModel.clearDelivered()
                        }
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.fallbackBlue)
                }
            }
        }
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
    }

    private var notificationList: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                let delivered  = viewModel.items.filter { $0.isDelivered }
                let scheduled  = viewModel.items.filter { !$0.isDelivered }

                if !delivered.isEmpty {
                    sectionHeader("Recent")
                    ForEach(delivered) { item in
                        NotificationRow(item: item)
                    }
                }

                if !scheduled.isEmpty {
                    sectionHeader("Scheduled")
                    ForEach(scheduled) { item in
                        NotificationRow(item: item)
                    }
                }
            }
            .padding(.top, .spacingS)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .kerning(0.8)
            Spacer()
        }
        .padding(.horizontal, .spacingL)
        .padding(.top, .spacingM)
        .padding(.bottom, .spacingXS)
    }

    private var emptyState: some View {
        VStack(spacing: .spacingM) {
            ZStack {
                Circle()
                    .fill(Color.fallbackBlue.opacity(0.1))
                    .frame(width: 80, height: 80)
                Image(systemName: "bell.slash.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(Color.fallbackBlue.opacity(0.6))
            }
            Text("No Notifications Yet")
                .font(.title3.bold())
                .foregroundStyle(Color.fallbackNavy)
            Text("Booking confirmations and reminders\nwill appear here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.spacingXXL)
    }
}

private struct NotificationRow: View {
    let item: AppNotificationItem

    var iconColor: Color {
        switch item.type {
        case .confirmed:      return Color.fallbackBlue
        case .pickup:         return .green
        case .returnReminder: return .orange
        case .general:        return .gray
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: .spacingM) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: item.type.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(item.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.fallbackNavy)
                    Spacer()
                    if let date = item.date {
                        Text(date.relativeFormatted)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Text(item.body)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if !item.isDelivered {
                    Label("Scheduled", systemImage: "clock")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.orange.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.horizontal, .spacingL)
        .padding(.vertical, .spacingM)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .overlay(
            Rectangle()
                .fill(Color(UIColor.separator).opacity(0.4))
                .frame(height: 0.5)
                .padding(.leading, 72),
            alignment: .bottom
        )
    }
}

private extension Date {
    var relativeFormatted: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: .now)
    }
}

#Preview {
    NavigationStack {
        NotificationsView()
    }
}
