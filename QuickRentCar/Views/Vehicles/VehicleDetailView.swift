import SwiftUI

struct VehicleDetailView: View {
    let vehicle: Vehicle
    @State private var showBooking = false
    @State private var showAR = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // MARK: - Hero Image
                RemoteImageView(url: vehicle.imageURL)
                    .frame(maxWidth: .infinity)
                    .frame(height: 260)
                    .clipped()

                VStack(alignment: .leading, spacing: .spacingL) {
                    // MARK: - Title Row
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

                    // MARK: - Rating
                    HStack {
                        Image(systemName: "star.fill").foregroundStyle(.yellow)
                        Text(String(format: "%.1f", vehicle.rating))
                            .fontWeight(.semibold)
                        Text("(\(vehicle.reviewCount) reviews)")
                            .foregroundStyle(.secondary)
                    }
                    .font(.subheadline)

                    Divider()

                    // MARK: - Specs
                    Text("Specifications")
                        .font(.headline)
                        .foregroundStyle(Color.fallbackNavy)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: .spacingM) {
                        SpecRow(icon: "person.2.fill", label: "Passengers", value: "\(vehicle.passengerCapacity)")
                        SpecRow(icon: "fuelpump.fill", label: "Fuel Type", value: vehicle.fuelType.rawValue)
                        SpecRow(icon: "gearshift.layout.sixspeed", label: "Transmission", value: vehicle.transmission.rawValue)
                        SpecRow(icon: "road.lanes", label: "Mileage", value: "\(vehicle.includedMileage) km/day")
                    }

                    Divider()

                    // MARK: - Description
                    Text("About this vehicle")
                        .font(.headline)
                        .foregroundStyle(Color.fallbackNavy)

                    Text(vehicle.description)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    // MARK: - CTAs
                    VStack(spacing: .spacingM) {
                        Button("Book Now") { showBooking = true }
                            .primaryButtonStyle()

                        Button {
                            showAR = true
                        } label: {
                            Label("View in AR", systemImage: "arkit")
                                .secondaryButtonStyle()
                        }
                    }
                }
                .padding(.horizontal, .spacingL)
                .padding(.vertical, .spacingL)
            }
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showBooking) {
            BookingView(vehicle: vehicle)
        }
        .sheet(isPresented: $showAR) {
            ARPreviewView()
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
