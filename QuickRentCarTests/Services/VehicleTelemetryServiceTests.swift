import XCTest
@testable import QuickRentCar

final class VehicleTelemetryServiceTests: XCTestCase {

    private func makeTelemetry(trips: [TelemetryTrip], allowanceKm: Double = 500.0) -> VehicleTelemetry {
        VehicleTelemetry(
            schemaVersion: "1.0",
            vehicleId: "V-TEST-001",
            rentalId: "R-TEST-001",
            dataSource: "Test",
            geographicalScope: "LK",
            samplingIntervalSeconds: 10,
            packageAllowanceKm: allowanceKm,
            rentalReturnDate: Date().adding(days: 5),
            trips: trips,
            lastKnownLocation: TelemetryLocation(latitude: 6.9271, longitude: 79.8612, timestamp: Date())
        )
    }

    func testDistance_withEmptyOrSinglePoint_returnsZero() {
        let telemetry = makeTelemetry(trips: [])
        let interval = DateInterval(start: Date().adding(days: -1), duration: 86400 * 2)

        let stats = VehicleTelemetryService.shared.calculateStats(for: interval, telemetry: telemetry)

        XCTAssertEqual(stats.totalDistanceKm, 0.0)
        XCTAssertEqual(stats.tripCount, 0)
        XCTAssertEqual(stats.maxSpeedKmh, 0.0)
    }

    func testCalculateStats_withNoTripsIntersecting_returnsZeroStats() {
        let tripStart = Date().adding(days: -10)
        let tripEnd = tripStart.addingTimeInterval(3600)
        let trip = TelemetryTrip(
            tripId: "t-1",
            startTime: tripStart,
            endTime: tripEnd,
            startReason: nil,
            endReason: nil,
            startLocationLabel: nil,
            endLocationLabel: nil,
            routeTemplate: nil,
            distanceKmApprox: 10.0,
            points: [
                TelemetryPoint(timestamp: tripStart, latitude: 6.9271, longitude: 79.8612, speedKmh: 40.0, engineOn: true),
                TelemetryPoint(timestamp: tripEnd, latitude: 6.9371, longitude: 79.8712, speedKmh: 60.0, engineOn: true)
            ]
        )
        let telemetry = makeTelemetry(trips: [trip])

        let interval = DateInterval(start: Date().startOfDay, duration: 86400)
        let stats = VehicleTelemetryService.shared.calculateStats(for: interval, telemetry: telemetry)

        XCTAssertEqual(stats.tripCount, 0)
        XCTAssertEqual(stats.totalDistanceKm, 0)
    }

    func testCalculateStats_filtersPointsInsideInterval_calculatesCorrectMetrics() {
        let now = Date()
        let p1 = TelemetryPoint(timestamp: now, latitude: 6.9271, longitude: 79.8612, speedKmh: 40.0, engineOn: true)
        let p2 = TelemetryPoint(timestamp: now.addingTimeInterval(1800), latitude: 6.9500, longitude: 79.8800, speedKmh: 80.0, engineOn: true)

        let trip = TelemetryTrip(
            tripId: "t-active",
            startTime: now,
            endTime: now.addingTimeInterval(1800),
            startReason: nil,
            endReason: nil,
            startLocationLabel: nil,
            endLocationLabel: nil,
            routeTemplate: nil,
            distanceKmApprox: nil,
            points: [p1, p2]
        )
        let telemetry = makeTelemetry(trips: [trip])

        let interval = DateInterval(start: now.addingTimeInterval(-60), end: now.addingTimeInterval(3600))
        let stats = VehicleTelemetryService.shared.calculateStats(for: interval, telemetry: telemetry)

        XCTAssertEqual(stats.tripCount, 1)
        XCTAssertEqual(stats.maxSpeedKmh, 80.0)
        XCTAssertGreaterThan(stats.totalDistanceKm, 0.0)
        XCTAssertEqual(stats.drivingTimeSec, 1800.0)
        XCTAssertGreaterThan(stats.averageSpeedKmh, 0.0)
    }

    func testRentalPackageUsage_calculatesUsedRemainingAndPercent() {
        let now = Date()
        let p1 = TelemetryPoint(timestamp: now, latitude: 6.9271, longitude: 79.8612, speedKmh: 50.0, engineOn: true)
        let p2 = TelemetryPoint(timestamp: now.addingTimeInterval(300), latitude: 6.9500, longitude: 79.8700, speedKmh: 50.0, engineOn: true)

        let trip = TelemetryTrip(
            tripId: "t-1",
            startTime: now,
            endTime: now.addingTimeInterval(300),
            startReason: nil,
            endReason: nil,
            startLocationLabel: nil,
            endLocationLabel: nil,
            routeTemplate: nil,
            distanceKmApprox: 3.0,
            points: [p1, p2]
        )
        let allowance: Double = 100.0
        let telemetry = makeTelemetry(trips: [trip], allowanceKm: allowance)

        let usage = VehicleTelemetryService.shared.rentalPackageUsage(telemetry: telemetry)

        XCTAssertGreaterThan(usage.usedKm, 0.0)
        XCTAssertEqual(usage.remainingKm, allowance - usage.usedKm, accuracy: 0.01)
        XCTAssertEqual(usage.percentUsed, (usage.usedKm / allowance) * 100, accuracy: 0.01)
    }

    func testRentalPackageUsage_whenExceedsAllowance_clampsRemainingToZero() {
        let now = Date()
        let p1 = TelemetryPoint(timestamp: now, latitude: 6.9271, longitude: 79.8612, speedKmh: 50.0, engineOn: true)
        let p2 = TelemetryPoint(timestamp: now.addingTimeInterval(300), latitude: 7.2000, longitude: 80.1000, speedKmh: 50.0, engineOn: true)

        let trip = TelemetryTrip(
            tripId: "t-long",
            startTime: now,
            endTime: now.addingTimeInterval(300),
            startReason: nil,
            endReason: nil,
            startLocationLabel: nil,
            endLocationLabel: nil,
            routeTemplate: nil,
            distanceKmApprox: 50.0,
            points: [p1, p2]
        )
        let allowance: Double = 1.0
        let telemetry = makeTelemetry(trips: [trip], allowanceKm: allowance)

        let usage = VehicleTelemetryService.shared.rentalPackageUsage(telemetry: telemetry)

        XCTAssertEqual(usage.remainingKm, 0.0, "Remaining package allowance should clamp to 0 when exceeded")
        XCTAssertGreaterThan(usage.percentUsed, 100.0)
    }
}
