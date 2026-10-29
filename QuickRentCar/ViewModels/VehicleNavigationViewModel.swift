import SwiftUI
import MapKit

// MARK: - Navigation ViewModel
/// Loads the vehicle's last known GPS position and works out a road route to it.
///
/// TESTING: the "current location" is hard-coded to Bandaranaike International Airport.
/// To use the real device location later, replace `origin` with the coordinate from
/// `LocationService` (the rest of the screen does not change).
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
    /// The road route (follows the roads). `nil` while loading or if no routing source worked.
    @Published private(set) var route: DrivingRoute?
    /// Why the road route could not be found (one line per routing source that failed).
    @Published private(set) var routeProblems: [String] = []
    @Published private(set) var isRouting = false

    private var routeRequestID = 0

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

    var travelTime: TimeInterval? { route?.duration }

    /// True when only the straight-line estimate is available.
    var isRouteEstimate: Bool { route == nil && position != nil }

    // MARK: Loading
    func load() async {
        state = .loading
        route = nil
        routeProblems = []
        do {
            position = try await TelemetryAPIClient.shared.fetchPosition(vehicleId: Self.gpsVehicleId)
            state = .loaded
        } catch {
            state = .failed(error.localizedDescription)
            return
        }
        await calculateRoute()
    }

    /// Road route from the (test) origin to the vehicle. If no routing source works, the screen
    /// keeps working and draws a dashed straight line instead.
    func calculateRoute() async {
        guard let destination = vehicleCoordinate else { return }

        routeRequestID += 1
        let requestID = routeRequestID
        isRouting = true

        let outcome = await RoadRouteService.shared.route(from: Self.origin, to: destination)

        guard requestID == routeRequestID else { return }   // a newer request has started
        route = outcome.route
        routeProblems = outcome.problems
        isRouting = false
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
