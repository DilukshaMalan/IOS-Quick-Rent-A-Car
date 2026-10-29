import XCTest
@testable import QuickRentCar

final class TelemetryDecodingTests: XCTestCase {

    func testTelemetryDecoder_decodesISO8601WithTimezoneOffset() throws {
        let json = """
        {
            "schemaVersion": "1.0",
            "vehicleId": "QR-001",
            "rentalId": "RENT-001",
            "dataSource": "seed",
            "geographicalScope": "Colombo",
            "samplingIntervalSeconds": 15,
            "packageAllowanceKm": 500,
            "rentalReturnDate": "2026-10-23T23:59:59+05:30",
            "trips": [],
            "lastKnownLocation": {
                "latitude": 6.9271,
                "longitude": 79.8612,
                "timestamp": "2026-10-20T14:30:00+05:30"
            }
        }
        """.data(using: .utf8)!

        let telemetry = try JSONDecoder.telemetryDecoder.decode(VehicleTelemetry.self, from: json)

        XCTAssertEqual(telemetry.vehicleId, "QR-001")
        XCTAssertEqual(telemetry.rentalId, "RENT-001")
        XCTAssertEqual(telemetry.packageAllowanceKm, 500.0)
        XCTAssertEqual(telemetry.lastKnownLocation.latitude, 6.9271, accuracy: 0.0001)
    }

    func testVehicleTelemetry_fromAPI_convertsGPSAPITripsResponse() {
        let now = Date()
        let apiPoint = GPSAPIPoint(timestamp: now, latitude: 6.9271, longitude: 79.8612, speedKmh: 45.0, engineOn: true)
        let apiTrip = GPSAPITrip(
            tripId: "api-trip-1",
            startTime: now,
            endTime: now.addingTimeInterval(900),
            startReason: "Ignition",
            endReason: "IgnitionOff",
            distanceKm: 5.2,
            maxSpeedKmh: 60.0,
            averageSpeedKmh: 40.0,
            points: [apiPoint]
        )
        let meta = GPSAPITripsMeta(
            dataSource: "GPS-API",
            samplingIntervalSeconds: 10,
            tripCount: 1,
            pointCount: 1,
            effectiveIntervalSeconds: 10
        )
        let response = GPSAPITripsResponse(
            vehicleId: "V-999",
            meta: meta,
            trips: [apiTrip]
        )

        let telemetry = VehicleTelemetry.fromAPI(response: response, rentalId: "R-CUSTOM", packageAllowanceKm: 600)

        XCTAssertEqual(telemetry.vehicleId, "V-999")
        XCTAssertEqual(telemetry.rentalId, "R-CUSTOM")
        XCTAssertEqual(telemetry.packageAllowanceKm, 600)
        XCTAssertEqual(telemetry.trips.count, 1)
        XCTAssertEqual(telemetry.trips.first?.tripId, "api-trip-1")
        XCTAssertEqual(telemetry.trips.first?.points.count, 1)
    }

    func testVehicleTelemetry_derivesLastKnownLocationFromNewestPoint() {
        let t1 = Date().addingTimeInterval(-1000)
        let t2 = Date() // newer
        let p1 = GPSAPIPoint(timestamp: t1, latitude: 6.9000, longitude: 79.8000, speedKmh: 30.0, engineOn: true)
        let p2 = GPSAPIPoint(timestamp: t2, latitude: 7.0000, longitude: 79.9000, speedKmh: 50.0, engineOn: true)

        let apiTrip = GPSAPITrip(
            tripId: "trip-points",
            startTime: t1,
            endTime: t2,
            startReason: "Start",
            endReason: nil,
            distanceKm: 12.0,
            maxSpeedKmh: 50.0,
            averageSpeedKmh: 40.0,
            points: [p1, p2]
        )
        let response = GPSAPITripsResponse(
            vehicleId: "V-DERIVE",
            meta: GPSAPITripsMeta(dataSource: "Test", samplingIntervalSeconds: 5, tripCount: 1, pointCount: 2, effectiveIntervalSeconds: nil),
            trips: [apiTrip]
        )

        let telemetry = VehicleTelemetry.fromAPI(response: response)

        XCTAssertEqual(telemetry.lastKnownLocation.latitude, 7.0000, accuracy: 0.0001)
        XCTAssertEqual(telemetry.lastKnownLocation.longitude, 79.9000, accuracy: 0.0001)
        XCTAssertEqual(telemetry.lastKnownLocation.timestamp, t2)
    }

    func testVehicleTelemetry_whenTripsHaveNoPoints_handlesSafely() {
        let response = GPSAPITripsResponse(
            vehicleId: "V-EMPTY",
            meta: GPSAPITripsMeta(dataSource: "Test", samplingIntervalSeconds: 10, tripCount: 0, pointCount: 0, effectiveIntervalSeconds: nil),
            trips: []
        )

        let telemetry = VehicleTelemetry.fromAPI(response: response)

        XCTAssertEqual(telemetry.trips.count, 0)
        XCTAssertEqual(telemetry.lastKnownLocation.latitude, 0.0)
        XCTAssertEqual(telemetry.lastKnownLocation.longitude, 0.0)
    }
}
