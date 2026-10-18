import SwiftUI

// MARK: - Section title
struct SectionLabel: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(.headline)
            .foregroundStyle(Color.fallbackNavy)
    }
}

// MARK: - Shared field look
private extension View {
    func branchFieldStyle() -> some View {
        self
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.gray.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusS))
    }
}

// MARK: - Location section
/// Pick-up is fixed to the vehicle's own branch; drop-off defaults to the same branch
/// and can be switched to any other branch from a menu (no typing).
struct BookingLocationSection: View {
    let pickupLocation: String
    @Binding var dropOffLocation: String
    @State private var sameAsPickup = true

    var body: some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            SectionLabel("Location")

            BranchInfoRow(
                icon: "arrow.up.circle.fill",
                title: "Pick-up branch",
                branchName: pickupLocation,
                caption: "Where this vehicle is based"
            )

            Toggle("Return to the same branch", isOn: $sameAsPickup)
                .font(.subheadline)
                .tint(Color.fallbackBlue)

            if !sameAsPickup {
                DropOffBranchMenu(selection: $dropOffLocation, pickupLocation: pickupLocation)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: sameAsPickup)
        .onChange(of: sameAsPickup) { _, isOn in
            if isOn { dropOffLocation = pickupLocation }
        }
    }
}

/// Read-only branch row (used for the fixed pick-up branch).
struct BranchInfoRow: View {
    let icon: String
    let title: String
    let branchName: String
    var caption: String? = nil

    var body: some View {
        HStack(spacing: .spacingM) {
            Image(systemName: icon).foregroundStyle(Color.fallbackBlue)

            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.caption).foregroundStyle(.secondary)
                Text(Branch(rawValue: branchName)?.displayName ?? branchName)
                    .font(.subheadline.weight(.medium))
                if let caption {
                    Text(caption).font(.caption2).foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "lock.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .branchFieldStyle()
    }
}

/// Drop-off branch chooser — a menu of the known branches.
struct DropOffBranchMenu: View {
    @Binding var selection: String
    let pickupLocation: String

    private var options: [String] {
        var names = Branch.allCases.map(\.rawValue)
        // Safety net for older vehicles whose location isn't one of the known branches
        if !names.contains(pickupLocation) { names.insert(pickupLocation, at: 0) }
        return names
    }

    var body: some View {
        Menu {
            Picker("Drop-off branch", selection: $selection) {
                ForEach(options, id: \.self) { name in
                    Label(name, systemImage: Branch(rawValue: name)?.icon ?? "mappin.and.ellipse")
                        .tag(name)
                }
            }
        } label: {
            HStack(spacing: .spacingM) {
                Image(systemName: "arrow.down.circle.fill").foregroundStyle(Color.fallbackBlue)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Drop-off branch").font(.caption).foregroundStyle(.secondary)
                    Text(Branch(rawValue: selection)?.displayName ?? selection)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .branchFieldStyle()
        }
    }
}
