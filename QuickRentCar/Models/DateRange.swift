import Foundation

/// A half-open time interval `[start, end)` used for rental availability.
///
/// Intervals that merely touch are **not** considered overlapping, which is what
/// lets a vehicle returned at 10:00 be rented again from 10:00 onwards.
struct DateRange: Codable, Hashable {
    var start: Date
    var end: Date

    init(start: Date, end: Date) {
        self.start = start
        self.end = end
    }

    /// The range covers at least one moment in time.
    var isValid: Bool { end > start }

    /// Number of whole days, minimum 1 — matches the rest of the app's pricing.
    var dayCount: Int { start.days(to: end) }

    /// True when this range and `other` share at least one moment.
    ///
    /// Standard interval-intersection test: two ranges overlap unless one ends
    /// before or exactly when the other begins.
    func overlaps(_ other: DateRange) -> Bool {
        start < other.end && other.start < end
    }

    /// Convenience for call sites that only have loose dates.
    func overlaps(start otherStart: Date, end otherEnd: Date) -> Bool {
        overlaps(DateRange(start: otherStart, end: otherEnd))
    }
}
