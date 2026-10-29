import Foundation
import CoreLocation
import Combine

final class DeviceLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {

    @Published private(set) var location: CLLocation?
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var errorMessage: String?

    private let manager = CLLocationManager()

    override init() {
        super.init()

        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 10

        authorizationStatus = manager.authorizationStatus
    }

    func requestLocationUpdates() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()

        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()

        case .denied, .restricted:
            errorMessage = "Enable location access for QuickRentCar in Settings."

        @unknown default:
            errorMessage = "Unable to determine location permission."
        }
    }

    func stopLocationUpdates() {
        manager.stopUpdatingLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus

            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                self.manager.startUpdatingLocation()

            case .denied, .restricted:
                self.errorMessage = "Location permission is disabled. Check Settings."

            case .notDetermined:
                break

            @unknown default:
                self.errorMessage = "Unable to determine location permission."
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latestLocation = locations.last,
              latestLocation.horizontalAccuracy >= 0 else {
            return
        }

        DispatchQueue.main.async {
            self.location = latestLocation
            self.errorMessage = nil
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.errorMessage = error.localizedDescription
        }
    }
}
