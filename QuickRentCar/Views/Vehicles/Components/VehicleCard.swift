import SwiftUI

struct VehicleCard: View {
    let vehicle: Vehicle

    var body: some View {
        HStack(spacing: .spacingM) {
            // Vehicle image
            RemoteImageView(url: vehicle.imageURL)
                .frame(width: 110, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusS))

            // Info
            VStack(alignment: .leading, spacing: .spacingXS) {
                Text(vehicle.name)
                    .font(.headline)
                    .foregroundStyle(Color.fallbackNavy)
                    .lineLimit(1)

                Text(vehicle.category.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Label(vehicle.location, systemImage: "mappin.and.ellipse")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                // Specs row
                HStack(spacing: .spacingS) {
                    SpecBadge(icon: "person.2.fill", value: "\(vehicle.passengerCapacity)")
                    SpecBadge(icon: "fuelpump.fill", value: vehicle.fuelType.rawValue)
                    SpecBadge(icon: "gearshift.layout.sixspeed", value: vehicle.transmission.rawValue)
                }

                // Price row
                HStack {
                    Text(PriceCalculator.format(vehicle.dailyPrice))
                        .font(.headline)
                        .foregroundStyle(Color.fallbackBlue)
                    Text("/day")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                        Text(String(format: "%.1f", vehicle.rating))
                            .foregroundStyle(.secondary)
                    }
                    .font(.caption)
                }
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .cardStyle()
    }
}

struct SpecBadge: View {
    let icon: String
    let value: String

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: icon)
            Text(value)
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color.gray.opacity(0.08))
        .clipShape(Capsule())
    }
}

#Preview {
    VehicleCard(vehicle: Vehicle.sampleVehicles[0])
        .padding()
}
