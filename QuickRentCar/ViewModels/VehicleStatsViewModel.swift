import Foundation
import SwiftUI

@MainActor
final class VehicleStatsViewModel: ObservableObject {

    /// TESTING: the seed JSON only covers Oct 14–18, so "Today" and "This Week" would be empty
    /// on any later date. While this is `true`, periods are measured back from the newest sample
    /// point (the last known location time) instead of from the real current date.
    /// Set to `false` when real, live telemetry is connected.
    static let useSampleDataAnchor = true

    /// Stats days/weeks are calculated in Colombo time (the seed data is +05:30).
    static let displayTimeZone = TimeZone(identifier: "Asia/Colombo") ?? .current

    // MARK: - Period selection
    enum Period: String, CaseIterable {
        case today = "Today"
        case week = "This Week"
        case month = "This Month"
        case custom = "Custom"

        /// Short label for the segmented control.
        var shortTitle: String {
            switch self {
            case .today:  return "Today"
            case .week:   return "Week"
            case .month:  return "Month"
            case .custom: return "Custom"
            }
        }
    }

    /// Changing the period recalculates the stats AND the replay data.
    @Published var selectedPeriod: Period = .today {
        didSet { updatePeriodStats() }
    }

    /// Custom range (inclusive days). Only used while `selectedPeriod == .custom`.
    @Published var customStart = Date() {
        didSet { customRangeChanged() }
    }
    @Published var customEnd = Date() {
        didSet { customRangeChanged() }
    }

    // MARK: - Telemetry data
    @Published var telemetry: VehicleTelemetry?
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Replay data (limited to the selected period)
    /// Trips that fall inside the selected period, with points trimmed to it, oldest first.
    @Published private(set) var replayTrips: [TelemetryTrip] = []
    /// All points of `replayTrips` in time order — this is what the replay plays.
    @Published private(set) var replayPoints: [TelemetryPoint] = []

    /// Newest telemetry sample (speed / engine state at the last known location).
    @Published private(set) var lastKnownPoint: TelemetryPoint?

    /// First and last moment covered by the telemetry (limits the custom date pickers).
    private(set) var dataStart: Date?
    private(set) var dataEnd: Date?

