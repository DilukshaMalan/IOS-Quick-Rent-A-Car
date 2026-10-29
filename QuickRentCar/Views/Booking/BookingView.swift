import SwiftUI

struct BookingView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: BookingViewModel
    @State private var showLicenseStep = false

    init(vehicle: Vehicle) {
        _viewModel = StateObject(wrappedValue: BookingViewModel(vehicle: vehicle))
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.fallbackNavy)
                        .frame(width: 36, height: 36)
                        .background(Color.gray.opacity(0.09))
                        .clipShape(Circle())
                }

                Spacer()

                Text("Book Vehicle")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.fallbackNavy)

                Spacer()

                Color.clear.frame(width: 36, height: 36)
            }
            .padding(.horizontal, .spacingL)
            .padding(.top, .spacingS)
            .padding(.bottom, .spacingXS)
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity, alignment: .center)

            ScrollView {
                VStack(spacing: .spacingL) {
                    BookingStepIndicator(step: 1, total: 2, title: "Trip details")

                    BookingVehicleSummaryCard(vehicle: viewModel.vehicle)

                    BookingLocationSection(
                        pickupLocation: viewModel.pickupLocation,
                        dropOffLocation: $viewModel.dropOffLocation
                    )

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
                .frame(maxWidth: 680)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom) {
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
                        await viewModel.refreshAvailability()
                        if viewModel.isFormValid { showLicenseStep = true }
                    }
                }
            }
        }
        .task { await viewModel.refreshAvailability() }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
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
