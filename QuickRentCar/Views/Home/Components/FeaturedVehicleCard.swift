import SwiftUI

// MARK: - Featured Vehicle Card
struct FeaturedVehicleCard: View {
    let vehicle: Vehicle

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RemoteImageView(url: vehicle.imageURL)
                .frame(width: 160, height: 110)
                .clipped()
                .overlay(alignment: .topTrailing) {
                    HStack(spacing: 3) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(.yellow)
                        Text(String(format: "%.1f", vehicle.rating))
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .padding(8)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(vehicle.name)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.fallbackNavy)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    Text(vehicle.location)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                HStack(spacing: 2) {
                    Text(PriceCalculator.format(vehicle.dailyPrice))
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.fallbackBlue)
                    Text("/ day")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(10)
        }
        .frame(width: 160)
        .background(Color.fallbackCardBg)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 3)
    }
}

#Preview {
    HStack(spacing: 12) {
        FeaturedVehicleCard(vehicle: Vehicle.sampleVehicles[0])
        FeaturedVehicleCard(vehicle: Vehicle.sampleVehicles[1])
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}
