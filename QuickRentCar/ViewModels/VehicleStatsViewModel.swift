import Foundation
import SwiftUI

@MainActor
final class VehicleStatsViewModel: ObservableObject {

    static let useSampleDataAnchor = true

    static let displayTimeZone = TimeZone(identifier: "Asia/Colombo") ?? .current

    enum Period: String, CaseIterable {
        case today = "Today"
        case week = "This Week"
        case month = "This Month"
        case custom = "Custom"

        var shortTitle: String {
            switch self {
            case .today:  return "Today"
            case .week:   return "Week"
            case .month:  return "Month"
            case .custom: return "Custom"
            }
        }
    }

    @Published var selectedPeriod: Period = .today {
        didSet { updatePeriodStats() }
    }

    @Published var customStart = Date() {
        didSet { customRangeChanged() }
    }
    @Published var customEnd = Date() {
        didSet { customRangeChanged() }
    }

    @Published var telemetry: VehicleTelemetry?
    @Published var isLoading = false
    @Published var errorMessage: String?

    @Published private(set) var replayTrips: [TelemetryTrip] = []
    @Published private(set) var replayPoints: [TelemetryPoint] = []

    @Published private(set) var lastKnownPoint: TelemetryPoint?

    private(set) var dataStart: Date?
    private(set) var dataEnd: Date?

    var availableDateRange: ClosedRange<Date>? {
        guard let start = dataStart, let end = dataEnd, start <= end else { return nil }
        return start...end
    }

    var lastKnownLocation: TelemetryLocation? { telemetry?.lastKnownLocation }
    var vehicleId: String? { telemetry?.vehicleId }
    var rentalId: String? { telemetry?.rentalId }
    var rentalReturnDate: Date? { telemetry?.rentalReturnDate }
    var packageAllowanceKm: Double { telemetry?.packageAllowanceKm ?? 0 }

    var usedKm: Double { packageUsage?.usedKm ?? 0 }
    var remainingKm: Double { packageUsage?.remainingKm ?? 0 }
    var percentUsed: Double { packageUsage?.percentUsed ?? 0 }
    private var packageUsage: (usedKm: Double, remainingKm: Double, percentUsed: Double)?

    struct PeriodStats {
        var distanceKm: Double = 0
        var maxSpeedKmh: Double = 0
        var averageSpeedKmh: Double = 0
        var drivingTimeSec: Double = 0
        var tripCount: Int = 0
    }
    @Published var periodStats = PeriodStats()

    @Published var todayStats = PeriodStats()

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

            let allPoints = data.trips.flatMap { $0.points }
            lastKnownPoint = allPoints.max(by: { $0.timestamp < $1.timestamp })
            if let first = data.trips.map(\.startTime).min() {
                let latest = lastKnownPoint?.timestamp ?? data.lastKnownLocation.timestamp
                dataStart = calendar.startOfDay(for: first)
                dataEnd = endOfDay(for: Self.useSampleDataAnchor ? latest : Date())
                if let start = dataStart, let end = dataEnd {
                    customStart = start
                    customEnd = end
                }
            }

            packageUsage = VehicleTelemetryService.shared.rentalPackageUsage(telemetry: data)

            computeTodayStats()
            updatePeriodStats()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

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

    var periodDescription: String {
        let range = selectedInterval
        let lastMoment = range.end.addingTimeInterval(-1)
        let startText = Self.dayFormatter.string(from: range.start)
        let endText = Self.dayFormatter.string(from: lastMoment)
        let endWithYear = Self.dayYearFormatter.string(from: lastMoment)
        return startText == endText ? endWithYear : "\(startText) – \(endWithYear)"
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
        todayStats = computeStats(for: interval(for: .today))
    }

    func updatePeriodStats() {
        let range = interval(for: selectedPeriod)
        periodStats = computeStats(for: range)
        rebuildReplayData(for: range)
    }

    private func customRangeChanged() {
        if customStart > customEnd {
            customEnd = customStart
            return
        }
        if selectedPeriod == .custom { updatePeriodStats() }
    }

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
