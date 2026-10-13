import SwiftUI

// MARK: - Simplified Vehicle List Card (Change 5)
struct VehicleCard: View {
    let vehicle: Vehicle

    var body: some View {
        HStack(spacing: 0) {

            // MARK: — Left: image
            RemoteImageView(url: vehicle.imageURL)
                .frame(width: 120, height: 95)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: .cornerRadiusM,
                        bottomLeadingRadius: .cornerRadiusM,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 0
                    )
                )

            // MARK: — Right: info
            VStack(alignment: .leading, spacing: .spacingXS) {

                // Name + chevron
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(vehicle.name)
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.fallbackNavy)
                            .lineLimit(1)

                        // Category badge
                        Text(vehicle.category.rawValue.uppercased())
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Color.fallbackBlue)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(Color.fallbackBlue.opacity(0.10))
                            .clipShape(Capsule())
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(Color.secondary)
                }

                // Location
                Label(vehicle.location, systemImage: "mappin.and.ellipse")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Spacer()

                // Bottom row: 2 key specs + price
                HStack(spacing: .spacingS) {
                    // Only show the two most useful specs
                    SpecPill(icon: "person.2.fill",  value: "\(vehicle.passengerCapacity) seats")
                    SpecPill(icon: "fuelpump.fill",   value: vehicle.fuelType.rawValue)

                    Spacer()

                    // Price — prominent
                    VStack(alignment: .trailing, spacing: 0) {
                        Text(PriceCalculator.format(vehicle.dailyPrice))
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.fallbackBlue)
                        Text("/ day")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, .spacingM)
            .padding(.vertical, .spacingM)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.fallbackCardBg)
        .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusM))
        .shadow(color: .black.opacity(0.07), radius: 8, x: 0, y: 3)
    }
}

// MARK: - Spec Pill (only 2 shown — cleaner than 3)
struct SpecPill: View {
    let icon: String
    let value: String

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 9))
            Text(value)
                .font(.system(size: 10))
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(Color.gray.opacity(0.08))
        .clipShape(Capsule())
    }
}

// Keep the old SpecBadge name so other files that use it still compile
typealias SpecBadge = SpecPill

#Preview {
    VStack(spacing: 12) {
        VehicleCard(vehicle: Vehicle.sampleVehicles[0])
        VehicleCard(vehicle: Vehicle.sampleVehicles[1])
    }
    .padding()
}
