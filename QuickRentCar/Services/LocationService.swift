import Foundation
import CoreLocation

@MainActor
class LocationService: NSObject, ObservableObject {
    static let shared = LocationService()

    private let locationManager = CLLocationManager()

    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isInPickupZone: Bool = false
    @Published var isInReturnZone: Bool = false

    private var pickupRegion: CLCircularRegion?
    private var returnRegion: CLCircularRegion?

    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    // MARK: - Permission
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    // MARK: - Start / Stop Updates
    func startUpdating() {
        locationManager.startUpdatingLocation()
    }

    func stopUpdating() {
        locationManager.stopUpdatingLocation()
    }

    // MARK: - Distance Calculation
    func distanceTo(coordinate: CLLocationCoordinate2D) -> Double? {
        guard let current = currentLocation else { return nil }
        let target = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return current.distance(from: target)  // metres
    }

    func distanceString(to coordinate: CLLocationCoordinate2D) -> String {
        guard let metres = distanceTo(coordinate: coordinate) else { return "—" }
        if metres < 1000 {
            return String(format: "%.0f m", metres)
        } else {
            return String(format: "%.1f km", metres / 1000)
        }
    }

    // MARK: - Geofencing
    func startMonitoringPickupZone(center: CLLocationCoordinate2D, identifier: String) {
        let region = CLCircularRegion(
            center: center,
            radius: Constants.Location.geofenceRadiusMeters,
            identifier: "pickup-\(identifier)"
        )
        region.notifyOnEntry = true
        region.notifyOnExit = false
        pickupRegion = region
        locationManager.startMonitoring(for: region)
    }

    func startMonitoringReturnZone(center: CLLocationCoordinate2D, identifier: String) {
        let region = CLCircularRegion(
            center: center,
            radius: Constants.Location.geofenceRadiusMeters,
            identifier: "return-\(identifier)"
        )
        region.notifyOnEntry = true
        region.notifyOnExit = true
        returnRegion = region
        locationManager.startMonitoring(for: region)
    }

    func stopMonitoringAllRegions() {
        locationManager.monitoredRegions.forEach { locationManager.stopMonitoring(for: $0) }
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            self.currentLocation = locations.last
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
            if manager.authorizationStatus == .authorizedWhenInUse ||
               manager.authorizationStatus == .authorizedAlways {
                manager.startUpdatingLocation()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        Task { @MainActor in
            if region.identifier.hasPrefix("pickup-") { self.isInPickupZone = true }
            if region.identifier.hasPrefix("return-") { self.isInReturnZone = true }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        Task { @MainActor in
            if region.identifier.hasPrefix("return-") { self.isInReturnZone = false }
        }
    }
}
