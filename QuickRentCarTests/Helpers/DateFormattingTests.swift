import XCTest
@testable import QuickRentCar

final class DateFormattingTests: XCTestCase {

    func testDaysTo_withFutureDate_calculatesCorrectDayCount() {
        let calendar = Calendar.current
        let today = Date()
        guard let fiveDaysLater = calendar.date(byAdding: .day, value: 5, to: today) else {
            XCTFail("Failed to create date")
            return
        }

        let days = today.days(to: fiveDaysLater)
        XCTAssertEqual(days, 5, "Difference between today and +5 days should be 5")
    }

    func testDaysTo_withPastOrSameDate_returnsMinimumOne() {
        let calendar = Calendar.current
        let today = Date()
        guard let pastDate = calendar.date(byAdding: .day, value: -2, to: today) else {
            XCTFail("Failed to create date")
            return
        }

        XCTAssertEqual(today.days(to: today), 1, "Same-day difference should fall back to minimum 1")
        XCTAssertEqual(today.days(to: pastDate), 1, "Past-date difference should fall back to minimum 1")
    }

    func testIsToday_withCurrentDate_returnsTrue() {
        let now = Date()
        XCTAssertTrue(now.isToday)
    }

    func testIsToday_withYesterdayOrTomorrow_returnsFalse() {
        let calendar = Calendar.current
        let now = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!

        XCTAssertFalse(yesterday.isToday)
        XCTAssertFalse(tomorrow.isToday)
    }

    func testStartOfDay_resetsHoursMinutesAndSecondsToZero() {
        let now = Date()
        let start = now.startOfDay

        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: start)
        XCTAssertEqual(components.hour, 0)
        XCTAssertEqual(components.minute, 0)
        XCTAssertEqual(components.second, 0)
    }

    func testAddingDays_incrementsAndDecrementsCorrectly() {
        let calendar = Calendar.current
        let now = Date()

        let plusThree = now.adding(days: 3)
        let minusTwo = now.adding(days: -2)

        let diffPlus = calendar.dateComponents([.day], from: now.startOfDay, to: plusThree.startOfDay).day
        let diffMinus = calendar.dateComponents([.day], from: now.startOfDay, to: minusTwo.startOfDay).day

        XCTAssertEqual(diffPlus, 3)
        XCTAssertEqual(diffMinus, -2)
    }

    func testDisplayFormatters_produceNonEmptyStrings() {
        let now = Date()
        XCTAssertFalse(now.displayDate.isEmpty)
        XCTAssertFalse(now.displayTime.isEmpty)
        XCTAssertFalse(now.displayDateTime.isEmpty)
    }
}
