import SwiftUI

struct AllVehiclesView: View {
    let initialCategory: Vehicle.VehicleCategory?

    @StateObject private var viewModel = AllVehiclesViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var vehicleColumns: [GridItem] {
        if horizontalSizeClass == .regular {
            return [GridItem(.adaptive(minimum: 360, maximum: 560), spacing: .spacingM)]
        } else {
            return [GridItem(.flexible())]
        }
    }

    init(initialCategory: Vehicle.VehicleCategory? = nil) {
        self.initialCategory = initialCategory
    }

    var body: some View {
        VStack(spacing: 0) {

            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.fallbackNavy)
                        .frame(width: 36, height: 36)
                        .background(Color.gray.opacity(0.09))
                        .clipShape(Circle())
                }

                Spacer()

                Text("Available Vehicles")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.fallbackNavy)

                Spacer()

                Color.clear.frame(width: 36, height: 36)
            }
            .padding(.horizontal, .spacingM)
            .padding(.top, .spacingS)
            .padding(.bottom, .spacingM)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {

                    AVCategoryChip(
                        title: "All",
                        isSelected: viewModel.selectedCategory == nil
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewModel.selectedCategory = nil
                        }
                    }

                    ForEach(Vehicle.VehicleCategory.allCases, id: \.self) { cat in
                        AVCategoryChip(
                            title: cat.rawValue,
                            isSelected: viewModel.selectedCategory == cat
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                viewModel.selectedCategory =
                                    viewModel.selectedCategory == cat ? nil : cat
                            }
                        }
                    }
                }
                .padding(.horizontal, .spacingM)
            }
            .padding(.bottom, .spacingM)

            if viewModel.isLoading {
                Spacer()
                ProgressView("Finding vehicles…")
                    .foregroundStyle(.secondary)
                Spacer()
            } else if viewModel.filteredVehicles.isEmpty {
                Spacer()
                ContentUnavailableView(
                    "No Vehicles Found",
                    systemImage: "car.fill",
                    description: Text("No vehicles in this category right now.\nTry selecting a different type.")
                )
                Spacer()
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: vehicleColumns, spacing: .spacingM) {
                        ForEach(viewModel.filteredVehicles) { vehicle in
                            VehicleCard(vehicle: vehicle)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, .spacingM)
                    .padding(.vertical, .spacingS)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8),
                               value: viewModel.selectedCategory)
                }
            }
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .navigationBarHidden(true)
        .task {
            await viewModel.load()
            viewModel.selectedCategory = initialCategory
        }
    }
}

private struct AVCategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .bold : .regular))
                .foregroundStyle(isSelected ? .white : Color.fallbackNavy)
                .padding(.horizontal, 20)
                .padding(.vertical, 9)
                .background(
                    isSelected
                        ? Color.fallbackBlue
                        : Color.clear
                )
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(
                            isSelected ? Color.clear : Color.fallbackNavy.opacity(0.35),
                            lineWidth: 1.5
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

@MainActor
final class AllVehiclesViewModel: ObservableObject {
    @Published var allVehicles: [Vehicle] = []
    @Published var selectedCategory: Vehicle.VehicleCategory?
    @Published var isLoading = false

    private let firestoreService = FirestoreService.shared

    var filteredVehicles: [Vehicle] {
        guard let cat = selectedCategory else { return allVehicles }
        return allVehicles.filter { $0.category == cat }
    }

    func load() async {
        isLoading = true
        do {
            let fetched = try await firestoreService.fetchVehicles()
            allVehicles = fetched.isEmpty ? SeedData.vehicles : fetched
        } catch {
            allVehicles = SeedData.vehicles
        }
        isLoading = false
    }
}

#Preview {
    AllVehiclesView()
}
