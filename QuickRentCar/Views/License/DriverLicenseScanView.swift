import SwiftUI

/// Booking step 2: scan the driver's license, then confirm the booking.
/// Reuses `LicenseOCRViewModel` and `LicenseCameraView` from the existing license code.
struct DriverLicenseScanView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authViewModel: AuthViewModel
    @ObservedObject var bookingViewModel: BookingViewModel
    @StateObject private var viewModel = LicenseOCRViewModel()
    @State private var showCamera = false

    private var isWorking: Bool {
        viewModel.isScanning || viewModel.isSaving || bookingViewModel.isLoading
    }

    private var infoBinding: Binding<LicenseInfo> {
        Binding(
            get: { viewModel.extractedInfo ?? LicenseInfo() },
            set: { viewModel.extractedInfo = $0 }
        )
    }

    /// Confirm is allowed only with a license number and a license that has not expired.
    private var canConfirm: Bool {
        guard let info = viewModel.extractedInfo else { return false }
        return info.licenseNumber.isNotEmpty && !info.isExpired && !isWorking
    }

    private var errorText: String? {
        viewModel.errorMessage ?? bookingViewModel.errorMessage
    }

    var body: some View {
        VStack(spacing: 0) {
            LicenseScanHeader(title: "Scan Driver's License") { dismiss() }

            ScrollView(showsIndicators: false) {
                VStack(spacing: .spacingL) {
                    if viewModel.scanComplete {
                        LicenseReviewCard(info: infoBinding)
                    } else {
                        LicenseScanFrameCard(isScanning: viewModel.isScanning)
                        LicenseFeatureList()
                            .padding(.top, .spacingS)
                    }

                    if let errorText {
                        Text(errorText)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, .spacingL)
                .padding(.top, .spacingM)
                .padding(.bottom, .spacingL)
            }
        }
        .background(Color.scanBackground.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) { bottomActions }
        .preferredColorScheme(.dark)
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showCamera) {
            LicenseCameraView { image in
                Task { await viewModel.processImage(image) }
            }
        }
        .navigationDestination(isPresented: $bookingViewModel.bookingSuccess) {
            BookingSuccessView(
                vehicleName: bookingViewModel.vehicle.name,
                bookingId: bookingViewModel.confirmedBookingId ?? ""
            )
        }
    }

    // MARK: - Bottom buttons
    private var bottomActions: some View {
        VStack(spacing: .spacingS) {
            if viewModel.scanComplete {
                ScanPrimaryButton(
                    title: "Confirm Booking – \(PriceCalculator.format(bookingViewModel.totalPrice))",
                    isLoading: viewModel.isSaving || bookingViewModel.isLoading,
                    isEnabled: canConfirm
                ) {
                    Task { await confirmBooking() }
                }

                ScanSecondaryButton(title: "Rescan") { viewModel.reset() }
                    .disabled(isWorking)
            } else {
                ScanPrimaryButton(
                    title: "Start Scanning",
                    isLoading: viewModel.isScanning,
                    isEnabled: !viewModel.isScanning
                ) {
                    startScanning()
                }
            }
        }
        .padding(.horizontal, .spacingL)
        .padding(.top, .spacingS)
        .padding(.bottom, .spacingS)
        .background(Color.scanBackground)
    }

    // MARK: - Actions
    private func startScanning() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            viewModel.errorMessage = "Camera isn't available on this device."
            return
        }
        viewModel.errorMessage = nil
        showCamera = true
    }

    private func confirmBooking() async {
        guard let user = authViewModel.currentUser, let userId = user.id else {
            viewModel.errorMessage = "Please sign in again to confirm your booking."
            return
        }
        // 1) save license onto the profile  2) create the booking
        guard await viewModel.saveLicense(merging: user) else { return }
        await bookingViewModel.confirmBooking(userId: userId)
    }
}

#Preview {
    NavigationStack {
        DriverLicenseScanView(bookingViewModel: BookingViewModel(vehicle: Vehicle.sampleVehicles[0]))
            .environmentObject(AuthViewModel())
    }
}
