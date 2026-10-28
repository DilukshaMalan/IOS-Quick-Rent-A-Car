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
                NavigationLink(destination: BookingDetailView(booking: booking)) {
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

// MARK: - Rich Booking Card
struct BookingCard: View {
    let booking: Booking

    private var statusColor: Color {
        switch booking.status {
        case .active:    return .green
        case .confirmed: return Color.fallbackBlue
        case .pending:   return .orange
        case .completed: return .gray
        case .cancelled: return .red
        }
    }

    private var isActive: Bool {
        booking.status == .active || booking.status == .confirmed
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // ── Top status bar ───────────────────────────────────────
            HStack(spacing: .spacingS) {
                Image(systemName: booking.status.icon)
                    .font(.caption.bold())
                Text(booking.status.rawValue.uppercased())
                    .font(.caption2.bold())
                    .tracking(0.8)
                Spacer()
                if isActive {
                    // Pulsing live indicator
                    HStack(spacing: 4) {
                        Circle()
                            .fill(.green)
                            .frame(width: 7, height: 7)
                        Text("LIVE")
                            .font(.caption2.bold())
                            .tracking(0.8)
                    }
                    .foregroundStyle(.green)
                }
            }
            .foregroundStyle(statusColor)
            .padding(.horizontal, .spacingM)
            .padding(.vertical, .spacingS)
            .background(statusColor.opacity(0.1))

            // ── Main card content ─────────────────────────────────────
            VStack(alignment: .leading, spacing: .spacingM) {
                // Vehicle name + booking ID
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(booking.vehicleName)
                            .font(.headline)
                            .foregroundStyle(Color.fallbackNavy)
                        Text("ID: \(booking.id?.prefix(8).uppercased() ?? "—")")
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    // Total price badge
                    Text(PriceCalculator.format(booking.totalPrice))
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.fallbackBlue)
                        .padding(.horizontal, .spacingS)
                        .padding(.vertical, 4)
                        .background(Color.fallbackBlue.opacity(0.1))
                        .clipShape(Capsule())
                }

                Divider()

                // Dates row
                HStack(spacing: .spacingL) {
                    dateColumn(label: "Pick-up", date: booking.pickupDate, icon: "arrow.up.circle.fill", color: .green)
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    dateColumn(label: "Return", date: booking.returnDate, icon: "arrow.down.circle.fill", color: .red)
                }

                // Location row
                HStack(spacing: .spacingS) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundStyle(Color.fallbackBlue)
                        .font(.subheadline)
                    Text(booking.pickupLocation)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Spacer()
                    Text("\(booking.totalDays) day\(booking.totalDays == 1 ? "" : "s")")
                        .font(.caption.bold())
                        .foregroundStyle(Color.fallbackBlue)
                        .padding(.horizontal, .spacingS)
                        .padding(.vertical, 3)
                        .background(Color.fallbackBlue.opacity(0.08))
                        .clipShape(Capsule())
                }

                // CTA hint for active bookings
                if isActive {
                    HStack {
                        Spacer()
                        Label("Tap to get directions", systemImage: "map.fill")
                            .font(.caption.bold())
                            .foregroundStyle(Color.fallbackBlue)
                    }
                }
            }
            .padding(.spacingM)
            .background(Color(UIColor.systemBackground))
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: isActive ? Color.fallbackBlue.opacity(0.12) : .black.opacity(0.06),
                radius: isActive ? 8 : 4, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(isActive ? statusColor.opacity(0.4) : Color.clear, lineWidth: 1.5)
        )
    }

    @ViewBuilder
    private func dateColumn(label: String, date: Date, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.caption2)
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Text(date.displayDate)
                .font(.caption.bold())
                .foregroundStyle(Color.fallbackNavy)
        }
    }
}

// MARK: - Booking Detail View (tapped from a card)
struct BookingDetailView: View {
    let booking: Booking
    @StateObject private var telemetryVM = VehicleStatsViewModel()
    @State private var showDirectionsAlert = false
    @State private var mapItem: MKMapItem?

    // Test origin: Bandaranaike International Airport
    private let testOrigin = CLLocationCoordinate2D(latitude: 7.1802, longitude: 79.8839)
    private let testOriginName = "Bandaranaike Airport"

    private var isActive: Bool {
        booking.status == .active || booking.status == .confirmed
    }

