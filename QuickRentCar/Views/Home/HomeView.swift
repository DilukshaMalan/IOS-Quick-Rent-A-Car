import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // MARK: 1 — Hero header (greeting + notif bell)
                    HomeHeaderView(userName: authViewModel.currentUser?.firstName ?? "there")
                        .padding(.horizontal, .spacingM)
                        .padding(.top, .spacingM)
                        .padding(.bottom, .spacingL)

                    // MARK: 2 — Unified booking search card
                    BookingSearchCard(
                        selectedBranch: $viewModel.selectedBranch,
                        selectedVehicleName: $viewModel.selectedVehicleName,
                        vehicleNames: viewModel.vehicleNames,
                        pickupDate: $viewModel.pickupDate,
                        returnDate: $viewModel.returnDate,
                        onSearch: { viewModel.search() }
                    )
                    .padding(.horizontal, .spacingM)

                    // Error / validation
                    if let message = viewModel.errorMessage {
                        Label(message, systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .padding(.horizontal, .spacingM)
                            .padding(.top, .spacingS)
                    }

                    #if DEBUG
                    if viewModel.isUsingSampleData {
                        sampleDataBanner
                            .padding(.top, .spacingS)
                    }
                    #endif

                    // MARK: 3 — Compact category chips
                    CategoryFilterView(selectedCategory: $viewModel.selectedCategory)
                        .padding(.top, .spacingL)

                    // MARK: 4 — Featured vehicles
                    if !viewModel.featuredVehicles.isEmpty {
                        SectionHeader(title: "Featured", subtitle: "Top picks for you")
                            .padding(.horizontal, .spacingM)
                            .padding(.top, .spacingL)
                            .padding(.bottom, .spacingS)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: .spacingM) {
                                ForEach(viewModel.featuredVehicles) { vehicle in
                                    NavigationLink(destination: VehicleDetailView(vehicle: vehicle)) {
                                        FeaturedVehicleCard(vehicle: vehicle)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, .spacingM)
                            .padding(.vertical, 4) // let shadow breathe
                        }
                    }

                    // MARK: 5 — Results list
                    HStack(alignment: .bottom) {
                        SectionHeader(
                            title: resultsTitle,
                            subtitle: viewModel.resultsSubtitle
                        )
                        Spacer()
                        if viewModel.isSearchActive {
                            Button("Clear") { viewModel.clearSearch() }
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.fallbackBlue)
                        }
                    }
                    .padding(.horizontal, .spacingM)
                    .padding(.top, .spacingL)
                    .padding(.bottom, .spacingXS)

                    // Period summary
                    if let period = viewModel.periodSummary {
                        VStack(alignment: .leading, spacing: 2) {
                            Label(period, systemImage: "calendar")
                            if viewModel.unavailableCount > 0 {
                                Text("\(viewModel.unavailableCount) vehicle\(viewModel.unavailableCount == 1 ? " is" : "s are") unavailable for these dates.")
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, .spacingM)
                        .padding(.bottom, .spacingS)
                    }

                    // Vehicle list
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, .spacingXL)
                    } else if viewModel.filteredVehicles.isEmpty {
                        ContentUnavailableView(
                            "No Vehicles Found",
                            systemImage: "car.fill",
                            description: Text(emptyStateMessage)
                        )
                        .padding(.vertical, .spacingXL)
                    } else {
                        LazyVStack(spacing: .spacingM) {
                            ForEach(viewModel.filteredVehicles) { vehicle in
                                NavigationLink(destination: VehicleDetailView(vehicle: vehicle)) {
                                    VehicleCard(vehicle: vehicle)
                                        .padding(.horizontal, .spacingM)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Spacer(minLength: .spacingXXL)
                }
            }
            .navigationBarHidden(true)          // header replaces the navbar
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
        let branch  = viewModel.selectedBranch?.rawValue ?? "this branch"
        return "No \(vehicle) is free at \(branch) for the selected dates. Try different dates, another branch, or another vehicle."
    }

    #if DEBUG
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
        .background(Color.fallbackBlue.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusM))
        .padding(.horizontal, .spacingM)
    }
    #endif
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
