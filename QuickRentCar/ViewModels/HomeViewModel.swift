import Foundation

struct SearchCriteria: Equatable {
    var branch: Branch?
    var vehicleName: String?
    var pickupDate: Date
    var returnDate: Date

    var period: DateRange {
        DateRange(start: pickupDate, end: returnDate)
    }
}

@MainActor
class HomeViewModel: ObservableObject {
    @Published var featuredVehicles: [Vehicle] = []
    @Published var allVehicles: [Vehicle] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    @Published var isUsingSampleData = false

    @Published var selectedCategory: Vehicle.VehicleCategory?
    @Published var selectedBranch: Branch?
    @Published var selectedVehicleName: String?
    @Published var pickupDate = Date()
    @Published var returnDate = Date().adding(days: 3)

    @Published private(set) var appliedSearch: SearchCriteria?

    private let firestoreService = FirestoreService.shared

    var vehicleNames: [String] {
        Array(Set(allVehicles.map(\.name))).sorted()
    }

    var isSearchActive: Bool { appliedSearch != nil }

    var filteredVehicles: [Vehicle] {
        var vehicles = allVehicles

        if let category = selectedCategory {
            vehicles = vehicles.filter { $0.category == category }
        }

        guard let criteria = appliedSearch else {
            return vehicles.filter { $0.isAvailable }
        }

        if let branch = criteria.branch {
            vehicles = vehicles.filter { $0.location == branch.rawValue }
        }

        if let name = criteria.vehicleName {
            vehicles = vehicles.filter { $0.name == name }
        }

        return vehicles.filter { $0.canBeBooked(for: criteria.period) }
    }

    var unavailableCount: Int {
        guard let criteria = appliedSearch else { return 0 }
        return allVehicles
            .filter { criteria.branch == nil || $0.location == criteria.branch?.rawValue }
            .filter { criteria.vehicleName == nil || $0.name == criteria.vehicleName }
            .filter { !$0.canBeBooked(for: criteria.period) }
            .count
    }

    var periodSummary: String? {
        guard let criteria = appliedSearch else { return nil }
        return "\(criteria.pickupDate.displayDateTime) → \(criteria.returnDate.displayDateTime)"
    }

    var resultsSubtitle: String {
        if isUsingSampleData {
            return "\(filteredVehicles.count) available · sample data"
        }
        return "\(filteredVehicles.count) available"
    }

    func loadVehicles() async {
        isLoading = true
        errorMessage = nil

        do {
            let fetched = try await firestoreService.fetchVehicles()
            if fetched.isEmpty {
                useSampleCatalogue()
            } else {
                allVehicles = fetched
                isUsingSampleData = false
            }
        } catch {
            errorMessage = error.localizedDescription
            useSampleCatalogue()
        }

        featuredVehicles = Array(allVehicles.filter(\.isAvailable).prefix(5))
        isLoading = false
    }

    private func useSampleCatalogue() {
        allVehicles = SeedData.vehicles
        isUsingSampleData = true
    }

    func search() {
        guard returnDate > pickupDate else {
            errorMessage = "The return date must be after the pickup date."
            return
        }

        errorMessage = nil
        appliedSearch = SearchCriteria(
            branch: selectedBranch,
            vehicleName: selectedVehicleName,
            pickupDate: pickupDate,
            returnDate: returnDate
        )
    }

    func clearSearch() {
        appliedSearch = nil
        selectedBranch = nil
        selectedVehicleName = nil
        selectedCategory = nil
    }

    func selectCategory(_ category: Vehicle.VehicleCategory?) {
        selectedCategory = selectedCategory == category ? nil : category
    }

    func seedDatabase() async {
        isLoading = true
        errorMessage = nil
        do {
            try await firestoreService.seedVehicles(SeedData.vehicles)
        } catch {
            errorMessage = "Seeding failed: \(error.localizedDescription)"
        }
        isLoading = false
        await loadVehicles()
    }
}
