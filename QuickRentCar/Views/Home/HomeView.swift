import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @StateObject private var viewModel = HomeViewModel()
    @State private var navPath = NavigationPath()
    @State private var navStackId = UUID()

    private var vehicleColumns: [GridItem] {
        if horizontalSizeClass == .regular {
            return [GridItem(.adaptive(minimum: 360, maximum: 560), spacing: .spacingM)]
        } else {
            return [GridItem(.flexible())]
        }
    }

    private enum ScrollAnchor: String { case results }

    var body: some View {
        NavigationStack(path: $navPath) {
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {

                        HomeTopBarView(
                            userName: authViewModel.currentUser?.firstName ?? "there"
                        )

                        if !viewModel.isSearchActive {
                            HeroBannerView()
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }

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
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                    withAnimation(.easeInOut(duration: 0.4)) {
                                        proxy.scrollTo(ScrollAnchor.results.rawValue, anchor: .top)
                                    }
                                }
                            }
                        )
                        .padding(.horizontal, .spacingM)
                        .frame(maxWidth: 720)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .offset(y: viewModel.isSearchActive ? 0 : -28)
                        .padding(.bottom, viewModel.isSearchActive ? 0 : -28)
                        .animation(.spring(response: 0.45, dampingFraction: 0.82), value: viewModel.isSearchActive)

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

                        CategoryFilterView(selectedCategory: $viewModel.selectedCategory)
                            .padding(.top, .spacingL)

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

                        VStack(alignment: .leading, spacing: 0) {

                            HStack(alignment: .bottom) {
                                SectionHeader(
                                    title: resultsTitle,
                                    subtitle: viewModel.resultsSubtitle
                                )
                                Spacer()
                                if viewModel.isSearchActive {
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
                            .id(ScrollAnchor.results.rawValue)

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
                                LazyVGrid(columns: vehicleColumns, spacing: .spacingM) {
                                    ForEach(viewModel.filteredVehicles) { vehicle in
                                        NavigationLink(destination: VehicleDetailView(vehicle: vehicle)) {
                                            VehicleCard(vehicle: vehicle)
                                        }
                                        .buttonStyle(.plain)
                                        .transition(.move(edge: .bottom).combined(with: .opacity))
                                    }
                                }
                                .padding(.horizontal, .spacingM)
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
            .onReceive(NotificationCenter.default.publisher(for: .navigateToHome)) { _ in
                navPath = NavigationPath()
                navStackId = UUID()
            }
        }
        .id(navStackId)
    }

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
