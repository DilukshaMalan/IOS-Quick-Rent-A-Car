import SwiftUI

// MARK: - Simplified Search Card (Figma-style)
/// Pick-up location row + Pick-up & Drop-off dates side by side + Search button.
/// Vehicle picker removed — vehicle type is handled by the category filter below.
struct BookingSearchCard: View {
    @Binding var selectedBranch: Branch?
    @Binding var selectedVehicleName: String?   // kept for ViewModel compatibility, not shown in UI
    let vehicleNames: [String]                  // kept for ViewModel compatibility, not shown in UI
    @Binding var pickupDate: Date
    @Binding var returnDate: Date
    let onSearch: () -> Void

    var body: some View {
        VStack(spacing: 0) {

            // MARK: Row 1 — Pick-up location
            Menu {
                Picker("Branch", selection: $selectedBranch) {
                    Text("Any branch").tag(Branch?.none)
                    ForEach(Branch.allCases) { b in
                        Label(b.rawValue, systemImage: b.icon)
                            .tag(Branch?.some(b))
                    }
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.fallbackBlue)
                        .frame(width: 20)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Pick-up Location")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(selectedBranch?.rawValue ?? "Select a branch")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(selectedBranch == nil ? .secondary : Color.fallbackNavy)
                            .lineLimit(1)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, .spacingM)
                .padding(.vertical, 14)
            }

            // Divider
            Rectangle()
                .fill(Color.gray.opacity(0.12))
                .frame(height: 1)
                .padding(.horizontal, .spacingM)

            // MARK: Row 2 — Dates side by side (exactly like Figma)
            HStack(spacing: 0) {

                // Pick-up date
                VStack(alignment: .leading, spacing: 3) {
                    Label("Pick-up Date", systemImage: "calendar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    DatePicker(
                        "",
                        selection: $pickupDate,
                        in: Date()...,
                        displayedComponents: [.date]
                    )
                    .labelsHidden()
                    .scaleEffect(0.88, anchor: .leading)
                    .frame(height: 26)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, .spacingM)
                .padding(.vertical, 12)

                // Vertical separator
                Rectangle()
                    .fill(Color.gray.opacity(0.12))
                    .frame(width: 1, height: 50)

                // Drop-off date
                VStack(alignment: .leading, spacing: 3) {
                    Label("Drop-off Date", systemImage: "calendar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    DatePicker(
                        "",
                        selection: $returnDate,
                        in: pickupDate.adding(days: 1)...,
                        displayedComponents: [.date]
                    )
                    .labelsHidden()
                    .scaleEffect(0.88, anchor: .leading)
                    .frame(height: 26)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, .spacingM)
                .padding(.vertical, 12)
            }

            // Divider
            Rectangle()
                .fill(Color.gray.opacity(0.12))
                .frame(height: 1)
                .padding(.horizontal, .spacingM)

            // MARK: Row 3 — Search button (full width, Figma blue)
            Button(action: onSearch) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 15, weight: .bold))
                    Text("Search Vehicles")
                        .font(.system(size: 15, weight: .bold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.fallbackBlue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding([.horizontal, .bottom], .spacingM)
            .padding(.top, .spacingS)
        }
        .background(Color.fallbackCardBg)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 6)
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.1).ignoresSafeArea()
        BookingSearchCard(
            selectedBranch: .constant(.colombo),
            selectedVehicleName: .constant(nil),
            vehicleNames: ["Toyota Aqua", "Honda CR-V"],
            pickupDate: .constant(Date()),
            returnDate: .constant(Date().adding(days: 3)),
            onSearch: {}
        )
        .padding()
    }
}
