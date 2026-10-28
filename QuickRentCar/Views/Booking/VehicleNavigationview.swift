import SwiftUI
import MapKit

// MARK: - Navigation ViewModel
/// Loads the vehicle's last known GPS position and calculates a driving route to it.
///
/// TESTING: the "current location" is hard-coded to Bandaranaike International Airport.
/// To use the real device location later, replace `origin` with the coordinate from
/// `LocationService` (the rest of this file does not change).
@MainActor
final class VehicleNavigationViewModel: ObservableObject {

    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    // MARK: Test origin
    static let originName = "Bandaranaike Airport"
    static let origin = CLLocationCoordinate2D(latitude: 7.1802, longitude: 79.8839)

    /// TESTING: the GPS API only knows the sample vehicles (QR-001 … QR-003).
    /// Stats page uses QR-001 too (see `TelemetryRepository`). Replace with the
    /// booking's real GPS id once bookings are linked to GPS devices.
    static let gpsVehicleId = "QR-001"

    // MARK: Published state
    @Published private(set) var state: LoadState = .idle
    @Published private(set) var position: GPSAPIPosition?
    @Published private(set) var route: MKRoute?
    @Published private(set) var isRouting = false

    var vehicleCoordinate: CLLocationCoordinate2D? {
        guard let p = position else { return nil }
        return CLLocationCoordinate2D(latitude: p.latitude, longitude: p.longitude)
    }

    /// Road distance when a route exists, otherwise straight-line distance.
    var distanceMeters: CLLocationDistance? {
        if let route { return route.distance }
        guard let v = vehicleCoordinate else { return nil }
        let a = CLLocation(latitude: Self.origin.latitude, longitude: Self.origin.longitude)
        let b = CLLocation(latitude: v.latitude, longitude: v.longitude)
        return a.distance(from: b)
    }

    var travelTime: TimeInterval? { route?.expectedTravelTime }
    var isRouteEstimate: Bool { route == nil && position != nil }

    // MARK: Loading
    func load() async {
        state = .loading
        route = nil
        do {
            position = try await TelemetryAPIClient.shared.fetchPosition(vehicleId: Self.gpsVehicleId)
            state = .loaded
            await calculateRoute()
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    /// Driving route from the (test) origin to the vehicle. On failure the screen keeps
    /// working and draws a dashed straight line instead.
    func calculateRoute() async {
        guard let destination = vehicleCoordinate else { return }
        isRouting = true
        defer { isRouting = false }

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: Self.origin))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = .automobile

        do {
            let response = try await MKDirections(request: request).calculate()
            route = response.routes.first
        } catch {
            route = nil
        }
    }

    // MARK: External maps
    /// Google Maps: app if installed, otherwise the documented universal URL (opens browser / app).
    func openGoogleMaps() {
        guard let dest = vehicleCoordinate else { return }
        let o = Self.origin

        if let appURL = URL(string:
            "comgooglemaps://?saddr=\(o.latitude),\(o.longitude)&daddr=\(dest.latitude),\(dest.longitude)&directionsmode=driving"),
           UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL)
            return
        }

        if let webURL = URL(string:
            "https://www.google.com/maps/dir/?api=1&origin=\(o.latitude),\(o.longitude)&destination=\(dest.latitude),\(dest.longitude)&travelmode=driving") {
            UIApplication.shared.open(webURL)
        }
    }

    func openAppleMaps(vehicleName: String) {
        guard let dest = vehicleCoordinate else { return }
        let from = MKMapItem(placemark: MKPlacemark(coordinate: Self.origin))
        from.name = Self.originName
        let to = MKMapItem(placemark: MKPlacemark(coordinate: dest))
        to.name = "\(vehicleName) – last known location"
        MKMapItem.openMaps(
            with: [from, to],
            launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
        )
    }
}

// MARK: - Navigation Screen (opened from an ongoing booking)
struct VehicleNavigationView: View {
    let booking: Booking
    @StateObject private var viewModel = VehicleNavigationViewModel()
    @State private var camera: MapCameraPosition = .automatic

