import SwiftUI
import MapKit

struct VehicleNavigationView: View {
    let booking: Booking
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = VehicleNavigationViewModel()
    @State private var camera: MapCameraPosition = .automatic

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

                Text("Find My Vehicle")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.fallbackNavy)

                Spacer()

                Button {
                    Task { await viewModel.load() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.fallbackNavy)
                        .frame(width: 36, height: 36)
                        .background(Color.gray.opacity(0.09))
                        .clipShape(Circle())
                }
                .disabled(viewModel.state == .loading || viewModel.isRouting)
            }
            .padding(.horizontal, .spacingM)
            .padding(.top, .spacingS)
            .padding(.bottom, .spacingS)
            .background(Color(UIColor.systemGroupedBackground))

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
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .task { await viewModel.load() }
        .onDisappear { viewModel.stopLocationUpdates() }
    }

    private var mapCard: some View {
        ZStack(alignment: .bottom) {
            Map(position: $camera) {
                Marker(viewModel.originName,
                       systemImage: viewModel.isUsingCurrentLocation ? "location.fill" : "airplane",
                       coordinate: viewModel.originCoordinate)
                    .tint(viewModel.isUsingCurrentLocation ? .blue : .orange)

                if let dest = viewModel.vehicleCoordinate {
                    Marker(booking.vehicleName, systemImage: "car.fill", coordinate: dest)
                        .tint(.green)

                    if let route = viewModel.route {
                        MapPolyline(coordinates: route.coordinates)
                            .stroke(.white, lineWidth: 9)
                        MapPolyline(coordinates: route.coordinates)
                            .stroke(Color.fallbackBlue, lineWidth: 5)
                    } else if !viewModel.isRouting {
                        MapPolyline(coordinates: [viewModel.originCoordinate, dest])
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
                    .frame(maxHeight: .infinity)
            } else if viewModel.isRouting {
                Label("Finding road route…", systemImage: "arrow.triangle.turn.up.right.diamond")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, .spacingM)
                    .padding(.vertical, .spacingS)
                    .background(.regularMaterial)
                    .clipShape(Capsule())
                    .padding(.bottom, .spacingS)
            }
        }
        .frame(height: 280)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)
        .onChange(of: viewModel.vehicleCoordinate?.latitude) { _, _ in fitCamera() }
        .onChange(of: viewModel.originCoordinate.latitude) { _, _ in fitCamera() }
        .onChange(of: viewModel.route?.coordinates.count) { _, _ in fitCamera() }
    }

    private func fitCamera() {
        guard let dest = viewModel.vehicleCoordinate else { return }
        var rect = MKMapRect.null
        for coord in [viewModel.originCoordinate, dest] {
            let p = MKMapPoint(coord)
            rect = rect.union(MKMapRect(x: p.x, y: p.y, width: 0, height: 0))
        }
        if let route = viewModel.route {
            rect = rect.union(route.boundingMapRect)
        }
        let padded = rect.insetBy(dx: -rect.size.width * 0.25 - 2000,
                                  dy: -rect.size.height * 0.25 - 2000)
        camera = .rect(padded)
    }

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
                routeRow(icon: viewModel.isUsingCurrentLocation ? "location.fill" : "airplane",
                         color: viewModel.isUsingCurrentLocation ? .blue : .orange,
                         title: viewModel.isUsingCurrentLocation ? "From" : "From (default location)",
                         value: viewModel.originName)
                routeRow(icon: "car.fill", color: .green,
                         title: "To (\(booking.vehicleName))",
                         value: viewModel.position == nil ? "Locating…" : "Last known GPS location")

                if viewModel.authorizationStatus == .denied || viewModel.authorizationStatus == .restricted {
                    HStack(spacing: .spacingS) {
                        Image(systemName: "location.slash.fill")
                            .foregroundStyle(.orange)
                        Text("Location access is disabled. Using default location.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            Button("Settings") {
                                UIApplication.shared.open(url)
                            }
                            .font(.caption.bold())
                        }
                    }
                    .padding(.vertical, 2)
                }

                if viewModel.position != nil {
                    Divider()
                    HStack(spacing: .spacingL) {
                        stat(title: "Distance",
                             value: viewModel.distanceMeters.map(Self.formatDistance) ?? "—",
                             note: viewModel.isRouteEstimate ? "straight line" : "by road")
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
                    if let route = viewModel.route {
                        Label("Route via \(route.source.rawValue)", systemImage: "road.lanes")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if viewModel.isRouteEstimate && !viewModel.isRouting {
                        routeFailureNote
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.spacingM)
        .cardStyle()
    }

    private var routeFailureNote: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Road route not available – showing a straight line.",
                  systemImage: "info.circle")
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(viewModel.routeProblems, id: \.self) { problem in
                Text(problem)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Button("Retry route") { Task { await viewModel.calculateRoute() } }
                .font(.caption.bold())
        }
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
