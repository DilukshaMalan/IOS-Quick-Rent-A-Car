import SwiftUI
import MapKit

@MainActor
final class VehicleNavigationViewModel: ObservableObject {

    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    static let originName = "Bandaranaike Airport"
    static let origin = CLLocationCoordinate2D(latitude: 7.1802, longitude: 79.8839)

    static let gpsVehicleId = "QR-001"

    @Published private(set) var state: LoadState = .idle
    @Published private(set) var position: GPSAPIPosition?
    @Published private(set) var route: DrivingRoute?
    @Published private(set) var routeProblems: [String] = []
    @Published private(set) var isRouting = false

    private var routeRequestID = 0

    var vehicleCoordinate: CLLocationCoordinate2D? {
        guard let p = position else { return nil }
        return CLLocationCoordinate2D(latitude: p.latitude, longitude: p.longitude)
    }

    var distanceMeters: CLLocationDistance? {
        if let route { return route.distance }
        guard let v = vehicleCoordinate else { return nil }
        let a = CLLocation(latitude: Self.origin.latitude, longitude: Self.origin.longitude)
        let b = CLLocation(latitude: v.latitude, longitude: v.longitude)
        return a.distance(from: b)
    }

    var travelTime: TimeInterval? { route?.duration }

    var isRouteEstimate: Bool { route == nil && position != nil }

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

    func calculateRoute() async {
        guard let destination = vehicleCoordinate else { return }

        routeRequestID += 1
        let requestID = routeRequestID
        isRouting = true

        let outcome = await RoadRouteService.shared.route(from: Self.origin, to: destination)

        guard requestID == routeRequestID else { return }
        route = outcome.route
        routeProblems = outcome.problems
        isRouting = false
    }

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
