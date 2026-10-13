import SwiftUI

// MARK: - Featured Vehicle Card (refreshed)
struct FeaturedVehicleCard: View {
    let vehicle: Vehicle

    var body: some View {
        ZStack(alignment: .bottom) {

            // MARK: — Background image
            RemoteImageView(url: vehicle.imageURL)
                .frame(width: 220, height: 155)
                .clipped()

            // MARK: — Gradient scrim (bottom two-thirds)
            LinearGradient(
                colors: [
                    Color.fallbackNavy.opacity(0.85),
                    Color.fallbackNavy.opacity(0.4),
                    Color.clear
                ],
                startPoint: .bottom,
                endPoint: .top
            )
            .frame(height: 110)
            .frame(maxHeight: .infinity, alignment: .bottom)

            // MARK: — Content overlay
            VStack(alignment: .leading, spacing: 4) {

                // Rating badge top-right
                HStack {
                    Spacer()
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
                }

                Spacer()

                // Category chip
                Text(vehicle.category.rawValue.uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.fallbackBlue.opacity(0.75))
                    .clipShape(Capsule())

                // Name
                Text(vehicle.name)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .lineLimit(1)

                // Price row
                HStack(spacing: 4) {
                    Text(PriceCalculator.format(vehicle.dailyPrice))
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                    Text("/ day")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
        }
        .frame(width: 220, height: 155)
        .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusM))
        .shadow(color: .black.opacity(0.20), radius: 10, x: 0, y: 5)
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
