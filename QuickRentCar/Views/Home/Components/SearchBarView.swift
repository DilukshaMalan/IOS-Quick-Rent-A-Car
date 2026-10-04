import SwiftUI

/// Pickup branch + vehicle pickers and the Search button.
struct SearchBarView: View {
    @Binding var selectedBranch: Branch?
    @Binding var selectedVehicleName: String?
    let vehicleNames: [String]
    let onSearch: () -> Void

    var body: some View {
        VStack(spacing: .spacingS) {
            // MARK: Pickup branch
            Menu {
                Picker("Pickup branch", selection: $selectedBranch) {
                    Text("Any branch").tag(Branch?.none)

                    ForEach(Branch.allCases) { branch in
                        Text(branch.rawValue).tag(Branch?.some(branch))
                    }
                }
            } label: {
                dropdownField(
                    icon: "location.fill",
                    text: selectedBranch?.rawValue ?? "Any branch",
                    isPlaceholder: selectedBranch == nil
                )
            }

            // MARK: Vehicle
            Menu {
                Picker("Vehicle", selection: $selectedVehicleName) {
                    Text("Any vehicle").tag(String?.none)

                    ForEach(vehicleNames, id: \.self) { name in
                        Text(name).tag(String?.some(name))
                    }
                }
            } label: {
                dropdownField(
                    icon: "car.fill",
                    text: selectedVehicleName ?? "Any vehicle",
                    isPlaceholder: selectedVehicleName == nil
                )
            }

            // MARK: Search
            Button(action: onSearch) {
                Label("Search", systemImage: "magnifyingglass")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, .spacingS)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.fallbackBlue)
        }
    }

    /// The tappable row that opens a dropdown menu.
    private func dropdownField(icon: String, text: String, isPlaceholder: Bool) -> some View {
        HStack(spacing: .spacingS) {
            Image(systemName: icon)
                .foregroundStyle(Color.fallbackBlue)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(isPlaceholder ? Color.secondary : Color.fallbackNavy)
                .lineLimit(1)

            Spacer()

            Image(systemName: "chevron.up.chevron.down")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusM))
    }
}

#Preview {
    SearchBarView(
        selectedBranch: .constant(.katunayakeAirport),
        selectedVehicleName: .constant(nil),
        vehicleNames: ["Honda CR-V", "Toyota Aqua", "Toyota HiAce"],
        onSearch: {}
    )
    .padding()
}
