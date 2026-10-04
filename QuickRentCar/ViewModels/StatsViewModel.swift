import Foundation

@MainActor
class StatsViewModel: ObservableObject {
    @Published var selectedPeriod: DailyDistance.StatPeriod = .daily
    @Published var stats: DrivingStats?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let firestoreService = FirestoreService.shared

    var chartData: [DailyDistance] {
        stats?.dailyDistances.filter { $0.period == selectedPeriod } ?? []
    }

    var totalDistance: Double {
        stats?.totalDistanceKm ?? 0
    }

    var averageSpeed: Double {
        stats?.averageSpeedKmh ?? 0
    }

    var maxSpeed: Double {
        stats?.maxSpeedKmh ?? 0
    }

    var usedMileage: Double {
        stats?.usedMileageKm ?? 0
    }

    var includedMileage: Int {
        stats?.includedMileageKm ?? 0
    }

    var mileageUsagePercent: Double {
        stats?.mileageUsagePercent ?? 0
    }

    func loadStats(userId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let statsList = try await firestoreService.fetchStats(userId: userId)
            stats = statsList.first  // Most recent active booking's stats
        } catch {
            errorMessage = error.localizedDescription
            loadSampleStats()
        }

        isLoading = false
    }

    /// Fills `stats` with deterministic sample data. Used when a fetch fails and
    /// when no user is signed in (SwiftUI previews), so `StatsView` has something to show.
    func loadSampleStats() {
        let calendar = Calendar.current
        let today = Date()

        let sampleDistances: [DailyDistance] = (0..<7).map { dayOffset in
            DailyDistance(
                date: calendar.date(byAdding: .day, value: -dayOffset, to: today) ?? today,
                distanceKm: Double.random(in: 20...150),
                period: .daily
            )
        }

        stats = DrivingStats(
            bookingId: "sample",
            userId: "sample",
            date: today,
            totalDistanceKm: 342.5,
            dailyDistances: sampleDistances,
            averageSpeedKmh: 65.4,
            maxSpeedKmh: 112.0,
            includedMileageKm: 500,
            usedMileageKm: 342.5
        )
    }
}
