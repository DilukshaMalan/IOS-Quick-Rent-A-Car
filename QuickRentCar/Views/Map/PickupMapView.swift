import SwiftUI
import MapKit

struct PickupMapView: View {
    @StateObject private var viewModel = MapViewModel()
    @Environment(\.dismiss) var dismiss

    let booking: Booking
    let pickupCoordinate: CLLocationCoordinate2D

    var body: some View {
        ZStack(alignment: .bottom) {
            // MARK: - Map
            Map(initialPosition: .region(MKCoordinateRegion(
                center: pickupCoordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))) {
                // Vehicle/pickup location
                Annotation("Pickup", coordinate: pickupCoordinate, anchor: .bottom) {
                    Image(systemName: "car.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .padding(.spacingS)
                        .background(Color.fallbackBlue)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }

                // Geofence circle
                MapCircle(center: pickupCoordinate, radius: Constants.Location.geofenceRadiusMeters)
                    .foregroundStyle(Color.fallbackBlue.opacity(0.12))
                    .stroke(Color.fallbackBlue, lineWidth: 2)

                // User location
                UserAnnotation()
            }
            .ignoresSafeArea(edges: .top)

            // MARK: - Bottom Sheet
            VStack(spacing: .spacingM) {
                // Status
                HStack {
                    VStack(alignment: .leading, spacing: .spacingXS) {
                        Text("Pickup Location")
                            .font(.headline)
                            .foregroundStyle(Color.fallbackNavy)
                        Text(booking.pickupLocation)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()

                    VStack(alignment: .trailing) {
                        Text(viewModel.distanceToPickup)
                            .font(.title3.bold())
                            .foregroundStyle(Color.fallbackBlue)
                        Text("away")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Geofence status
                if viewModel.isInPickupZone {
                    Label("You're in the pickup zone!", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusS))
                }

                // Open in Maps
                Button {
                    let url = URL(string: "maps://?daddr=\(pickupCoordinate.latitude),\(pickupCoordinate.longitude)")!
                    UIApplication.shared.open(url)
                } label: {
                    Label("Get Directions", systemImage: "arrow.triangle.turn.up.right.circle.fill")
                        .primaryButtonStyle()
                }
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusL))
            .padding()
        }
        .navigationTitle("Pickup")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.setup(
                pickupCoord: pickupCoordinate,
                returnCoord: pickupCoordinate,
                bookingId: booking.id ?? ""
            )
            LocationService.shared.requestPermission()
        }
        .onDisappear { viewModel.stopMonitoring() }
    }
}

#Preview {
    NavigationStack {
        PickupMapView(
            booking: Booking(
                userId: "1", vehicleId: "1", vehicleName: "Toyota Camry",
                vehicleImageURL: "", pickupLocation: "Colombo Fort",
                dropOffLocation: "Colombo Fort", pickupDate: Date(),
                returnDate: Date().adding(days: 3), totalDays: 3,
                dailyRate: 65, totalPrice: 195
            ),
            pickupCoordinate: CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612)
        )
    }
}
