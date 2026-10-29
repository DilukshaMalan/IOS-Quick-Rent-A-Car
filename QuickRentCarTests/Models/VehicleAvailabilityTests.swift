import XCTest
@testable import QuickRentCar

final class VehicleAvailabilityTests: XCTestCase {

    private func makeTestVehicle(isAvailable: Bool = true, bookedPeriods: [DateRange]? = nil) -> Vehicle {
        Vehicle(
            id: "test-car-1",
            name: "Test Sedan",
            brand: "TestBrand",
            category: .sedan,
            dailyPrice: 70.0,
            imageURL: "test_car",
            passengerCapacity: 5,
            fuelType: .petrol,
            transmission: .automatic,
            seats: 5,
            includedMileage: 200,
            description: "A test car",
            specifications: [:],
            isAvailable: isAvailable,
            rating: 4.8,
            reviewCount: 10,
            location: "Colombo",
            bookedPeriods: bookedPeriods
        )
    }

    func testCanBeBooked_whenVehicleIsUnavailable_returnsFalse() {
        let vehicle = makeTestVehicle(isAvailable: false)
        let period = DateRange(start: Date(), end: Date().adding(days: 2))

        XCTAssertFalse(vehicle.canBeBooked(for: period), "Unavailable vehicle should not be bookable")
    }

    func testCanBeBooked_whenNoBookedPeriods_returnsTrue() {
        let vehicle = makeTestVehicle(isAvailable: true, bookedPeriods: nil)
        let period = DateRange(start: Date(), end: Date().adding(days: 3))

        XCTAssertTrue(vehicle.canBeBooked(for: period), "Available vehicle with no previous bookings should be bookable")
    }

    func testCanBeBooked_whenRequestedPeriodConflictsWithExistingBooking_returnsFalse() {
        let today = Date()
        let existingBooking = DateRange(start: today.adding(days: 2), end: today.adding(days: 5))
        let vehicle = makeTestVehicle(isAvailable: true, bookedPeriods: [existingBooking])

        let conflictPeriod = DateRange(start: today.adding(days: 3), end: today.adding(days: 6))
        XCTAssertFalse(vehicle.canBeBooked(for: conflictPeriod), "Should reject booking that overlaps an existing reservation")
    }

    func testCanBeBooked_whenRequestedPeriodHasNoConflict_returnsTrue() {
        let today = Date()
        let existingBooking = DateRange(start: today.adding(days: 5), end: today.adding(days: 10))
        let vehicle = makeTestVehicle(isAvailable: true, bookedPeriods: [existingBooking])

        let clearPeriod = DateRange(start: today.adding(days: 1), end: today.adding(days: 4))
        XCTAssertTrue(vehicle.canBeBooked(for: clearPeriod), "Should allow booking for non-overlapping dates")
    }
}
