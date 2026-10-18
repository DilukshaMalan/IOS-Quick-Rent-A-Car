import SwiftUI

struct BookingView: View {
    @StateObject private var viewModel: BookingViewModel
    @State private var showLicenseStep = false

    init(vehicle: Vehicle) {
        _viewModel = StateObject(wrappedValue: BookingViewModel(vehicle: vehicle))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: .spacingL) {
                // MARK: - Vehicle Summary
                BookingVehicleSummaryCard(vehicle: viewModel.vehicle)

                // MARK: - Location
                BookingLocationSection(
                    pickupLocation: $viewModel.pickupLocation,
                    dropOffLocation: $viewModel.dropOffLocation
                )

                // MARK: - Dates
                BookingRentalPeriodSection(
                    pickupDate: $viewModel.pickupDate,
                    returnDate: $viewModel.returnDate,
                    rentalDays: viewModel.rentalDays
                )

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
            }
            .padding(.horizontal, .spacingL)
            .padding(.vertical, .spacingL)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            // MARK: - CTA
            BookingContinueBar(
                total: viewModel.totalPrice,
                hint: viewModel.isFormValid ? nil : viewModel.validationHint,
                isEnabled: viewModel.isFormValid
            ) {
                hideKeyboard()
                showLicenseStep = true
            }
        }
        .navigationTitle("Book Vehicle")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showLicenseStep) {
            DriverLicenseScanView(bookingViewModel: viewModel)
        }
    }
}

#Preview {
    NavigationStack {
        BookingView(vehicle: Vehicle.sampleVehicles[0])
            .environmentObject(AuthViewModel())
    }
}