    private var lastKnownCoord: CLLocationCoordinate2D? {
        guard let loc = telemetryVM.lastKnownLocation else { return nil }
        return CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: .spacingL) {

                // ── Status banner ─────────────────────────────────────
                statusBanner

                // ── Vehicle & booking info ────────────────────────────
                infoCard

                // ── Map preview + directions button (active only) ─────
                if isActive {
                    navigationCard
                }

                // ── Price breakdown ───────────────────────────────────
                priceCard
            }
            .padding(.horizontal, .spacingM)
            .padding(.top, .spacingM)
            .padding(.bottom, .spacingXXL)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Booking Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if isActive {
                // Load telemetry to get the last known vehicle location
                try? await telemetryVM.loadTelemetry()
            }
        }
    }

    // MARK: - Status Banner
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

    // MARK: - Info Card
    private var infoCard: some View {
        VStack(alignment: .leading, spacing: .spacingM) {
            sectionLabel("Trip Details")

            detailRow(icon: "mappin.circle.fill",  color: .green,   label: "Pick-up Location", value: booking.pickupLocation)
            detailRow(icon: "mappin.and.ellipse",  color: .red,     label: "Drop-off Location", value: booking.dropOffLocation)
            Divider()
            detailRow(icon: "clock.fill",          color: Color.fallbackBlue, label: "Pick-up Date",  value: booking.pickupDate.displayDate)
            detailRow(icon: "clock.arrow.circlepath", color: .orange, label: "Return Date",    value: booking.returnDate.displayDate)
            detailRow(icon: "calendar",            color: .purple,  label: "Duration",        value: "\(booking.totalDays) day\(booking.totalDays == 1 ? "" : "s")")
        }
        .padding(.spacingM)
        .cardStyle()
    }

    // MARK: - Navigation Card (active bookings only)
    private var navigationCard: some View {
        VStack(alignment: .leading, spacing: .spacingM) {
            sectionLabel("Vehicle Location")

            if telemetryVM.isLoading {
                HStack(spacing: .spacingS) {
                    ProgressView()
                    Text("Finding vehicle…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, .spacingM)
            } else if let coord = lastKnownCoord {
                // Mini map snapshot
                LocationMapView(vehicleCoord: coord, originCoord: testOrigin)
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                // Last seen info
                if let loc = telemetryVM.lastKnownLocation {
                    HStack(spacing: .spacingS) {
                        Image(systemName: "location.fill")
                            .foregroundStyle(Color.fallbackBlue)
                            .font(.caption)
                        Text("Last seen: \(loc.timestamp.displayDateTime)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Directions button
                Button {
                    openDirections(to: coord)
                } label: {
                    Label("Get Directions (Google Maps)", systemImage: "map.fill")
                        .primaryButtonStyle()
                }

                Button {
                    openAppleMaps(to: coord)
                } label: {
                    Label("Open in Apple Maps", systemImage: "apple.logo")
                        .secondaryButtonStyle()
                }
            } else {
                HStack(spacing: .spacingS) {
                    Image(systemName: "location.slash.fill")
                        .foregroundStyle(.secondary)
                    Text("Vehicle location not available")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, .spacingM)
            }
        }
        .padding(.spacingM)
        .cardStyle()
    }

    // MARK: - Price Card
    private var priceCard: some View {
        VStack(alignment: .leading, spacing: .spacingM) {
            sectionLabel("Price Breakdown")

            priceRow(label: "Daily Rate", value: PriceCalculator.format(booking.dailyRate))
            priceRow(label: "Duration", value: "\(booking.totalDays) day\(booking.totalDays == 1 ? "" : "s")")
            priceRow(label: "Subtotal", value: PriceCalculator.format(booking.dailyRate * Double(booking.totalDays)))
            priceRow(label: "Tax (10%)", value: PriceCalculator.format(booking.dailyRate * Double(booking.totalDays) * 0.1))
            Divider()
            HStack {
                Text("Total Paid")
                    .font(.headline)
                    .foregroundStyle(Color.fallbackNavy)
                Spacer()
                Text(PriceCalculator.format(booking.totalPrice))
                    .font(.title3.bold())
                    .foregroundStyle(Color.fallbackBlue)
            }
        }
        .padding(.spacingM)
        .cardStyle()
    }

    // MARK: - Helpers
    private var statusColor: Color {
        switch booking.status {
        case .active:    return .green
        case .confirmed: return Color.fallbackBlue
        case .pending:   return .orange
        case .completed: return .gray
        case .cancelled: return .red
        }
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

    // MARK: - Navigation Actions
    private func openDirections(to dest: CLLocationCoordinate2D) {
        // Try Google Maps first, fall back to Apple Maps
        let googleURL = URL(string: "comgooglemaps://?saddr=\(testOrigin.latitude),\(testOrigin.longitude)&daddr=\(dest.latitude),\(dest.longitude)&directionsmode=driving")
        let googleWebURL = URL(string: "https://www.google.com/maps/dir/\(testOrigin.latitude),\(testOrigin.longitude)/\(dest.latitude),\(dest.longitude)/")

        if let url = googleURL, UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else if let url = googleWebURL {
            UIApplication.shared.open(url)
        }
    }

    private func openAppleMaps(to dest: CLLocationCoordinate2D) {
        let origin = MKMapItem(placemark: MKPlacemark(coordinate: testOrigin))
        origin.name = testOriginName

        let destination = MKMapItem(placemark: MKPlacemark(coordinate: dest))
        destination.name = "\(booking.vehicleName) – Last Location"

        MKMapItem.openMaps(
            with: [origin, destination],
            launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
        )
    }
}

// MARK: - Small Map Preview using MapKit
struct LocationMapView: UIViewRepresentable {
    let vehicleCoord: CLLocationCoordinate2D
    let originCoord: CLLocationCoordinate2D

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.isUserInteractionEnabled = false
        map.showsCompass = false
        map.pointOfInterestFilter = .excludingAll

        // Vehicle annotation
        let vehiclePin = MKPointAnnotation()
        vehiclePin.coordinate = vehicleCoord
        vehiclePin.title = "Vehicle"

        // Origin annotation
        let originPin = MKPointAnnotation()
        originPin.coordinate = originCoord
        originPin.title = "You (Test)"

        map.addAnnotations([vehiclePin, originPin])

        // Show both annotations
        let coords = [vehicleCoord, originCoord]
        var rect = MKMapRect.null
        for coord in coords {
            let pt = MKMapPoint(coord)
            rect = rect.union(MKMapRect(x: pt.x - 5000, y: pt.y - 5000, width: 10000, height: 10000))
        }
        map.setVisibleMapRect(rect, edgePadding: UIEdgeInsets(top: 30, left: 30, bottom: 30, right: 30), animated: false)
        return map
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {}
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
