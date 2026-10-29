import XCTest
@testable import QuickRentCar

@MainActor
final class BookingViewModelTests: XCTestCase {

    private func makeSampleVehicle(dailyPrice: Double = 100.0, isAvailable: Bool = true, bookedPeriods: [DateRange]? = nil) -> Vehicle {
        Vehicle(
            id: "v-booking-test",
            name: "Toyota Prius",
            brand: "Toyota",
            category: .sedan,
            dailyPrice: dailyPrice,
            imageURL: "vehicle_prius",
            passengerCapacity: 5,
            fuelType: .hybrid,
            transmission: .automatic,
            seats: 5,
            includedMileage: 200,
            description: "Hybrid sedan",
            specifications: [:],
            isAvailable: isAvailable,
            rating: 4.6,
            reviewCount: 20,
            location: "Colombo",
            bookedPeriods: bookedPeriods
        )
    }

    func testInit_setsDefaultDatesAndLocations() {
        let vehicle = makeSampleVehicle()
        let vm = BookingViewModel(vehicle: vehicle)

        XCTAssertEqual(vm.pickupLocation, "Colombo")
        XCTAssertEqual(vm.dropOffLocation, "Colombo")
        XCTAssertTrue(vm.returnDate > vm.pickupDate)
        XCTAssertEqual(vm.rentalDays, 3)
    }

    func testComputedPricing_matchesDailyRateAndDays() {
        let vehicle = makeSampleVehicle(dailyPrice: 100.0)
        let vm = BookingViewModel(vehicle: vehicle)

        let pickup = Date()
        let returnDate = pickup.adding(days: 4)
        vm.pickupDate = pickup
        vm.returnDate = returnDate

        XCTAssertEqual(vm.rentalDays, 4)
        XCTAssertEqual(vm.subtotal, 400.0, accuracy: 0.001)
        XCTAssertEqual(vm.taxAmount, 40.0, accuracy: 0.001) // 10% tax
        XCTAssertEqual(vm.totalPrice, 440.0, accuracy: 0.001)
    }

    func testIsFormValid_whenLocationsEmpty_returnsFalse() {
        let vehicle = makeSampleVehicle()
        let vm = BookingViewModel(vehicle: vehicle)

        vm.pickupLocation = ""
        XCTAssertFalse(vm.isFormValid)
        XCTAssertEqual(vm.validationHint, "Choose a drop-off branch to continue.")

        vm.pickupLocation = "Colombo"
        vm.dropOffLocation = ""
        XCTAssertFalse(vm.isFormValid)
    }

    func testIsFormValid_whenReturnDateBeforePickup_returnsFalse() {
        let vehicle = makeSampleVehicle()
        let vm = BookingViewModel(vehicle: vehicle)

        vm.returnDate = vm.pickupDate.adding(days: -1)

        XCTAssertFalse(vm.isFormValid)
        XCTAssertEqual(vm.validationHint, "Return time must be after the pick-up time.")
    }

    func testAvailabilityState_returnsAvailableForUnbookedDates() {
        let vehicle = makeSampleVehicle(isAvailable: true, bookedPeriods: [])
        let vm = BookingViewModel(vehicle: vehicle)

        if case .available = vm.availabilityState {
            // Success
        } else {
            XCTFail("Expected .available state")
        }
    }

    func testAvailabilityState_returnsBookedWhenPeriodOverlaps() {
        let pickup = Date().adding(days: 1)
        let returnDate = pickup.adding(days: 3)
        let conflictPeriod = DateRange(start: pickup, end: returnDate)

        let vehicle = makeSampleVehicle(isAvailable: true, bookedPeriods: [conflictPeriod])
        let vm = BookingViewModel(vehicle: vehicle)
        vm.pickupDate = pickup
        vm.returnDate = returnDate

        if case .booked = vm.availabilityState {
            // Success
        } else {
            XCTFail("Expected .booked availability state for conflicting dates")
        }
    }
}
