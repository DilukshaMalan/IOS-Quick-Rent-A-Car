import Foundation

final class TelemetryRepository {
    static let shared = TelemetryRepository()
    private init() {}

    // MARK: - Hardcoded sample IDs (replace with real IDs once rental flow is wired)
    private let sampleVehicleId = "QR-001"
    private let sampleRentalId  = "QR001-TRIP-001"

    // MARK: - Known data window for the sample vehicle
    // The GPS API enforces a maximum 31-day query window.
    // All three sample vehicles (QR-001, QR-002, QR-003) have records from
    // 2026-10-10 to 2026-10-23 – a span of 13 days, well within the limit.
    // When real rental data is wired up, replace these with the actual rental
    // start/end dates so the query always fits inside the 31-day window.
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

    // MARK: - Load telemetry from the GPS API
    /// Fetches all trips for the sample vehicle from the live API (within the known
    /// 13-day data window) and converts them into the `VehicleTelemetry` model that
    /// `VehicleStatsViewModel` already understands.
    ///
    /// The API rejects any request whose window exceeds 31 days (HTTP 400
    /// `range_too_large`). By anchoring `from`/`to` to the actual data dates we
    /// stay well within that limit.
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

        // Convert API response → the existing VehicleTelemetry model.
        return VehicleTelemetry.fromAPI(response: response, rentalId: sampleRentalId)
    }
}

// MARK: - Old local-JSON implementation (kept for offline reference)
//
// func loadTelemetry() async throws -> VehicleTelemetry {
//     let jsonFileName = "QuickRentCar_SeedVehicleTelemetry_JaEla_Colombo"
//     let ext = "json"
//     if let bundleURL = Bundle.main.url(forResource: jsonFileName, withExtension: ext) {
//         let data = try Data(contentsOf: bundleURL)
//         return try JSONDecoder.telemetryDecoder.decode(VehicleTelemetry.self, from: data)
//     }
//     let fallbackPath = "\(FileManager.default.currentDirectoryPath)/QuickRentCar/Utilities/\(jsonFileName).\(ext)"
//     let fallbackURL  = URL(fileURLWithPath: fallbackPath)
//     guard FileManager.default.fileExists(atPath: fallbackURL.path) else {
//         throw NSError(domain: "TelemetryRepository", code: 2,
//                       userInfo: [NSLocalizedDescriptionKey: "Telemetry JSON not found: \(fallbackURL.path)"])
//     }
//     let data = try Data(contentsOf: fallbackURL)
//     return try JSONDecoder.telemetryDecoder.decode(VehicleTelemetry.self, from: data)
// }
