// MARK: - Telemetry Models
import Foundation

// Top-level JSON structure.
// NOTE: `tripDetectionAssumption` and `routeGeometry` are objects in the seed JSON and the app
// never reads them, so they are intentionally NOT declared here. Swift's Codable ignores
// JSON keys that have no matching property.
struct VehicleTelemetry: Codable {
    let schemaVersion: String
    let vehicleId: String
    let rentalId: String
    let dataSource: String
    let geographicalScope: String
    let samplingIntervalSeconds: Int
    let packageAllowanceKm: Double
    let rentalReturnDate: Date
    let trips: [TelemetryTrip]
    let lastKnownLocation: TelemetryLocation
}

struct TelemetryTrip: Codable {
    let tripId: String
    let startTime: Date
    let endTime: Date
    let startReason: String?
    let endReason: String?
    let startLocationLabel: String?
    let endLocationLabel: String?
    let routeTemplate: String?
    let distanceKmApprox: Double?
    let points: [TelemetryPoint]
}

struct TelemetryPoint: Codable {
    let timestamp: Date
    let latitude: Double
    let longitude: Double
    let speedKmh: Double?
    let engineOn: Bool
}

struct TelemetryLocation: Codable, Identifiable {
    let latitude: Double
    let longitude: Double
    let timestamp: Date
    var id: String { "\(latitude)-\(longitude)-\(timestamp.timeIntervalSince1970)" }
}

// Helper for date decoding. The seed file uses plain ISO8601 with an offset
// (e.g. 2026-10-14T07:30:00+05:30) and no fractional seconds, which `.iso8601` handles.
extension JSONDecoder {
    static var telemetryDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
