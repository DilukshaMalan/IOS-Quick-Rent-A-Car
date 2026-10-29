import Foundation

final class TelemetryRepository {
    static let shared = TelemetryRepository()
    private init() {}

    private let sampleVehicleId = "QR-001"
    private let sampleRentalId  = "QR001-TRIP-001"

    private let dataWindowStart: Date = {
        var comps = DateComponents()
        comps.year = 2026; comps.month = 10; comps.day = 10
        comps.hour = 0;    comps.minute = 0; comps.second = 0
        return Calendar(identifier: .gregorian).date(from: comps)!
    }()

    private let dataWindowEnd: Date = {
        var comps = DateComponents()
        comps.year = 2026; comps.month = 10; comps.day = 23
        comps.hour = 23;   comps.minute = 59; comps.second = 59
        return Calendar(identifier: .gregorian).date(from: comps)!
    }()

    func loadTelemetry() async throws -> VehicleTelemetry {
        print("🚗 [TelemetryRepository] Loading telemetry from API for vehicle: \(sampleVehicleId)")
        print("📅 [TelemetryRepository] Query window: \(dataWindowStart) → \(dataWindowEnd)")

        let response = try await TelemetryAPIClient.shared.fetchTrips(
            vehicleId: sampleVehicleId,
            from: dataWindowStart,
            to: dataWindowEnd,
            includePoints: true,
            maxPoints: 5000
        )

        print("✅ [TelemetryRepository] API returned \(response.trips.count) trips, source: \(response.meta.dataSource)")

        return VehicleTelemetry.fromAPI(response: response, rentalId: sampleRentalId)
    }
}
