import SwiftUI

/// Booking step 2: use the saved license or scan one, then confirm the booking.
/// Reuses `LicenseOCRViewModel` and `LicenseCameraView` from the existing license code.
struct DriverLicenseScanView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authViewModel: AuthViewModel
    @ObservedObject var bookingViewModel: BookingViewModel
    @StateObject private var viewModel = LicenseOCRViewModel()
    @State private var showCamera = false
    @State private var wantsNewScan = false
    @State private var imageSource: UIImagePickerController.SourceType = .camera
    @State private var showSourceChoice = false

    // MARK: - Saved license
    private struct SavedLicense {
        let number: String
        let expiry: Date
        var masked: String { "•••• " + number.suffix(4) }
    }

    /// A saved license is offered only if it is still valid on the day the car is returned.
    private var savedLicense: SavedLicense? {
        guard let user = authViewModel.currentUser,
              let number = user.licenseNumber, number.isNotEmpty,
              let expiry = user.licenseExpiry,
              expiry >= bookingViewModel.returnDate
        else { return nil }
        return SavedLicense(number: number, expiry: expiry)
    }

    private var showingSavedLicense: Bool {
        savedLicense != nil && !wantsNewScan && !viewModel.scanComplete && !viewModel.isScanning
    }

    // MARK: - State helpers
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

    private var confirmTitle: String {
        "Confirm Booking – \(PriceCalculator.format(bookingViewModel.totalPrice))"
    }

    var body: some View {
        VStack(spacing: 0) {
            LicenseScanHeader(
                title: showingSavedLicense ? "Driver's License" : "Scan Driver's License",
                subtitle: "Step 2 of 2"
            ) {
                dismiss()
            }

            ScrollView(showsIndicators: false) {
                VStack(spacing: .spacingL) {
                    if showingSavedLicense, let saved = savedLicense {
                        SavedLicenseCard(maskedNumber: saved.masked, expiry: saved.expiry)
                    } else if viewModel.scanComplete {
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
            LicenseCameraView(sourceType: imageSource) { image in
                Task { await viewModel.processImage(image) }
            }
        }
        .confirmationDialog("Select Image Source", isPresented: $showSourceChoice, titleVisibility: .visible) {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button("Take Photo") {
                    imageSource = .camera
                    showCamera = true
                }
            }
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                Button("Choose from Library") {
                    imageSource = .photoLibrary
                    showCamera = true
                }
            }
            Button("Cancel", role: .cancel) {}
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
            if showingSavedLicense {
                ScanPrimaryButton(
                    title: confirmTitle,
                    isLoading: bookingViewModel.isLoading,
                    isEnabled: true
                ) {
                    Task { await confirmWithSavedLicense() }
                }

                ScanSecondaryButton(title: "Scan a different license") { wantsNewScan = true }
                    .disabled(isWorking)
            } else if viewModel.scanComplete {
                ScanPrimaryButton(
                    title: confirmTitle,
                    isLoading: viewModel.isSaving || bookingViewModel.isLoading,
                    isEnabled: canConfirm
                ) {
                    Task { await confirmWithScannedLicense() }
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
        // Present source choice dialog
        showSourceChoice = true
    }

    /// Saved license: nothing to store, just create the booking.
    private func confirmWithSavedLicense() async {
        guard let userId = authViewModel.currentUser?.id else {
            viewModel.errorMessage = "Please sign in again to confirm your booking."
            return
        }
        await bookingViewModel.confirmBooking(userId: userId)
    }

    /// New scan: 1) save the license onto the profile  2) create the booking.
    private func confirmWithScannedLicense() async {
        guard let user = authViewModel.currentUser, let userId = user.id else {
            viewModel.errorMessage = "Please sign in again to confirm your booking."
            return
        }
        guard let updatedUser = await viewModel.saveLicense(merging: user) else { return }
        authViewModel.currentUser = updatedUser   // so the next booking can reuse this license
        await bookingViewModel.confirmBooking(userId: userId)
    }
}

#Preview {
    NavigationStack {
        DriverLicenseScanView(bookingViewModel: BookingViewModel(vehicle: Vehicle.sampleVehicles[0]))
            .environmentObject(AuthViewModel())
    }
}
