import SwiftUI

struct FeaturedVehicleCard: View {
    let vehicle: Vehicle

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background image
            RemoteImageView(url: vehicle.imageURL)
                .frame(width: 240, height: 160)
                .clipped()

            // Gradient overlay
            LinearGradient.heroGradient
                .frame(height: 100)
                .frame(maxHeight: .infinity, alignment: .bottom)

            // Text info
            VStack(alignment: .leading, spacing: 2) {
                Text(vehicle.name)
                    .font(.headline)
                    .foregroundStyle(.white)

                HStack {
                    Text(PriceCalculator.format(vehicle.dailyPrice) + "/day")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))

                    Spacer()

                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                        Text(String(format: "%.1f", vehicle.rating))
                            .font(.caption)
                            .foregroundStyle(.white)
                    }
                }
            }
            .padding()
        }
        .frame(width: 240, height: 160)
        .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusM))
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    FeaturedVehicleCard(vehicle: Vehicle.sampleVehicles[0])
        .padding()
}