    var body: some View {
        ScrollView {
            VStack(spacing: .spacingM) {
                mapCard
                infoCard
                actionButtons

                NavigationLink {
                    BookingDetailView(booking: booking)
                } label: {
                    Label("Booking details", systemImage: "doc.text")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.fallbackBlue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, .spacingS)
                }
            }
            .padding(.horizontal, .spacingM)
            .padding(.top, .spacingM)
            .padding(.bottom, .spacingXXL)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Find My Vehicle")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await viewModel.load() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(viewModel.state == .loading)
            }
        }
        .task { await viewModel.load() }
    }

    // MARK: Map
    private var mapCard: some View {
        ZStack {
            Map(position: $camera) {
                Marker(VehicleNavigationViewModel.originName,
                       systemImage: "airplane",
                       coordinate: VehicleNavigationViewModel.origin)
                    .tint(.orange)

                if let dest = viewModel.vehicleCoordinate {
                    Marker(booking.vehicleName, systemImage: "car.fill", coordinate: dest)
                        .tint(.green)

                    if let route = viewModel.route {
                        MapPolyline(route.polyline)
                            .stroke(Color.fallbackBlue, lineWidth: 5)
                    } else {
                        MapPolyline(coordinates: [VehicleNavigationViewModel.origin, dest])
                            .stroke(Color.fallbackBlue.opacity(0.6),
                                    style: StrokeStyle(lineWidth: 4, dash: [8, 6]))
                    }
                }
            }
            .mapStyle(.standard)

            if viewModel.state == .loading {
                ProgressView("Finding vehicle…")
                    .padding(.spacingM)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .frame(height: 280)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)
        .onChange(of: viewModel.vehicleCoordinate?.latitude) { _, _ in fitCamera() }
        .onChange(of: viewModel.route?.polyline.pointCount) { _, _ in fitCamera() }
    }

    /// Zooms the map so the origin, the vehicle and the route are all visible.
    private func fitCamera() {
        guard let dest = viewModel.vehicleCoordinate else { return }
        var rect = MKMapRect.null
        for coord in [VehicleNavigationViewModel.origin, dest] {
            let p = MKMapPoint(coord)
            rect = rect.union(MKMapRect(x: p.x, y: p.y, width: 0, height: 0))
        }
        if let route = viewModel.route {
            rect = rect.union(route.polyline.boundingMapRect)
        }
        let padded = rect.insetBy(dx: -rect.size.width * 0.25 - 2000,
                                  dy: -rect.size.height * 0.25 - 2000)
        camera = .rect(padded)
    }

    // MARK: Info
    @ViewBuilder
    private var infoCard: some View {
        VStack(alignment: .leading, spacing: .spacingM) {
            switch viewModel.state {
            case .failed(let message):
                HStack(alignment: .top, spacing: .spacingS) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Vehicle location unavailable")
                            .font(.subheadline.bold())
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Button("Try again") { Task { await viewModel.load() } }
                    .font(.subheadline.bold())

            default:
                routeRow(icon: "airplane", color: .orange,
                         title: "From (test location)",
                         value: VehicleNavigationViewModel.originName)
                routeRow(icon: "car.fill", color: .green,
                         title: "To (\(booking.vehicleName))",
                         value: viewModel.position == nil ? "Locating…" : "Last known GPS location")

                if viewModel.position != nil {
                    Divider()
                    HStack(spacing: .spacingL) {
                        stat(title: "Distance",
                             value: viewModel.distanceMeters.map(Self.formatDistance) ?? "—",
                             note: viewModel.isRouteEstimate ? "straight line" : nil)
                        stat(title: "Drive time",
                             value: viewModel.travelTime.map(Self.formatDuration) ?? "—",
                             note: nil)
                        stat(title: "Vehicle",
                             value: vehicleStateText,
                             note: nil)
                    }
                    if let p = viewModel.position {
                        Label("Last seen \(p.timestamp.displayDateTime)", systemImage: "clock")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if viewModel.isRouteEstimate && !viewModel.isRouting {
                        Label("Road route not available – showing a straight line.",
                              systemImage: "info.circle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.spacingM)
        .cardStyle()
    }

    private var vehicleStateText: String {
        guard let p = viewModel.position else { return "—" }
        if let speed = p.speedKmh, speed > 1 { return "Moving" }
        return p.engineOn ? "Idling" : "Parked"
    }

    private func routeRow(icon: String, color: Color, title: String, value: String) -> some View {
        HStack(spacing: .spacingM) {
            Image(systemName: icon)
                .frame(width: 28, height: 28)
                .foregroundStyle(color)
                .background(color.opacity(0.12))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.caption).foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.fallbackNavy)
            }
            Spacer()
        }
    }

    private func stat(title: String, value: String, note: String?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(Color.fallbackNavy)
            if let note {
                Text(note).font(.caption2).foregroundStyle(.secondary)
            }
        }
    }

    // MARK: Buttons
    @ViewBuilder
    private var actionButtons: some View {
        let enabled = viewModel.vehicleCoordinate != nil
        VStack(spacing: .spacingS) {
            Button {
                viewModel.openGoogleMaps()
            } label: {
                Label("Navigate with Google Maps", systemImage: "location.north.line.fill")
                    .primaryButtonStyle()
            }
            .disabled(!enabled)
            .opacity(enabled ? 1 : 0.5)

            Button {
                viewModel.openAppleMaps(vehicleName: booking.vehicleName)
            } label: {
                Label("Open in Apple Maps", systemImage: "map")
                    .secondaryButtonStyle()
            }
            .disabled(!enabled)
            .opacity(enabled ? 1 : 0.5)
        }
    }

    // MARK: Formatting
    private static func formatDistance(_ meters: CLLocationDistance) -> String {
        meters < 1000
            ? String(format: "%.0f m", meters)
            : String(format: "%.1f km", meters / 1000)
    }

    private static func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int((seconds / 60).rounded())
        if minutes < 60 { return "\(max(1, minutes)) min" }
        return "\(minutes / 60) h \(minutes % 60) min"
    }
}
