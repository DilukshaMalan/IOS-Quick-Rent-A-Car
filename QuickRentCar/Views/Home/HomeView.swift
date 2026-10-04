import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: .spacingL) {
                    // MARK: - Search Header
                    SearchBarView(
                        searchText: $viewModel.searchText,
                        pickupLocation: $viewModel.pickupLocation
                    )
                    .padding(.horizontal)

                    // MARK: - Date Row
                    HStack(spacing: .spacingM) {
                        DatePickerChip(label: "Pick Up", date: $viewModel.pickupDate, icon: "arrow.up.circle.fill")
                        DatePickerChip(label: "Return", date: $viewModel.returnDate, icon: "arrow.down.circle.fill")
                    }
                    .padding(.horizontal)

                    // MARK: - Categories
                    CategoryFilterView(selectedCategory: $viewModel.selectedCategory)

                    // MARK: - Featured Vehicles
                    if !viewModel.featuredVehicles.isEmpty {
                        SectionHeader(title: "Featured Vehicles", subtitle: "Top picks for you")
                            .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: .spacingM) {
                                ForEach(viewModel.featuredVehicles) { vehicle in
                                    NavigationLink(destination: VehicleDetailView(vehicle: vehicle)) {
                                        FeaturedVehicleCard(vehicle: vehicle)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // MARK: - All Vehicles
                    SectionHeader(
                        title: viewModel.selectedCategory?.rawValue ?? "All Vehicles",
                        subtitle: "\(viewModel.filteredVehicles.count) available"
                    )
                    .padding(.horizontal)

                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else if viewModel.filteredVehicles.isEmpty {
                        ContentUnavailableView(
                            "No Vehicles Found",
                            systemImage: "car.fill",
                            description: Text("Try adjusting your search or filters.")
                        )
                    } else {
                        LazyVStack(spacing: .spacingM) {
                            ForEach(viewModel.filteredVehicles) { vehicle in
                                NavigationLink(destination: VehicleDetailView(vehicle: vehicle)) {
                                    VehicleCard(vehicle: vehicle)
                                        .padding(.horizontal)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.bottom, .spacingXL)
            }
            .navigationTitle("QuickRentCar")
            .navigationBarTitleDisplayMode(.large)
            .task { await viewModel.loadVehicles() }
        }
    }
}

// MARK: - Date Picker Chip
struct DatePickerChip: View {
    let label: String
    @Binding var date: Date
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(label, systemImage: icon)
                .font(.caption)
                .foregroundStyle(.secondary)

            DatePicker("", selection: $date, displayedComponents: [.date])
                .labelsHidden()
                .frame(maxWidth: .infinity)
        }
        .padding(.spacingM)
        .cardStyle()
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.title2.bold())
                .foregroundStyle(Color.fallbackNavy)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthViewModel())
}
