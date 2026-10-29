import SwiftUI
import MapKit

struct BookingsTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = BookingsViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Button {
                        NotificationCenter.default.post(name: .navigateToHome, object: nil)
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color.fallbackNavy)
                            .frame(width: 36, height: 36)
                            .background(Color.gray.opacity(0.09))
                            .clipShape(Circle())
                    }

                    Spacer()

                    Text("My Bookings")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color.fallbackNavy)

                    Spacer()

                    Color.clear.frame(width: 36, height: 36)
                }
                .padding(.horizontal, .spacingM)
                .padding(.top, .spacingS)
                .padding(.bottom, .spacingS)
                .frame(maxWidth: 760)
                .frame(maxWidth: .infinity, alignment: .center)
                .background(Color(UIColor.systemGroupedBackground))

                Group {
                    if viewModel.isLoading {
                        loadingView
                    } else if viewModel.allBookings.isEmpty {
                        emptyView
                    } else {
                        bookingsList
                    }
                }
            }
            .navigationBarHidden(true)
            .toolbar(.hidden, for: .tabBar)
            .task {
                if let userId = authViewModel.currentUser?.id {
                    await viewModel.load(userId: userId)
                }
            }
            .refreshable {
                if let userId = authViewModel.currentUser?.id {
                    await viewModel.load(userId: userId)
                }
            }
        }
    }

    private var bookingsList: some View {
        ScrollView {
            LazyVStack(spacing: .spacingL, pinnedViews: []) {
                if !viewModel.activeBookings.isEmpty {
                    bookingSection(
                        title: "Ongoing & Confirmed",
                        icon: "car.fill",
                        tint: .green,
                        bookings: viewModel.activeBookings
                    )
                }

                if !viewModel.pendingBookings.isEmpty {
                    bookingSection(
                        title: "Pending",
                        icon: "clock.fill",
                        tint: .orange,
                        bookings: viewModel.pendingBookings
                    )
                }

                if !viewModel.pastBookings.isEmpty {
                    bookingSection(
                        title: "Completed",
                        icon: "checkmark.seal.fill",
                        tint: .gray,
                        bookings: viewModel.pastBookings
                    )
                }

                if !viewModel.cancelledBookings.isEmpty {
                    bookingSection(
                        title: "Cancelled",
                        icon: "xmark.circle.fill",
                        tint: .red,
                        bookings: viewModel.cancelledBookings
                    )
                }
            }
            .padding(.horizontal, .spacingM)
            .padding(.top, .spacingM)
            .padding(.bottom, .spacingXXL)
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .background(Color(UIColor.systemGroupedBackground))
    }

    @ViewBuilder
    private func bookingSection(title: String, icon: String, tint: Color, bookings: [Booking]) -> some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            HStack(spacing: .spacingS) {
                Image(systemName: icon)
                    .foregroundStyle(tint)
                    .font(.subheadline.bold())
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.fallbackNavy)
                Spacer()
                Text("\(bookings.count)")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .frame(minWidth: 22, minHeight: 22)
                    .background(tint)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, .spacingXS)

            ForEach(bookings) { booking in
                NavigationLink {
                    if booking.isOngoing {
                        VehicleNavigationView(booking: booking)
                    } else {
                        BookingDetailView(booking: booking)
                    }
                } label: {
                    BookingCard(booking: booking)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: .spacingM) {
            ProgressView()
            Text("Loading bookings…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyView: some View {
        ContentUnavailableView(
            "No Bookings Yet",
            systemImage: "car.fill",
            description: Text("Your bookings will appear here once you rent a vehicle.")
        )
    }
}

extension Booking {
    var isOngoing: Bool { status == .active || status == .confirmed }

    func daysUsed(now: Date = Date()) -> Int {
        guard now > pickupDate else { return 0 }
        let d = Calendar.current.dateComponents([.day], from: pickupDate.startOfDay, to: now.startOfDay).day ?? 0
        return min(max(d + 1, 1), max(totalDays, 1))
    }

    func daysLeft(now: Date = Date()) -> Int {
        guard returnDate > now else { return 0 }
        let d = Calendar.current.dateComponents([.day], from: now.startOfDay, to: returnDate.startOfDay).day ?? 0
        return max(d, 0)
    }

    func progress(now: Date = Date()) -> Double {
        let total = returnDate.timeIntervalSince(pickupDate)
        guard total > 0 else { return 0 }
        return min(max(now.timeIntervalSince(pickupDate) / total, 0), 1)
    }

    var daysText: String { "\(totalDays) day\(totalDays == 1 ? "" : "s")" }
}

extension Booking.BookingStatus {
    var tint: Color {
        switch self {
        case .active:    return .green
        case .confirmed: return Color.fallbackBlue
        case .pending:   return .orange
        case .completed: return .gray
        case .cancelled: return .red
        }
    }
}

struct BookingCard: View {
    let booking: Booking
    @State private var pulse = false

    private var statusColor: Color { booking.status.tint }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            statusBar

            VStack(alignment: .leading, spacing: .spacingM) {
                header
                Divider()
                periodRow
                if booking.isOngoing { progressSection }
                if booking.isOngoing { navigateHint }
            }
            .padding(.spacingM)
            .background(Color(UIColor.systemBackground))
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: booking.isOngoing ? statusColor.opacity(0.15) : .black.opacity(0.06),
                radius: booking.isOngoing ? 8 : 4, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(booking.isOngoing ? statusColor.opacity(0.4) : .clear, lineWidth: 1.5)
        )
    }

    private var statusBar: some View {
        HStack(spacing: .spacingS) {
            Image(systemName: booking.status.icon)
                .font(.caption.bold())
            Text(booking.status.rawValue.uppercased())
                .font(.caption2.bold())
                .tracking(0.8)
            Spacer()
            if booking.status == .active {
                HStack(spacing: 4) {
                    Circle()
                        .fill(.green)
                        .frame(width: 7, height: 7)
                        .scaleEffect(pulse ? 1.4 : 0.9)
                        .opacity(pulse ? 0.5 : 1)
                        .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: pulse)
                    Text("IN USE")
                        .font(.caption2.bold())
                        .tracking(0.8)
                }
                .onAppear { pulse = true }
            } else if booking.status == .confirmed {
                Text("READY TO COLLECT")
                    .font(.caption2.bold())
                    .tracking(0.8)
            }
        }
        .foregroundStyle(statusColor)
        .padding(.horizontal, .spacingM)
        .padding(.vertical, .spacingS)
        .background(statusColor.opacity(0.1))
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text(booking.vehicleName)
                    .font(.headline)
                    .foregroundStyle(Color.fallbackNavy)
                Text("Booking \(booking.id?.prefix(8).uppercased() ?? "—")")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(PriceCalculator.format(booking.totalPrice))
                .font(.subheadline.bold())
                .foregroundStyle(Color.fallbackBlue)
                .padding(.horizontal, .spacingS)
                .padding(.vertical, 4)
                .background(Color.fallbackBlue.opacity(0.1))
                .clipShape(Capsule())
        }
    }

    private var periodRow: some View {
        HStack(spacing: .spacingS) {
            Image(systemName: "calendar")
                .foregroundStyle(Color.fallbackBlue)
                .font(.subheadline)
            Text("\(booking.pickupDate.displayDate) – \(booking.returnDate.displayDate)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.fallbackNavy)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer()
            Text(booking.daysText)
                .font(.caption.bold())
                .foregroundStyle(Color.fallbackBlue)
                .padding(.horizontal, .spacingS)
                .padding(.vertical, 3)
                .background(Color.fallbackBlue.opacity(0.08))
                .clipShape(Capsule())
        }
    }

    private var progressSection: some View {
        let started = Date() >= booking.pickupDate
        return VStack(alignment: .leading, spacing: 6) {
            ProgressView(value: booking.progress())
                .tint(statusColor)
            HStack {
                if started {
                    Text("Day \(booking.daysUsed()) of \(booking.totalDays)")
                    Spacer()
                    Text("\(booking.daysLeft()) day\(booking.daysLeft() == 1 ? "" : "s") left")
                } else {
                    Text("Rental starts \(booking.pickupDate.displayDate)")
                    Spacer()
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private var navigateHint: some View {
        HStack(spacing: .spacingS) {
            Image(systemName: "location.north.circle.fill")
            Text("Find & navigate to your vehicle")
                .font(.caption.bold())
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption2.bold())
        }
        .foregroundStyle(Color.fallbackBlue)
        .padding(.horizontal, .spacingM)
        .padding(.vertical, 10)
        .background(Color.fallbackBlue.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct BookingDetailView: View {
    let booking: Booking
    @Environment(\.dismiss) private var dismiss

    private var statusColor: Color { booking.status.tint }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.fallbackNavy)
                        .frame(width: 36, height: 36)
                        .background(Color.gray.opacity(0.09))
                        .clipShape(Circle())
                }

                Spacer()

                Text("Booking Details")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.fallbackNavy)

                Spacer()

                Color.clear.frame(width: 36, height: 36)
            }
            .padding(.horizontal, .spacingM)
            .padding(.top, .spacingS)
            .padding(.bottom, .spacingS)
            .background(Color(UIColor.systemGroupedBackground))

            ScrollView {
                VStack(spacing: .spacingL) {
                    statusBanner
                    rentalCard
                    priceCard
                }
                .padding(.horizontal, .spacingM)
                .padding(.top, .spacingM)
                .padding(.bottom, .spacingXXL)
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
    }

    private var statusBanner: some View {
        HStack(spacing: .spacingM) {
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.15))
                    .frame(width: 52, height: 52)
                Image(systemName: booking.status.icon)
                    .font(.title3.bold())
                    .foregroundStyle(statusColor)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(booking.status.rawValue)
                    .font(.headline)
                    .foregroundStyle(statusColor)
                Text(booking.vehicleName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("ID: \(booking.id?.prefix(8).uppercased() ?? "—")")
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
        }
        .padding(.spacingM)
        .background(statusColor.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var rentalCard: some View {
        VStack(alignment: .leading, spacing: .spacingM) {
            sectionLabel("Rental Period")

            detailRow(icon: "calendar.badge.plus", color: .green,
                      label: "Rental starts", value: booking.pickupDate.displayDate)
            detailRow(icon: "calendar.badge.checkmark", color: .orange,
                      label: "Rental ends", value: booking.returnDate.displayDate)
            detailRow(icon: "calendar", color: .purple,
                      label: "Duration", value: booking.daysText)

            if booking.isOngoing && Date() >= booking.pickupDate {
                Divider()
                ProgressView(value: booking.progress()).tint(statusColor)
                HStack {
                    Text("Day \(booking.daysUsed()) of \(booking.totalDays)")
                    Spacer()
                    Text("\(booking.daysLeft()) day\(booking.daysLeft() == 1 ? "" : "s") left")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.spacingM)
        .cardStyle()
    }

    private var paidLabel: String {
        switch booking.status {
        case .completed:            return "Total Paid"
        case .cancelled:            return "Total (cancelled)"
        case .active, .confirmed:   return "Total"
        case .pending:              return "Total Due"
        }
    }

    private var priceCard: some View {
        let subtotal = booking.dailyRate * Double(booking.totalDays)
        let taxPercent = Int((Constants.Pricing.taxRate * 100).rounded())
        return VStack(alignment: .leading, spacing: .spacingM) {
            sectionLabel("Price Breakdown")

            priceRow(label: "Daily Rate", value: PriceCalculator.format(booking.dailyRate))
            priceRow(label: "Duration", value: booking.daysText)
            priceRow(label: "Subtotal", value: PriceCalculator.format(subtotal))
            priceRow(label: "Tax (\(taxPercent)%)", value: PriceCalculator.format(PriceCalculator.taxAmount(subtotal: subtotal)))
            Divider()
            HStack {
                Text(paidLabel)
                    .font(.headline)
                    .foregroundStyle(Color.fallbackNavy)
                Spacer()
                Text(PriceCalculator.format(booking.totalPrice))
                    .font(.title3.bold())
                    .foregroundStyle(Color.fallbackBlue)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.spacingM)
        .cardStyle()
    }

    @ViewBuilder
    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.footnote.bold())
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
    }

    @ViewBuilder
    private func detailRow(icon: String, color: Color, label: String, value: String) -> some View {
        HStack(spacing: .spacingM) {
            Image(systemName: icon)
                .frame(width: 22)
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.fallbackNavy)
            }
            Spacer()
        }
    }

    @ViewBuilder
    private func priceRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.fallbackNavy)
        }
    }
}

@MainActor
class BookingsViewModel: ObservableObject {
    @Published var allBookings: [Booking] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let firestoreService = FirestoreService.shared

    var activeBookings: [Booking] {
        allBookings.filter { $0.status == .active || $0.status == .confirmed }
                   .sorted { $0.pickupDate < $1.pickupDate }
    }
    var pendingBookings: [Booking] {
        allBookings.filter { $0.status == .pending }
                   .sorted { $0.pickupDate < $1.pickupDate }
    }
    var pastBookings: [Booking] {
        allBookings.filter { $0.status == .completed }
                   .sorted { $0.returnDate > $1.returnDate }
    }
    var cancelledBookings: [Booking] {
        allBookings.filter { $0.status == .cancelled }
                   .sorted { $0.createdAt > $1.createdAt }
    }

    func load(userId: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            allBookings = try await firestoreService.fetchBookings(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
