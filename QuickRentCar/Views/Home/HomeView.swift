import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: .spacingL) {
                    // MARK: - Search Header
                    SearchBarView(
                        selectedBranch: $viewModel.selectedBranch,
                        selectedVehicleName: $viewModel.selectedVehicleName,
                        vehicleNames: viewModel.vehicleNames,
                        onSearch: { viewModel.search() }
                    )
                    .padding(.horizontal)

                    // MARK: - Date & Time Row
                    VStack(spacing: .spacingM) {
                        DatePickerChip(
                            label: "Pick Up",
                            date: $viewModel.pickupDate,
                            icon: "arrow.up.circle.fill"
                        )
                        DatePickerChip(
                            label: "Return",
                            date: $viewModel.returnDate,
                            icon: "arrow.down.circle.fill"
                        )
                    }
                    .padding(.horizontal)

                    // MARK: - Validation / Errors
                    if let message = viewModel.errorMessage {
                        Label(message, systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .padding(.horizontal)
                    }

                    #if DEBUG
                    if viewModel.isUsingSampleData {
                        sampleDataBanner
                    }
                    #endif

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

                    // MARK: - Results
                    HStack(alignment: .bottom) {
                        SectionHeader(
                            title: resultsTitle,
                            subtitle: viewModel.resultsSubtitle
                        )

                        Spacer()

                        if viewModel.isSearchActive {
                            Button("Clear") { viewModel.clearSearch() }
                                .font(.caption.weight(.semibold))
                        }
                    }
                    .padding(.horizontal)

                    if let period = viewModel.periodSummary {
                        VStack(alignment: .leading, spacing: 2) {
                            Label(period, systemImage: "calendar")
                            if viewModel.unavailableCount > 0 {
                                Text("\(viewModel.unavailableCount) vehicle\(viewModel.unavailableCount == 1 ? " is" : "s are") already booked for these dates.")
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                    }

                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else if viewModel.filteredVehicles.isEmpty {
                        ContentUnavailableView(
                            "No Vehicles Found",
                            systemImage: "car.fill",
                            description: Text(emptyStateMessage)
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
            .refreshable { await viewModel.loadVehicles() }
            .task { await viewModel.loadVehicles() }
        }
    }

    // MARK: - Helpers

    private var resultsTitle: String {
        if let category = viewModel.selectedCategory { return category.rawValue }
        return viewModel.isSearchActive ? "Search Results" : "All Vehicles"
    }

    private var emptyStateMessage: String {
        guard viewModel.isSearchActive else {
            return "Try adjusting your search or filters."
        }
        let vehicle = viewModel.selectedVehicleName ?? "vehicle"
        let branch = viewModel.selectedBranch?.rawValue ?? "this branch"
        return "No \(vehicle) is free at \(branch) for the selected dates. Try different dates, another branch, or another vehicle."
    }

    #if DEBUG
    /// Shown when Firestore has no vehicles yet, so the sample catalogue is on screen.
    private var sampleDataBanner: some View {
        HStack(spacing: .spacingS) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(Color.fallbackBlue)

            VStack(alignment: .leading, spacing: 2) {
                Text("Showing sample data")
                    .font(.caption.weight(.semibold))
                Text("Firestore has no vehicles yet.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("Seed") {
                Task { await viewModel.seedDatabase() }
            }
            .font(.caption.weight(.semibold))
            .buttonStyle(.bordered)
            .disabled(viewModel.isLoading)
        }
        .padding(.spacingM)
        .background(Color.fallbackBlue.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusM))
        .padding(.horizontal)
    }
    #endif
}

// MARK: - Date Picker Chip
struct DatePickerChip: View {
    let label: String
    @Binding var date: Date
    let icon: String

    var body: some View {
        HStack {
            Label(label, systemImage: icon)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                .labelsHidden()
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
