import Foundation

struct DateRange: Codable, Hashable {
    var start: Date
    var end: Date

    init(start: Date, end: Date) {
        self.start = start
        self.end = end
    }

    var isValid: Bool { end > start }

    var dayCount: Int { start.days(to: end) }

    func overlaps(_ other: DateRange) -> Bool {
        start < other.end && other.start < end
    }

    func overlaps(start otherStart: Date, end otherEnd: Date) -> Bool {
        overlaps(DateRange(start: otherStart, end: otherEnd))
    }
}
