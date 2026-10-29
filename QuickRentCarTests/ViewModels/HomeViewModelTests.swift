import XCTest
@testable import QuickRentCar

@MainActor
final class HomeViewModelTests: XCTestCase {

    private func makeVehicles() -> [Vehicle] {
        [
            Vehicle(
                id: "v-1",
                name: "Toyota Camry",
                brand: "Toyota",
                category: .sedan,
                dailyPrice: 65.0,
                imageURL: "car1",
                passengerCapacity: 5,
                fuelType: .petrol,
                transmission: .automatic,
                seats: 5,
                includedMileage: 200,
                description: "",
                specifications: [:],
                isAvailable: true,
                rating: 4.5,
                reviewCount: 10,
                location: Branch.colombo.rawValue
            ),
            Vehicle(
                id: "v-2",
                name: "Honda CR-V",
                brand: "Honda",
                category: .suv,
                dailyPrice: 85.0,
                imageURL: "car2",
                passengerCapacity: 5,
                fuelType: .hybrid,
                transmission: .automatic,
                seats: 5,
                includedMileage: 200,
                description: "",
                specifications: [:],
                isAvailable: true,
                rating: 4.7,
                reviewCount: 15,
                location: Branch.negombo.rawValue
            ),
            Vehicle(
                id: "v-3",
                name: "Tesla Model 3",
                brand: "Tesla",
                category: .electric,
                dailyPrice: 120.0,
                imageURL: "car3",
                passengerCapacity: 5,
                fuelType: .electric,
                transmission: .automatic,
                seats: 5,
                includedMileage: 250,
                description: "",
                specifications: [:],
                isAvailable: false, // switched off
                rating: 4.9,
                reviewCount: 30,
                location: Branch.colombo.rawValue
            )
        ]
    }

    func testSelectCategory_filtersVehiclesByCategory() {
        let vm = HomeViewModel()
        vm.allVehicles = makeVehicles()

        vm.selectCategory(.suv)

        XCTAssertEqual(vm.selectedCategory, .suv)
        XCTAssertEqual(vm.filteredVehicles.count, 1)
        XCTAssertEqual(vm.filteredVehicles.first?.name, "Honda CR-V")
    }

    func testSelectCategory_whenTappedAgain_deselectsCategory() {
        let vm = HomeViewModel()
        vm.allVehicles = makeVehicles()

        vm.selectCategory(.sedan)
        XCTAssertEqual(vm.selectedCategory, .sedan)

        // Tap again to toggle off
        vm.selectCategory(.sedan)
        XCTAssertNil(vm.selectedCategory)
        // Shows available vehicles (2 of 3 are available)
        XCTAssertEqual(vm.filteredVehicles.count, 2)
    }

    func testSearch_withValidCriteria_appliesSearch() {
        let vm = HomeViewModel()
        vm.allVehicles = makeVehicles()

        vm.selectedBranch = .negombo
        vm.pickupDate = Date().adding(days: 1)
        vm.returnDate = Date().adding(days: 4)

        vm.search()

        XCTAssertTrue(vm.isSearchActive)
        XCTAssertNil(vm.errorMessage)
        XCTAssertEqual(vm.filteredVehicles.count, 1)
        XCTAssertEqual(vm.filteredVehicles.first?.location, Branch.negombo.rawValue)
    }

    func testSearch_withInvalidDates_setsErrorMessage() {
        let vm = HomeViewModel()
        vm.pickupDate = Date().adding(days: 5)
        vm.returnDate = Date().adding(days: 2) // return before pickup

        vm.search()

        XCTAssertFalse(vm.isSearchActive)
        XCTAssertEqual(vm.errorMessage, "The return date must be after the pickup date.")
    }

    func testClearSearch_resetsAllSearchFilters() {
        let vm = HomeViewModel()
        vm.allVehicles = makeVehicles()

        vm.selectedBranch = .colombo
        vm.selectedCategory = .sedan
        vm.search()

        XCTAssertTrue(vm.isSearchActive)

        vm.clearSearch()

        XCTAssertFalse(vm.isSearchActive)
        XCTAssertNil(vm.selectedBranch)
        XCTAssertNil(vm.selectedCategory)
        XCTAssertNil(vm.appliedSearch)
    }

    func testFilteredVehicles_respectsVehicleAvailability() {
        let vm = HomeViewModel()
        vm.allVehicles = makeVehicles()

        // Without active search, unavailable vehicles are filtered out
        let availableCars = vm.filteredVehicles
        XCTAssertFalse(availableCars.contains(where: { !$0.isAvailable }))
    }
}
