import Foundation
import SwiftUI

@MainActor
final class VehicleStatsViewModel: ObservableObject {
    // MARK: - Period selection
    enum Period: String, CaseIterable {
        case today = "Today"
        case week = "This Week"
        case month = "This Month"
    }
    @Published var selectedPeriod: Period = .today
    
    // MARK: - Telemetry data
    @Published var telemetry: VehicleTelemetry?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Computed UI values
    var lastKnownLocation: TelemetryLocation? { telemetry?.lastKnownLocation }
    var vehicleId: String? { telemetry?.vehicleId }
    var rentalId: String? { telemetry?.rentalId }
    var rentalReturnDate: Date? { telemetry?.rentalReturnDate }
    var packageAllowanceKm: Double { telemetry?.packageAllowanceKm ?? 0 }
    
    // Package usage
    var usedKm: Double { packageUsage?.usedKm ?? 0 }
    var remainingKm: Double { packageUsage?.remainingKm ?? 0 }
    var percentUsed: Double { packageUsage?.percentUsed ?? 0 }
    private var packageUsage: (usedKm: Double, remainingKm: Double, percentUsed: Double)?
    
    // MARK: - Period stats
    struct PeriodStats {
        var distanceKm: Double = 0
        var maxSpeedKmh: Double = 0
        var averageSpeedKmh: Double = 0
        var drivingTimeSec: Double = 0
        var tripCount: Int = 0
    }
    @Published var periodStats = PeriodStats()
    
    // MARK: - Today stats (shortcut for UI)
    @Published var todayStats = PeriodStats()
    
    // MARK: - Load telemetry
    func loadTelemetry() async {
        print("Start load daat")
        isLoading = true
        errorMessage = nil
        do {
            let data = try await TelemetryRepository.shared.loadTelemetry()
            telemetry = data
            // calculate package usage once
            packageUsage = VehicleTelemetryService.shared.rentalPackageUsage(telemetry: data)
            // compute today stats for the top‑cards
            computeTodayStats()
            // compute selected period stats (default today)
            updatePeriodStats()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    // MARK: - Helpers
    private func interval(for period: Period) -> DateInterval {
        let calendar = Calendar.current
        let now = Date()
        switch period {
        case .today:
            let start = calendar.startOfDay(for: now)
            let end = calendar.date(byAdding: .day, value: 1, to: start) ?? now
            return DateInterval(start: start, end: end)
        case .week:
            // Monday as first day
            var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
            components.weekday = 2 // Monday
            let start = calendar.date(from: components) ?? now
            let end = calendar.date(byAdding: .day, value: 7, to: start) ?? now
            return DateInterval(start: start, end: end)
        case .month:
            let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
            let end = calendar.date(byAdding: .month, value: 1, to: start) ?? now
            return DateInterval(start: start, end: end)
        }
    }
    
    private func computeStats(for interval: DateInterval) -> PeriodStats {
        guard let telemetry = telemetry else { return PeriodStats() }
        let raw = VehicleTelemetryService.shared.calculateStats(for: interval, telemetry: telemetry)
        return PeriodStats(distanceKm: raw.totalDistanceKm,
                           maxSpeedKmh: raw.maxSpeedKmh,
                           averageSpeedKmh: raw.averageSpeedKmh,
                           drivingTimeSec: raw.drivingTimeSec,
                           tripCount: raw.tripCount)
    }
    
    func computeTodayStats() {
        let todayInterval = interval(for: .today)
        todayStats = computeStats(for: todayInterval)
    }
    
    func updatePeriodStats() {
        let interval = interval(for: selectedPeriod)
        periodStats = computeStats(for: interval)
    }
}

// Duplicate PeriodStats extension removed – PeriodStats is defined within VehicleStatsViewModel.
