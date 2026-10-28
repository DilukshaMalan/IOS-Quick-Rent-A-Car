import SwiftUI
import MapKit

// MARK: - Bookings Tab Root
struct BookingsTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = BookingsViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.allBookings.isEmpty {
                    emptyView
                } else {
                    bookingsList
                }
            }
            .navigationTitle("My Bookings")
            .navigationBarTitleDisplayMode(.large)
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

    // MARK: - Grouped list
    private var bookingsList: some View {
        ScrollView {
            LazyVStack(spacing: .spacingL, pinnedViews: []) {
                // Active / Confirmed — shown first with highlight
                if !viewModel.activeBookings.isEmpty {
                    bookingSection(
                        title: "Ongoing & Confirmed",
                        icon: "car.fill",
                        tint: .green,
                        bookings: viewModel.activeBookings
                    )
                }

                // Pending
                if !viewModel.pendingBookings.isEmpty {
                    bookingSection(
                        title: "Pending",
                        icon: "clock.fill",
                        tint: .orange,
                        bookings: viewModel.pendingBookings
                    )
                }

                // Past
                if !viewModel.pastBookings.isEmpty {
                    bookingSection(
                        title: "Completed",
                        icon: "checkmark.seal.fill",
                        tint: .gray,
                        bookings: viewModel.pastBookings
                    )
                }

                // Cancelled
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
        }
        .background(Color(UIColor.systemGroupedBackground))
    }

    @ViewBuilder
    private func bookingSection(title: String, icon: String, tint: Color, bookings: [Booking]) -> some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            // Section header
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
                // Ongoing rentals open the "Find my vehicle" navigation screen;
                // every other status opens the booking details.
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

    // MARK: - Loading
    private var loadingView: some View {
        VStack(spacing: .spacingM) {
            ProgressView()
            Text("Loading bookings…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty
    private var emptyView: some View {
        ContentUnavailableView(
            "No Bookings Yet",
            systemImage: "car.fill",
            description: Text("Your bookings will appear here once you rent a vehicle.")
        )
    }
}

// MARK: - Booking helpers (rental-period focused)
extension Booking {
    /// Rental is running now or is confirmed and waiting to start → navigation is available.
    var isOngoing: Bool { status == .active || status == .confirmed }

    /// Whole days since the rental started (0 before it starts), capped at `totalDays`.
    func daysUsed(now: Date = Date()) -> Int {
        guard now > pickupDate else { return 0 }
        let d = Calendar.current.dateComponents([.day], from: pickupDate.startOfDay, to: now.startOfDay).day ?? 0
        return min(max(d + 1, 1), max(totalDays, 1))
    }

    /// Whole days left until the return date (0 when overdue).
    func daysLeft(now: Date = Date()) -> Int {
        guard returnDate > now else { return 0 }
        let d = Calendar.current.dateComponents([.day], from: now.startOfDay, to: returnDate.startOfDay).day ?? 0
        return max(d, 0)
    }

    /// 0…1 progress through the rental period.
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

// MARK: - Rich Booking Card
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

    // MARK: Status bar
    private var statusBar: some View {
        HStack(spacing: .spacingS) {
            Image(systemName: booking.status.icon)
                .font(.caption.bold())
            Text(booking.status.rawValue.uppercased())
                .font(.caption2.bold())
                .tracking(0.8)
            Spacer()
            if booking.status == .active {
                // Pulsing dot – only while the rental is really running
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

    // MARK: Header
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

    // MARK: Rental period
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

    // MARK: Progress (ongoing only)
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

// MARK: - Booking Detail View (non-ongoing bookings, or via "Booking details")
struct BookingDetailView: View {
    let booking: Booking

    private var statusColor: Color { booking.status.tint }

    var body: some View {
        ScrollView {
            VStack(spacing: .spacingL) {
                statusBanner
                rentalCard
                priceCard
            }
            .padding(.horizontal, .spacingM)
            .padding(.top, .spacingM)
            .padding(.bottom, .spacingXXL)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Booking Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Status banner
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

    // MARK: Rental period (no pick-up / drop-off points)
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

    // MARK: Price
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

    // MARK: Helpers
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

// MARK: - ViewModel
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
