import Foundation

@MainActor
class HomeViewModel: ObservableObject {
    @Published var featuredVehicles: [Vehicle] = []
    @Published var allVehicles: [Vehicle] = []
    @Published var selectedCategory: Vehicle.VehicleCategory?
    @Published var searchText = ""
    @Published var pickupLocation = ""
    @Published var pickupDate = Date()
    @Published var returnDate = Date().adding(days: 3)
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let firestoreService = FirestoreService.shared

    var filteredVehicles: [Vehicle] {
        var vehicles = allVehicles

        if let category = selectedCategory {
            vehicles = vehicles.filter { $0.category == category }
        }

        if !searchText.isEmpty {
            vehicles = vehicles.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.brand.localizedCaseInsensitiveContains(searchText)
            }
        }

        return vehicles
    }

    func loadVehicles() async {
        isLoading = true
        errorMessage = nil

        do {
            allVehicles = try await firestoreService.fetchVehicles()
            featuredVehicles = Array(allVehicles.prefix(5))
        } catch {
            errorMessage = error.localizedDescription
            // Use sample data as fallback
            allVehicles = Vehicle.sampleVehicles
            featuredVehicles = Vehicle.sampleVehicles
        }

        isLoading = false
    }

    func selectCategory(_ category: Vehicle.VehicleCategory?) {
        selectedCategory = selectedCategory == category ? nil : category
    }
}
