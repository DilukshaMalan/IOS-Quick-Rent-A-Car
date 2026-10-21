// MARK: - Telemetry Models
import Foundation

// Top‑level JSON structure
struct VehicleTelemetry: Codable {
    let schemaVersion: String
    let vehicleId: String
    let rentalId: String
    let dataSource: String
    let geographicalScope: String
    let samplingIntervalSeconds: Int
    let tripDetectionAssumption: String
    let routeGeometry: String?
    let packageAllowanceKm: Double
    let rentalReturnDate: Date
    let trips: [TelemetryTrip]
    let lastKnownLocation: TelemetryLocation

    enum CodingKeys: String, CodingKey {
        case schemaVersion, vehicleId, rentalId, dataSource, geographicalScope,
             samplingIntervalSeconds, tripDetectionAssumption, routeGeometry,
             packageAllowanceKm, rentalReturnDate, trips, lastKnownLocation
    }
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

// Helper for date decoding (ISO8601 with fractional seconds)
extension JSONDecoder {
    static var telemetryDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
