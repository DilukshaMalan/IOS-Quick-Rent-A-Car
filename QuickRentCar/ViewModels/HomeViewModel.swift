import Foundation

/// What the user asked for when they tapped Search. Held separately from the live
/// picker values so results only change when the button is tapped.
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
    // MARK: - Catalogue
    @Published var featuredVehicles: [Vehicle] = []
    @Published var allVehicles: [Vehicle] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    /// True when Firestore had no vehicles, so the sample catalogue is on screen.
    @Published var isUsingSampleData = false

    // MARK: - Live picker values
    @Published var selectedCategory: Vehicle.VehicleCategory?
    @Published var selectedBranch: Branch?
    @Published var selectedVehicleName: String?
    @Published var pickupDate = Date()
    @Published var returnDate = Date().adding(days: 3)

    /// Set when Search is tapped; `nil` means "show everything available".
    @Published private(set) var appliedSearch: SearchCriteria?

    private let firestoreService = FirestoreService.shared

    // MARK: - Derived

    /// Distinct vehicle names for the search dropdown, taken from the loaded catalogue.
    var vehicleNames: [String] {
        Array(Set(allVehicles.map(\.name))).sorted()
    }

    var isSearchActive: Bool { appliedSearch != nil }

    /// Vehicles after the category chips, the applied search and availability.
    var filteredVehicles: [Vehicle] {
        var vehicles = allVehicles

        if let category = selectedCategory {
            vehicles = vehicles.filter { $0.category == category }
        }

        guard let criteria = appliedSearch else {
            // Before searching, only hide vehicles that are switched off in the catalogue.
            return vehicles.filter { $0.isAvailable }
        }

        if let branch = criteria.branch {
            vehicles = vehicles.filter { $0.location == branch.rawValue }
        }

        if let name = criteria.vehicleName {
            vehicles = vehicles.filter { $0.name == name }
        }

        // Availability for the requested period — a car already booked for these
        // dates is not offered to anyone else.
        return vehicles.filter { $0.canBeBooked(for: criteria.period) }
    }

    /// How many catalogue vehicles in the searched scope are booked out for the period,
    /// so the UI can explain why some cars are missing from the results.
    var unavailableCount: Int {
        guard let criteria = appliedSearch else { return 0 }
        return allVehicles
            .filter { criteria.branch == nil || $0.location == criteria.branch?.rawValue }
            .filter { criteria.vehicleName == nil || $0.name == criteria.vehicleName }
            .filter { !$0.canBeBooked(for: criteria.period) }
            .count
    }

    /// Human-readable description of the searched rental period.
    var periodSummary: String? {
        guard let criteria = appliedSearch else { return nil }
        return "\(criteria.pickupDate.displayDateTime) → \(criteria.returnDate.displayDateTime)"
    }

    /// Subtitle for the results header.
    var resultsSubtitle: String {
        if isUsingSampleData {
            return "\(filteredVehicles.count) available · sample data"
        }
        return "\(filteredVehicles.count) available"
    }

    // MARK: - Loading

    func loadVehicles() async {
        isLoading = true
        errorMessage = nil

        do {
            let fetched = try await firestoreService.fetchVehicles()
            if fetched.isEmpty {
                // Firestore is reachable but has no vehicles yet — usually because the
                // database has not been seeded. Show the sample catalogue rather than
                // an empty screen.
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

    // MARK: - Search

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

    // MARK: - Debug

    /// Pushes the sample catalogue into Firestore, then reloads from the database.
    /// Backs the debug-only "Seed Firestore" menu action.
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
