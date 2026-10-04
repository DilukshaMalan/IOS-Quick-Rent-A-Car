import Foundation
import CoreLocation

@MainActor
class MapViewModel: ObservableObject {
    @Published var pickupCoordinate: CLLocationCoordinate2D?
    @Published var returnCoordinate: CLLocationCoordinate2D?
    @Published var distanceToPickup: String = "—"
    @Published var distanceToReturn: String = "—"
    @Published var isInPickupZone: Bool = false
    @Published var isInReturnZone: Bool = false

    private let locationService = LocationService.shared

    func setup(pickupCoord: CLLocationCoordinate2D, returnCoord: CLLocationCoordinate2D, bookingId: String) {
        pickupCoordinate = pickupCoord
        returnCoordinate = returnCoord

        locationService.startUpdating()
        locationService.startMonitoringPickupZone(center: pickupCoord, identifier: bookingId)
        locationService.startMonitoringReturnZone(center: returnCoord, identifier: bookingId)
    }

    func updateDistances() {
        if let coord = pickupCoordinate {
            distanceToPickup = locationService.distanceString(to: coord)
        }
        if let coord = returnCoordinate {
            distanceToReturn = locationService.distanceString(to: coord)
        }
        isInPickupZone = locationService.isInPickupZone
        isInReturnZone = locationService.isInReturnZone
    }

    func stopMonitoring() {
        locationService.stopMonitoringAllRegions()
        locationService.stopUpdating()
    }
}
