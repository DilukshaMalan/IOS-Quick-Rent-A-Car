import SwiftUI

// MARK: - Unified Booking Search Card (Change 2 + 3)
/// Replaces the old SearchBarView. Branch picker, vehicle picker and both
/// date pickers live inside a single elevated card so they feel like one action.
struct BookingSearchCard: View {
    @Binding var selectedBranch: Branch?
    @Binding var selectedVehicleName: String?
    let vehicleNames: [String]
    @Binding var pickupDate: Date
    @Binding var returnDate: Date
    let onSearch: () -> Void

    var body: some View {
        VStack(spacing: 0) {

            // MARK: — Branch row
            pickerRow(
                icon: "location.fill",
                iconColor: Color.fallbackBlue,
                label: "Pick-up location",
                value: selectedBranch?.rawValue ?? "Any branch"
            ) {
                Menu {
                    Picker("Branch", selection: $selectedBranch) {
                        Text("Any branch").tag(Branch?.none)
                        ForEach(Branch.allCases) { b in
                            Label(b.rawValue, systemImage: b.icon)
                                .tag(Branch?.some(b))
                        }
                    }
                } label: {
                    dropdownRowContent(
                        icon: "location.fill",
                        iconColor: Color.fallbackBlue,
                        label: "Pick-up location",
                        value: selectedBranch?.rawValue ?? "Any branch",
                        isPlaceholder: selectedBranch == nil
                    )
                }
            }

            divider

            // MARK: — Vehicle row
            Menu {
                Picker("Vehicle", selection: $selectedVehicleName) {
                    Text("Any vehicle").tag(String?.none)
                    ForEach(vehicleNames, id: \.self) { n in
                        Text(n).tag(String?.some(n))
                    }
                }
            } label: {
                dropdownRowContent(
                    icon: "car.fill",
                    iconColor: Color.fallbackNavy,
                    label: "Vehicle",
                    value: selectedVehicleName ?? "Any vehicle",
                    isPlaceholder: selectedVehicleName == nil
                )
            }

            divider

            // MARK: — Dates row (inline, side by side)
            HStack(spacing: 0) {
                // Pick-up date
                dateCell(
                    icon: "arrow.up.circle.fill",
                    iconColor: .green,
                    label: "Pick-up",
                    date: $pickupDate,
                    minDate: Date()
                )

                Divider()
                    .frame(height: 52)

                // Return date
                dateCell(
                    icon: "arrow.down.circle.fill",
                    iconColor: .orange,
                    label: "Return",
                    date: $returnDate,
                    minDate: pickupDate.adding(days: 1)
                )
            }
            .padding(.horizontal, .spacingM)
            .padding(.vertical, .spacingS)

            divider

            // MARK: — Search button
            Button(action: onSearch) {
                HStack(spacing: .spacingS) {
                    Image(systemName: "magnifyingglass")
                        .fontWeight(.semibold)
                    Text("Search Vehicles")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.fallbackBlue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding([.horizontal, .bottom], .spacingM)
                .padding(.top, .spacingS)
            }
        }
        .background(Color.fallbackCardBg)
        .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusL))
        .shadow(color: .black.opacity(0.10), radius: 12, x: 0, y: 4)
    }

    // MARK: - Sub-views

    private var divider: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.12))
            .frame(height: 1)
            .padding(.horizontal, .spacingM)
    }

    /// Tappable row that opens a menu — used by branch and vehicle pickers.
    @ViewBuilder
    private func pickerRow(
        icon: String, iconColor: Color,
        label: String, value: String,
        @ViewBuilder content: () -> some View
    ) -> some View {
        content()
    }

    @ViewBuilder
    private func dropdownRowContent(
        icon: String, iconColor: Color,
        label: String, value: String,
        isPlaceholder: Bool
    ) -> some View {
        HStack(spacing: .spacingM) {
            Image(systemName: icon)
                .foregroundStyle(iconColor)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.weight(isPlaceholder ? .regular : .medium))
                    .foregroundStyle(isPlaceholder ? .secondary : Color.fallbackNavy)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.up.chevron.down")
                .font(.caption2)
                .foregroundStyle(Color.secondary)
        }
        .padding(.horizontal, .spacingM)
        .padding(.vertical, 14)
    }

    @ViewBuilder
    private func dateCell(
        icon: String, iconColor: Color,
        label: String, date: Binding<Date>,
        minDate: Date
    ) -> some View {
        HStack(spacing: .spacingS) {
            Image(systemName: icon)
                .foregroundStyle(iconColor)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                DatePicker(
                    "",
                    selection: date,
                    in: minDate...,
                    displayedComponents: [.date]
                )
                .labelsHidden()
                .scaleEffect(0.85, anchor: .leading)
                .frame(height: 28)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, .spacingXS)
    }
}

#Preview {
    BookingSearchCard(
        selectedBranch: .constant(.colombo),
        selectedVehicleName: .constant(nil),
        vehicleNames: ["Toyota Aqua", "Honda CR-V", "Toyota HiAce"],
        pickupDate: .constant(Date()),
        returnDate: .constant(Date().adding(days: 3)),
        onSearch: {}
    )
    .padding()
}
