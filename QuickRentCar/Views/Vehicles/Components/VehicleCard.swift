import SwiftUI

struct VehicleCard: View {
    let vehicle: Vehicle

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            HStack(alignment: .center, spacing: .spacingM) {

                RemoteImageView(url: vehicle.imageURL)
                    .frame(width: 110, height: 90)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .background(Color.gray.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 5) {

                    Text(vehicle.name)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Color.fallbackNavy)
                        .lineLimit(1)

                    Text([
                        "\(vehicle.passengerCapacity) Seats",
                        vehicle.fuelType.rawValue,
                        vehicle.transmission.rawValue
                    ].joined(separator: " • "))
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                    Text("\(vehicle.includedMileage) km/day included")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)

                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text(PriceCalculator.format(vehicle.dailyPrice))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color.fallbackNavy)
                        Text("/ day")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, .spacingM)
            .padding(.top, .spacingM)
            .padding(.bottom, .spacingM)

            NavigationLink(destination: VehicleDetailView(vehicle: vehicle)) {
                Text("View Details")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.fallbackBlue)
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                    .padding(.horizontal, .spacingM)
                    .padding(.bottom, .spacingM)
            }
        }
        .background(Color.fallbackCardBg)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
    }
}

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

typealias SpecBadge = SpecPill

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            VehicleCard(vehicle: Vehicle.sampleVehicles[0])
            VehicleCard(vehicle: Vehicle.sampleVehicles[1])
        }
        .padding()
    }
    .background(Color(UIColor.systemGroupedBackground))
}
