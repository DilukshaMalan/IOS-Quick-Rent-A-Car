import XCTest
@testable import QuickRentCar

@MainActor
final class VehicleStatsViewModelTests: XCTestCase {

    func testSelectedPeriod_switchesDateInterval() {
        let vm = VehicleStatsViewModel()

        vm.selectedPeriod = .today
        let todayInterval = vm.selectedInterval
        XCTAssertGreaterThan(todayInterval.duration, 0)

        vm.selectedPeriod = .week
        let weekInterval = vm.selectedInterval
        XCTAssertGreaterThanOrEqual(weekInterval.duration, todayInterval.duration)
    }

    func testCustomRangeChanged_whenStartAfterEnd_adjustsEndToMatchStart() {
        let vm = VehicleStatsViewModel()
        let today = Date()

        vm.customEnd = today
        vm.customStart = today.adding(days: 1)

        XCTAssertEqual(vm.customEnd, vm.customStart, "customEnd should automatically adjust to equal customStart when start > end")
    }

    func testPeriodDescription_returnsFormattedDateRangeString() {
        let vm = VehicleStatsViewModel()
        vm.selectedPeriod = .today

        let description = vm.periodDescription
        XCTAssertFalse(description.isEmpty, "Period description should return a non-empty formatted date string")
    }
}
