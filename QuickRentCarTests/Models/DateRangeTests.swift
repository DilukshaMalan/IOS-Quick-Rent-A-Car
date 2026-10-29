import XCTest
@testable import QuickRentCar

final class DateRangeTests: XCTestCase {

    func testIsValid_whenEndAfterStart_returnsTrue() {
        let start = Date()
        let end = start.adding(days: 2)
        let range = DateRange(start: start, end: end)

        XCTAssertTrue(range.isValid)
    }

    func testIsValid_whenEndBeforeOrEqualToStart_returnsFalse() {
        let start = Date()
        let equalRange = DateRange(start: start, end: start)
        let invertedRange = DateRange(start: start, end: start.adding(days: -1))

        XCTAssertFalse(equalRange.isValid)
        XCTAssertFalse(invertedRange.isValid)
    }

    func testDayCount_calculatesAccurateDaySpan() {
        let start = Date()
        let end = start.adding(days: 4)
        let range = DateRange(start: start, end: end)

        XCTAssertEqual(range.dayCount, 4)
    }

    func testOverlaps_withPartialOverlap_returnsTrue() {
        let baseStart = Date()
        let r1 = DateRange(start: baseStart, end: baseStart.adding(days: 5))
        let r2 = DateRange(start: baseStart.adding(days: 3), end: baseStart.adding(days: 8))

        XCTAssertTrue(r1.overlaps(r2))
        XCTAssertTrue(r2.overlaps(r1))
    }

    func testOverlaps_withEngulfingRange_returnsTrue() {
        let baseStart = Date()
        let outer = DateRange(start: baseStart, end: baseStart.adding(days: 10))
        let inner = DateRange(start: baseStart.adding(days: 2), end: baseStart.adding(days: 4))

        XCTAssertTrue(outer.overlaps(inner))
        XCTAssertTrue(inner.overlaps(outer))
    }

    func testOverlaps_withAdjacentOrSeparatedRanges_returnsFalse() {
        let baseStart = Date()
        let r1 = DateRange(start: baseStart, end: baseStart.adding(days: 3))
        let r2 = DateRange(start: baseStart.adding(days: 3), end: baseStart.adding(days: 6))
        let r3 = DateRange(start: baseStart.adding(days: 7), end: baseStart.adding(days: 10))

        XCTAssertFalse(r1.overlaps(r2), "Adjacent ranges touching at the boundary should not overlap")
        XCTAssertFalse(r1.overlaps(r3), "Separated ranges should not overlap")
    }

    func testOverlapsConvenience_withLooseDates_matchesDateRangeOverlaps() {
        let baseStart = Date()
        let range = DateRange(start: baseStart, end: baseStart.adding(days: 5))

        let overlaps = range.overlaps(start: baseStart.adding(days: 2), end: baseStart.adding(days: 6))
        let doesNotOverlap = range.overlaps(start: baseStart.adding(days: 6), end: baseStart.adding(days: 9))

        XCTAssertTrue(overlaps)
        XCTAssertFalse(doesNotOverlap)
    }
}