    var availableDateRange: ClosedRange<Date>? {
        guard let start = dataStart, let end = dataEnd, start <= end else { return nil }
        return start...end
    }

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
    /// Loads once. Pass `force: true` to reload (the stats page re-appears after the replay screen,
    /// and a reload there would reset the custom range).
    func loadTelemetry(force: Bool = false) async {
        if telemetry != nil && !force {
            print("🔎 [StatsVM] telemetry already loaded – skipping")
            return
        }

        print("🔎 [StatsVM] loadTelemetry started")
        isLoading = true
        errorMessage = nil
        do {
            let data = try await TelemetryRepository.shared.loadTelemetry()

            telemetry = data

            // Newest sample + the span of dates the data covers
            let allPoints = data.trips.flatMap { $0.points }
            lastKnownPoint = allPoints.max(by: { $0.timestamp < $1.timestamp })
            if let first = data.trips.map(\.startTime).min() {
                let latest = lastKnownPoint?.timestamp ?? data.lastKnownLocation.timestamp
                dataStart = calendar.startOfDay(for: first)
                dataEnd = endOfDay(for: Self.useSampleDataAnchor ? latest : Date())
                // Default custom range = everything the data covers
                if let start = dataStart, let end = dataEnd {
                    customStart = start
                    customEnd = end
                }
            }

            // calculate package usage once
            packageUsage = VehicleTelemetryService.shared.rentalPackageUsage(telemetry: data)

            // compute today stats for the top-cards
            computeTodayStats()
            // compute selected period stats + replay data
            updatePeriodStats()
        } catch {
            // `localizedDescription` hides DecodingError details; print the full error for debugging.
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Calendar helpers
    /// Colombo calendar, Monday as the first day of the week.
    private var calendar: Calendar {
        var cal = Calendar.current
        cal.firstWeekday = 2
        cal.timeZone = Self.displayTimeZone
        return cal
    }

    private func endOfDay(for date: Date) -> Date {
        let start = calendar.startOfDay(for: date)
        let nextDay = calendar.date(byAdding: .day, value: 1, to: start) ?? start.addingTimeInterval(86_400)
        return nextDay.addingTimeInterval(-1)
    }

    /// "Now" for the stats periods (see `useSampleDataAnchor`).
    private var referenceDate: Date {
        if Self.useSampleDataAnchor, let latest = telemetry?.lastKnownLocation.timestamp {
            return latest
        }
        return Date()
    }

    private func interval(for period: Period) -> DateInterval {
        let component: Calendar.Component
        switch period {
        case .today:
            component = .day
        case .week:
            component = .weekOfYear
        case .month:
            component = .month
        case .custom:
            let first = calendar.startOfDay(for: min(customStart, customEnd))
            let lastDay = calendar.startOfDay(for: max(customStart, customEnd))
            let end = calendar.date(byAdding: .day, value: 1, to: lastDay) ?? lastDay.addingTimeInterval(86_400)
            return DateInterval(start: first, end: end)
        }
        return calendar.dateInterval(of: component, for: referenceDate)
            ?? DateInterval(start: referenceDate, duration: 86_400)
    }

    /// The date range the selected period currently covers (stats and replay both use this).
    var selectedInterval: DateInterval { interval(for: selectedPeriod) }

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeZone = displayTimeZone
        f.dateFormat = "MMM d"
        return f
    }()

    private static let dayYearFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeZone = displayTimeZone
        f.dateFormat = "MMM d, yyyy"
        return f
    }()

    /// e.g. "Oct 18, 2026" or "Oct 12 – Oct 18, 2026".
    var periodDescription: String {
        let range = selectedInterval
        let lastMoment = range.end.addingTimeInterval(-1)
        let startText = Self.dayFormatter.string(from: range.start)
        let endText = Self.dayFormatter.string(from: lastMoment)
        let endWithYear = Self.dayYearFormatter.string(from: lastMoment)
        return startText == endText ? endWithYear : "\(startText) – \(endWithYear)"
    }

    // MARK: - Stats
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
        todayStats = computeStats(for: interval(for: .today))
    }

    func updatePeriodStats() {
        let range = interval(for: selectedPeriod)
        periodStats = computeStats(for: range)
        rebuildReplayData(for: range)
    }

    private func customRangeChanged() {
        if customStart > customEnd {
            customEnd = customStart      // re-enters here with a valid range
            return
        }
        if selectedPeriod == .custom { updatePeriodStats() }
    }

    // MARK: - Replay data
    /// Keeps only the trips/points inside the selected period, so the replay matches the stats.
    private func rebuildReplayData(for range: DateInterval) {
        guard let telemetry = telemetry else {
            replayTrips = []
            replayPoints = []
            return
        }

        var trips: [TelemetryTrip] = []
        for trip in telemetry.trips.sorted(by: { $0.startTime < $1.startTime }) {
            let pts = trip.points
                .filter { range.contains($0.timestamp) }
                .sorted { $0.timestamp < $1.timestamp }
            guard !pts.isEmpty else { continue }
            trips.append(TelemetryTrip(tripId: trip.tripId,
                                       startTime: trip.startTime,
                                       endTime: trip.endTime,
                                       startReason: trip.startReason,
                                       endReason: trip.endReason,
                                       startLocationLabel: trip.startLocationLabel,
                                       endLocationLabel: trip.endLocationLabel,
                                       routeTemplate: trip.routeTemplate,
                                       distanceKmApprox: trip.distanceKmApprox,
                                       points: pts))
        }
        replayTrips = trips
        replayPoints = trips.flatMap { $0.points }
    }
}
