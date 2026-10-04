import SwiftUI

struct BookingView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel: BookingViewModel
    @State private var showConfirmation = false

    init(vehicle: Vehicle) {
        _viewModel = StateObject(wrappedValue: BookingViewModel(vehicle: vehicle))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: .spacingL) {
                // MARK: - Vehicle Summary
                HStack(spacing: .spacingM) {
                    RemoteImageView(url: viewModel.vehicle.imageURL)
                        .frame(width: 90, height: 65)
                        .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusS))

                    VStack(alignment: .leading, spacing: .spacingXS) {
                        Text(viewModel.vehicle.name)
                            .font(.headline)
                        Text(PriceCalculator.format(viewModel.vehicle.dailyPrice) + "/day")
                            .foregroundStyle(Color.fallbackBlue)
                    }
                    Spacer()
                }
                .padding()
                .cardStyle()

                // MARK: - Location
                VStack(alignment: .leading, spacing: .spacingS) {
                    SectionLabel("Location")

                    LocationField(icon: "arrow.up.circle.fill", placeholder: "Pickup location", text: $viewModel.pickupLocation)
                    LocationField(icon: "arrow.down.circle.fill", placeholder: "Drop-off location", text: $viewModel.dropOffLocation)
                }

                // MARK: - Dates
                VStack(alignment: .leading, spacing: .spacingS) {
                    SectionLabel("Rental Period")

                    HStack(spacing: .spacingM) {
                        DateSection(label: "Pick Up", date: $viewModel.pickupDate)
                        DateSection(label: "Return", date: $viewModel.returnDate)
                    }

                    Text("\(viewModel.rentalDays) day\(viewModel.rentalDays == 1 ? "" : "s") rental")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // MARK: - Price Summary
                VStack(alignment: .leading, spacing: .spacingS) {
                    SectionLabel("Price Breakdown")

                    PriceSummaryView(
                        dailyRate: viewModel.vehicle.dailyPrice,
                        days: viewModel.rentalDays,
                        subtotal: viewModel.subtotal,
                        tax: viewModel.taxAmount,
                        total: viewModel.totalPrice
                    )
                }

                // MARK: - Error
                if let error = viewModel.errorMessage {
                    Text(error).font(.caption).foregroundStyle(.red)
                }

                // MARK: - CTA
                Button {
                    Task {
                        if let userId = authViewModel.currentUser?.id {
                            await viewModel.confirmBooking(userId: userId)
                        }
                    }
                } label: {
                    Group {
                        if viewModel.isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Confirm Booking – \(PriceCalculator.format(viewModel.totalPrice))")
                        }
                    }
                    .primaryButtonStyle()
                }
                .disabled(!viewModel.isFormValid || viewModel.isLoading)
            }
            .padding(.horizontal, .spacingL)
            .padding(.vertical, .spacingL)
        }
        .navigationTitle("Book Vehicle")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $viewModel.bookingSuccess) {
            BookingSuccessView(
                vehicleName: viewModel.vehicle.name,
                bookingId: viewModel.confirmedBookingId ?? ""
            )
        }
    }
}

// MARK: - Sub-views
struct SectionLabel: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(.headline)
            .foregroundStyle(Color.fallbackNavy)
    }
}

struct LocationField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: icon).foregroundStyle(Color.fallbackBlue)
            TextField(placeholder, text: $text)
        }
        .padding()
        .background(Color.gray.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusS))
    }
}

struct DateSection: View {
    let label: String
    @Binding var date: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                .labelsHidden()
        }
        .padding()
        .cardStyle()
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Price Summary
struct PriceSummaryView: View {
    let dailyRate: Double
    let days: Int
    let subtotal: Double
    let tax: Double
    let total: Double

    var body: some View {
        VStack(spacing: .spacingS) {
            PriceRow(label: "\(PriceCalculator.format(dailyRate)) × \(days) days", value: PriceCalculator.format(subtotal))
            PriceRow(label: "Tax (\(Int(Constants.Pricing.taxRate * 100))%)", value: PriceCalculator.format(tax))
            Divider()
            PriceRow(label: "Total", value: PriceCalculator.format(total), isTotal: true)
        }
        .padding()
        .cardStyle()
    }
}

struct PriceRow: View {
    let label: String
    let value: String
    var isTotal = false

    var body: some View {
        HStack {
            Text(label)
                .font(isTotal ? .headline : .subheadline)
                .foregroundStyle(isTotal ? Color.fallbackNavy : .secondary)
            Spacer()
            Text(value)
                .font(isTotal ? .title3.bold() : .subheadline)
                .foregroundStyle(isTotal ? Color.fallbackBlue : .primary)
        }
    }
}

// MARK: - Success View
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
        BookingView(vehicle: Vehicle.sampleVehicles[0])
            .environmentObject(AuthViewModel())
    }
}
