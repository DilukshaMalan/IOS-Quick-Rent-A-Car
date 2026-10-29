import XCTest
@testable import QuickRentCar

final class DrivingStatsTests: XCTestCase {

    private func makeStats(includedKm: Int, usedKm: Double) -> DrivingStats {
        DrivingStats(
            bookingId: "b-1",
            userId: "u-1",
            date: Date(),
            totalDistanceKm: usedKm,
            dailyDistances: [],
            averageSpeedKmh: 55.0,
            maxSpeedKmh: 95.0,
            includedMileageKm: includedKm,
            usedMileageKm: usedKm
        )
    }

    func testRemainingMileageKm_whenUsageBelowAllowance_calculatesRemaining() {
        let stats = makeStats(includedKm: 500, usedKm: 320.0)
        XCTAssertEqual(stats.remainingMileageKm, 180.0, accuracy: 0.001)
    }

    func testRemainingMileageKm_whenUsageExceedsAllowance_clampsToZero() {
        let stats = makeStats(includedKm: 500, usedKm: 550.0)
        XCTAssertEqual(stats.remainingMileageKm, 0.0, accuracy: 0.001, "Remaining mileage must never be negative")
    }

    func testMileageUsagePercent_calculatesCorrectFraction() {
        let stats = makeStats(includedKm: 500, usedKm: 250.0)
        XCTAssertEqual(stats.mileageUsagePercent, 0.50, accuracy: 0.001)
    }

    func testMileageUsagePercent_whenUsageExceedsAllowance_capsAtOne() {
        let stats = makeStats(includedKm: 500, usedKm: 750.0)
        XCTAssertEqual(stats.mileageUsagePercent, 1.0, accuracy: 0.001, "Usage percent should not exceed 100% (1.0)")
    }

    func testMileageUsagePercent_whenAllowanceIsZero_returnsZeroToAvoidDivideByZero() {
        let stats = makeStats(includedKm: 0, usedKm: 50.0)
        XCTAssertEqual(stats.mileageUsagePercent, 0.0, accuracy: 0.001)
    }
}
