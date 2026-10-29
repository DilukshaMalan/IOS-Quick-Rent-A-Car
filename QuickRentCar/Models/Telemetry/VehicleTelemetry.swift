import Foundation

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

extension JSONDecoder {
    static var telemetryDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

extension VehicleTelemetry {

    static func fromAPI(
        response: GPSAPITripsResponse,
        rentalId: String = "QR001-TRIP-001",
        packageAllowanceKm: Double = 500,
        rentalReturnDate: Date = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
    ) -> VehicleTelemetry {

        let trips: [TelemetryTrip] = response.trips.map { apiTrip in
            let points: [TelemetryPoint] = (apiTrip.points ?? []).map { pt in
                TelemetryPoint(
                    timestamp: pt.timestamp,
                    latitude: pt.latitude,
                    longitude: pt.longitude,
                    speedKmh: pt.speedKmh,
                    engineOn: pt.engineOn
                )
            }
            return TelemetryTrip(
                tripId: apiTrip.tripId,
                startTime: apiTrip.startTime,
                endTime: apiTrip.endTime,
                startReason: apiTrip.startReason,
                endReason: apiTrip.endReason,
                startLocationLabel: nil,
                endLocationLabel: nil,
                routeTemplate: nil,
                distanceKmApprox: apiTrip.distanceKm,
                points: points
            )
        }

        let allPoints = trips.flatMap { $0.points }
        let newest = allPoints.max(by: { $0.timestamp < $1.timestamp })
        let lastKnown = TelemetryLocation(
            latitude: newest?.latitude ?? 0,
            longitude: newest?.longitude ?? 0,
            timestamp: newest?.timestamp ?? Date()
        )

        return VehicleTelemetry(
            schemaVersion: "1.0",
            vehicleId: response.vehicleId,
            rentalId: rentalId,
            dataSource: response.meta.dataSource,
            geographicalScope: "API",
            samplingIntervalSeconds: response.meta.samplingIntervalSeconds,
            packageAllowanceKm: packageAllowanceKm,
            rentalReturnDate: rentalReturnDate,
            trips: trips,
            lastKnownLocation: lastKnown
        )
    }
}
