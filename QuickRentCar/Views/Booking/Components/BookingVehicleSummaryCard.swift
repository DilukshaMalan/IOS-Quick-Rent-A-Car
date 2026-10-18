import SwiftUI

struct BookingVehicleSummaryCard: View {
    let vehicle: Vehicle

    var body: some View {
        HStack(spacing: .spacingM) {
            RemoteImageView(url: vehicle.imageURL)
                .frame(width: 96, height: 70)
                .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusS))

            VStack(alignment: .leading, spacing: .spacingXS) {
                Text(vehicle.name)
                    .font(.headline)
                    .lineLimit(1)

                Text("\(vehicle.category.rawValue) · \(vehicle.transmission.rawValue) · \(vehicle.seats) seats")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text(PriceCalculator.format(vehicle.dailyPrice) + " / day")
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.fallbackBlue)
            }
            Spacer(minLength: 0)
        }
        .padding()
        .cardStyle()
    }
}

#Preview {
    BookingVehicleSummaryCard(vehicle: Vehicle.sampleVehicles[0])
        .padding()
}
