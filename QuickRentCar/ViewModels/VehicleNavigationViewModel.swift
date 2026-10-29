import SwiftUI
import MapKit
import Combine

@MainActor
final class VehicleNavigationViewModel: ObservableObject {

    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    static let fallbackOriginName = "Bandaranaike Airport"
    static let fallbackOrigin = CLLocationCoordinate2D(latitude: 7.1802, longitude: 79.8839)

    static let originName = fallbackOriginName
    static let origin = fallbackOrigin

    static let gpsVehicleId = "QR-001"

    @Published private(set) var state: LoadState = .idle
    @Published private(set) var position: GPSAPIPosition?
    @Published private(set) var route: DrivingRoute?
    @Published private(set) var routeProblems: [String] = []
    @Published private(set) var isRouting = false
    @Published private(set) var userLocation: CLLocation?
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined

    let locationManager = DeviceLocationManager()
    private var cancellables = Set<AnyCancellable>()
    private var routeRequestID = 0
    private var lastRoutedCoordinate: CLLocationCoordinate2D?

    init() {
        locationManager.$location
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newLocation in
                self?.userLocation = newLocation
                self?.handleLocationUpdate(newLocation)
            }
            .store(in: &cancellables)

        locationManager.$authorizationStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.authorizationStatus = status
            }
            .store(in: &cancellables)
    }

    var originCoordinate: CLLocationCoordinate2D {
        userLocation?.coordinate ?? Self.fallbackOrigin
    }

    var originName: String {
        userLocation != nil ? "Current Location" : Self.fallbackOriginName
    }

    var isUsingCurrentLocation: Bool {
        userLocation != nil
    }

    var vehicleCoordinate: CLLocationCoordinate2D? {
        guard let p = position else { return nil }
        return CLLocationCoordinate2D(latitude: p.latitude, longitude: p.longitude)
    }

    var distanceMeters: CLLocationDistance? {
        if let route { return route.distance }
        guard let v = vehicleCoordinate else { return nil }
        let a = CLLocation(latitude: originCoordinate.latitude, longitude: originCoordinate.longitude)
        let b = CLLocation(latitude: v.latitude, longitude: v.longitude)
        return a.distance(from: b)
    }

    var travelTime: TimeInterval? { route?.duration }

    var isRouteEstimate: Bool { route == nil && position != nil }

    func startLocationUpdates() {
        locationManager.requestLocationUpdates()
    }

    func stopLocationUpdates() {
        locationManager.stopLocationUpdates()
    }

    func load() async {
        startLocationUpdates()
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

    private func handleLocationUpdate(_ location: CLLocation?) {
        guard let location = location, vehicleCoordinate != nil else { return }
        if let last = lastRoutedCoordinate {
            let lastLoc = CLLocation(latitude: last.latitude, longitude: last.longitude)
            if lastLoc.distance(from: location) < 30 && route != nil {
                return
            }
        }
        lastRoutedCoordinate = location.coordinate
        Task { [weak self] in
            await self?.calculateRoute()
        }
    }

    func calculateRoute() async {
        guard let destination = vehicleCoordinate else { return }

        routeRequestID += 1
        let requestID = routeRequestID
        isRouting = true

        let outcome = await RoadRouteService.shared.route(from: originCoordinate, to: destination)

        guard requestID == routeRequestID else { return }
        route = outcome.route
        routeProblems = outcome.problems
        isRouting = false
    }

    func openGoogleMaps() {
        guard let dest = vehicleCoordinate else { return }
        let o = originCoordinate

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
        let from: MKMapItem
        if isUsingCurrentLocation {
            from = MKMapItem.forCurrentLocation()
        } else {
            from = MKMapItem(placemark: MKPlacemark(coordinate: originCoordinate))
            from.name = originName
        }
        let to = MKMapItem(placemark: MKPlacemark(coordinate: dest))
        to.name = "\(vehicleName) – last known location"
        MKMapItem.openMaps(
            with: [from, to],
            launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
        )
    }
}
