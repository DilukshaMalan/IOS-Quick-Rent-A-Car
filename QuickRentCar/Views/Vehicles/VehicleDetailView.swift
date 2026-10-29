import SwiftUI

struct VehicleDetailView: View {
    let vehicle: Vehicle
    @State private var showBooking = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        ScrollView {
            if horizontalSizeClass == .regular {
                HStack(alignment: .top, spacing: .spacingXL) {
                    VStack(alignment: .leading, spacing: .spacingL) {
                        RemoteImageView(url: vehicle.imageURL)
                            .frame(maxWidth: .infinity)
                            .frame(height: 340)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .clipped()

                        titleAndRatingSection
                    }
                    .frame(maxWidth: .infinity)

                    VStack(alignment: .leading, spacing: .spacingL) {
                        specificationsSection
                        Divider()
                        descriptionSection
                        Divider()
                        Button("Book Now") { showBooking = true }
                            .primaryButtonStyle()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.spacingL)
                    .background(Color.fallbackCardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                }
                .padding(.horizontal, .spacingXL)
                .padding(.vertical, .spacingXL)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    RemoteImageView(url: vehicle.imageURL)
                        .frame(maxWidth: .infinity)
                        .frame(height: 260)
                        .clipped()

                    VStack(alignment: .leading, spacing: .spacingL) {
                        titleAndRatingSection
                        Divider()
                        specificationsSection
                        Divider()
                        descriptionSection
                        Button("Book Now") { showBooking = true }
                            .primaryButtonStyle()
                    }
                    .padding(.horizontal, .spacingL)
                    .padding(.vertical, .spacingL)
                }
            }
        }
        .ignoresSafeArea(edges: horizontalSizeClass == .regular ? [] : .top)
        .toolbar(.hidden, for: .tabBar)
        .navigationDestination(isPresented: $showBooking) {
            BookingView(vehicle: vehicle)
        }
    }

    private var titleAndRatingSection: some View {
        VStack(alignment: .leading, spacing: .spacingM) {
            HStack {
                VStack(alignment: .leading, spacing: .spacingXS) {
                    Text(vehicle.name)
                        .font(.title.bold())
                        .foregroundStyle(Color.fallbackNavy)
                    Text(vehicle.brand + " · " + vehicle.category.rawValue)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(PriceCalculator.format(vehicle.dailyPrice))
                        .font(.title2.bold())
                        .foregroundStyle(Color.fallbackBlue)
                    Text("per day")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            HStack {
                Image(systemName: "star.fill").foregroundStyle(.yellow)
                Text(String(format: "%.1f", vehicle.rating))
                    .fontWeight(.semibold)
                Text("(\(vehicle.reviewCount) reviews)")
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)
        }
    }

    private var specificationsSection: some View {
        VStack(alignment: .leading, spacing: .spacingM) {
            Text("Specifications")
                .font(.headline)
                .foregroundStyle(Color.fallbackNavy)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: .spacingM) {
                SpecRow(icon: "person.2.fill", label: "Passengers", value: "\(vehicle.passengerCapacity)")
                SpecRow(icon: "fuelpump.fill", label: "Fuel Type", value: vehicle.fuelType.rawValue)
                SpecRow(icon: "gearshift.layout.sixspeed", label: "Transmission", value: vehicle.transmission.rawValue)
                SpecRow(icon: "road.lanes", label: "Mileage", value: "\(vehicle.includedMileage) km/day")
            }
        }
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            Text("About this vehicle")
                .font(.headline)
                .foregroundStyle(Color.fallbackNavy)

            Text(vehicle.description)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct SpecRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: .spacingS) {
            Image(systemName: icon)
                .foregroundStyle(Color.fallbackBlue)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 1) {
                Text(label).font(.caption).foregroundStyle(.secondary)
                Text(value).font(.subheadline.weight(.medium))
            }
        }
        .padding(.spacingM)
        .cardStyle(cornerRadius: 12)
    }
}

#Preview {
    NavigationStack {
        VehicleDetailView(vehicle: Vehicle.sampleVehicles[0])
    }
}
