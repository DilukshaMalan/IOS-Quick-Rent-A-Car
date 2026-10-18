import SwiftUI

struct BookingSuccessView: View {
    let vehicleName: String
    let bookingId: String
    @State private var navigateToBookings = false

    var body: some View {
        VStack(spacing: .spacingXL) {
            Spacer()

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.fallbackBlue)
                .symbolEffect(.bounce)

            VStack(spacing: .spacingS) {
                Text("Booking Confirmed!")
                    .font(.title.bold())
                    .foregroundStyle(Color.fallbackNavy)

                Text("Your \(vehicleName) has been booked successfully.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Text("Booking ID: \(bookingId.prefix(8).uppercased())")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, .spacingXS)
            }

            Spacer()

            Button("View My Bookings") { navigateToBookings = true }
                .primaryButtonStyle()
                .padding(.horizontal, .spacingL)
                .padding(.bottom, .spacingXL)
        }
        .navigationBarBackButtonHidden()
    }
}

#Preview {
    NavigationStack {
        BookingSuccessView(vehicleName: "Toyota Camry", bookingId: "ABCD1234EFGH")
    }
}
