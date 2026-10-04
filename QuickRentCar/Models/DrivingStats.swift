import Foundation

struct DrivingStats: Codable {
    var bookingId: String
    var userId: String
    var date: Date
    var totalDistanceKm: Double
    var dailyDistances: [DailyDistance]
    var averageSpeedKmh: Double
    var maxSpeedKmh: Double
    var includedMileageKm: Int
    var usedMileageKm: Double

    var remainingMileageKm: Double {
        max(0, Double(includedMileageKm) - usedMileageKm)
    }

    var mileageUsagePercent: Double {
        guard includedMileageKm > 0 else { return 0 }
        return min(1.0, usedMileageKm / Double(includedMileageKm))
    }
}

struct DailyDistance: Identifiable, Codable {
    var id = UUID()
    var date: Date
    var distanceKm: Double
    var period: StatPeriod

    enum StatPeriod: String, Codable, CaseIterable {
        case daily = "Daily"
        case weekly = "Weekly"
        case monthly = "Monthly"
    }
}
