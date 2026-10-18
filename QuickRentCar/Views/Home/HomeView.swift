import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = HomeViewModel()

    // Used to scroll to results section after search is triggered
    private enum ScrollAnchor: String { case results }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {

                        // ─────────────────────────────────────────────────
                        // MARK: 1 — Top navigation bar
                        // ─────────────────────────────────────────────────
                        HomeTopBarView(
                            userName: authViewModel.currentUser?.firstName ?? "there"
                        )

                        // ─────────────────────────────────────────────────
                        // MARK: 2 — Hero banner (hidden once search is active)
                        // ─────────────────────────────────────────────────
                        if !viewModel.isSearchActive {
                            HeroBannerView()
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        // ─────────────────────────────────────────────────
                        // MARK: 3 — Floating search card
                        // ─────────────────────────────────────────────────
                        BookingSearchCard(
                            selectedBranch: $viewModel.selectedBranch,
                            selectedVehicleName: $viewModel.selectedVehicleName,
                            vehicleNames: viewModel.vehicleNames,
                            pickupDate: $viewModel.pickupDate,
                            returnDate: $viewModel.returnDate,
                            onSearch: {
                                withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                                    viewModel.search()
                                }
                                // Small delay so animation starts before scroll
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                    withAnimation(.easeInOut(duration: 0.4)) {
                                        proxy.scrollTo(ScrollAnchor.results.rawValue, anchor: .top)
                                    }
                                }
                            }
                        )
                        .padding(.horizontal, .spacingM)
                        // Only overlap the hero when hero is visible
                        .offset(y: viewModel.isSearchActive ? 0 : -28)
                        .padding(.bottom, viewModel.isSearchActive ? 0 : -28)
                        .animation(.spring(response: 0.45, dampingFraction: 0.82), value: viewModel.isSearchActive)

                        // Validation error
                        if let message = viewModel.errorMessage {
                            Label(message, systemImage: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                                .padding(.horizontal, .spacingM)
                                .padding(.top, .spacingS)
                                .transition(.opacity)
                        }

                        #if DEBUG
                        if viewModel.isUsingSampleData {
                            sampleDataBanner
                                .padding(.top, .spacingS)
                        }
                        #endif

                        // ─────────────────────────────────────────────────
                        // MARK: 4 — Category chips (always visible)
                        // ─────────────────────────────────────────────────
                        CategoryFilterView(selectedCategory: $viewModel.selectedCategory)
                            .padding(.top, .spacingL)

                        // ─────────────────────────────────────────────────
                        // MARK: 5 — Popular Vehicles (hidden when search active)
                        // ─────────────────────────────────────────────────
                        if !viewModel.isSearchActive && !viewModel.featuredVehicles.isEmpty {
                            Group {
                                HStack(alignment: .firstTextBaseline) {
                                    Text("Popular Vehicles")
                                        .font(.title3.bold())
                                        .foregroundStyle(Color.fallbackNavy)
                                    Spacer()
                                    NavigationLink(destination: AllVehiclesView()) {
                                        Text("See All")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(Color.fallbackBlue)
                                    }
                                }
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
                                    .padding(.vertical, 4)
                                }
                            }
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }

                        // ─────────────────────────────────────────────────
                        // MARK: 6 — Results section (scrolled to on search)
                        // ─────────────────────────────────────────────────
                        VStack(alignment: .leading, spacing: 0) {

                            // Results header row
                            HStack(alignment: .bottom) {
                                SectionHeader(
                                    title: resultsTitle,
                                    subtitle: viewModel.resultsSubtitle
                                )
                                Spacer()
                                if viewModel.isSearchActive {
                                    // "Clear" button — brings Popular Vehicles back
                                    Button {
                                        withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                                            viewModel.clearSearch()
                                        }
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.caption)
                                            Text("Clear")
                                                .font(.caption.weight(.semibold))
                                        }
                                        .foregroundStyle(Color.fallbackBlue)
                                    }
                                }
                            }
                            .padding(.horizontal, .spacingM)
                            .padding(.top, .spacingL)
                            .padding(.bottom, .spacingXS)
                            // Scroll anchor — this is what we jump to after search
                            .id(ScrollAnchor.results.rawValue)

                            // Active search summary pill
                            if viewModel.isSearchActive, let period = viewModel.periodSummary {
                                HStack(spacing: .spacingS) {
                                    Image(systemName: "calendar")
                                        .font(.caption2)
                                    Text(period)
                                        .font(.caption)

                                    if viewModel.unavailableCount > 0 {
                                        Text("·")
                                        Text("\(viewModel.unavailableCount) unavailable")
                                            .font(.caption)
                                    }
                                }
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(Color.gray.opacity(0.08))
                                .clipShape(Capsule())
                                .padding(.horizontal, .spacingM)
                                .padding(.bottom, .spacingS)
                                .transition(.scale.combined(with: .opacity))
                            }

                            // ── Vehicle list / empty state / loading ──
                            if viewModel.isLoading {
                                VStack(spacing: .spacingM) {
                                    ProgressView()
                                    Text("Finding available vehicles…")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
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
                                        .transition(.move(edge: .bottom).combined(with: .opacity))
                                    }
                                }
                                .padding(.bottom, .spacingM)
                            }
                        }
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.isSearchActive)

                        Spacer(minLength: .spacingXXL)
                    }
                }
            }
            .navigationBarHidden(true)
            .background(Color(UIColor.systemGroupedBackground))
            .refreshable { await viewModel.loadVehicles() }
            .task { await viewModel.loadVehicles() }
        }
    }

    // MARK: - Helpers
    private var resultsTitle: String {
        if viewModel.isSearchActive { return "Search Results" }
        if let category = viewModel.selectedCategory { return category.rawValue }
        return "All Vehicles"
    }

    private var emptyStateMessage: String {
        guard viewModel.isSearchActive else {
            return "Try adjusting your category filter."
        }
        let vehicle = viewModel.selectedVehicleName ?? "vehicle"
        let branch  = viewModel.selectedBranch?.rawValue ?? "this branch"
        return "No \(vehicle) available at \(branch) for the selected dates.\nTry different dates, another branch, or another vehicle type."
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
