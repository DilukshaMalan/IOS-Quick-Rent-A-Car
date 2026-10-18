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
                // MARK: - Progress
                BookingStepIndicator(step: 1, total: 2, title: "Trip details")

                // MARK: - Vehicle Summary
                BookingVehicleSummaryCard(vehicle: viewModel.vehicle)

                // MARK: - Location
                BookingLocationSection(
                    pickupLocation: viewModel.pickupLocation,
                    dropOffLocation: $viewModel.dropOffLocation
                )

                // MARK: - Dates + availability
                BookingRentalPeriodSection(
                    pickupDate: $viewModel.pickupDate,
                    returnDate: $viewModel.returnDate,
                    rentalDays: viewModel.rentalDays,
                    unavailablePeriods: viewModel.vehicle.bookedPeriods ?? []
                )

                if let state = viewModel.availabilityState {
                    BookingAvailabilityBanner(state: state, isChecking: viewModel.isCheckingAvailability)
                }
            }
            .padding(.horizontal, .spacingL)
            .padding(.vertical, .spacingL)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            // MARK: - Price + CTA
            BookingContinueBar(
                dailyRate: viewModel.vehicle.dailyPrice,
                days: viewModel.rentalDays,
                subtotal: viewModel.subtotal,
                tax: viewModel.taxAmount,
                total: viewModel.totalPrice,
                includedMileage: viewModel.vehicle.includedMileage,
                hint: viewModel.isFormValid ? nil : viewModel.validationHint,
                isEnabled: viewModel.isFormValid,
                isLoading: viewModel.isCheckingAvailability
            ) {
                hideKeyboard()
                Task {
                    // Re-check right before moving on, in case someone booked in the meantime
                    await viewModel.refreshAvailability()
                    if viewModel.isFormValid { showLicenseStep = true }
                }
            }
        }
        .task { await viewModel.refreshAvailability() }
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
