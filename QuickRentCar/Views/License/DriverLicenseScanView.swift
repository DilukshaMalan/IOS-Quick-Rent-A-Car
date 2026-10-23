import SwiftUI
import UIKit

// MARK: - Two‑Side Driver License Scan for Booking
private enum LicenseSide { case front, rear }

struct DriverLicenseScanView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authViewModel: AuthViewModel
    @ObservedObject var bookingViewModel: BookingViewModel
    @StateObject private var viewModel = LicenseOCRViewModel()

    // Image selection state
    @State private var activeSide: LicenseSide = .front
    @State private var showSourceChoice = false
    @State private var showPicker = false
    @State private var imageSource: UIImagePickerController.SourceType = .camera
    @State private var navigateToSuccess = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: .spacingL) {
                // Step indicator
                BookingStepIndicator(step: 2, total: 2, title: "Driver's Licence")
                    .padding(.horizontal, .spacingL)
                    .padding(.top, .spacingM)

                if viewModel.scanComplete, let info = viewModel.extractedInfo {
                    // ── Step 3: Review & confirm extracted details ──────
                    BookingLicenseConfirmView(
                        info: info,
                        bookingViewModel: bookingViewModel,
                        isWorking: viewModel.isSaving || bookingViewModel.isLoading,
                        errorMessage: bookingViewModel.errorMessage ?? viewModel.errorMessage,
                        onConfirm: { Task { await confirmWithScannedLicense() } },
                        onRescan: { viewModel.reset() }
                    )
                } else {
                    // ── Step 1 & 2: Capture both sides ─────────────────
                    VStack(spacing: .spacingL) {
                        VStack(spacing: .spacingS) {
                            Image(systemName: "person.text.rectangle")
                                .font(.system(size: 64))
                                .foregroundStyle(Color.fallbackBlue)
                            Text("Scan Your Licence")
                                .font(.title2.bold())
                                .foregroundStyle(Color.fallbackNavy)
                            Text("Add photos of both sides, then tap **Scan Licence** to extract your details.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        // Front card
                        SidePickerCard(title: "Front Side",
                                       subtitle: "Name • Licence Number • DOB",
                                       systemIcon: "person.text.rectangle",
                                       image: viewModel.frontImage) {
                            activeSide = .front; showSourceChoice = true
                        }

                        // Rear card
                        SidePickerCard(title: "Rear Side",
                                       subtitle: "Expiry Date",
                                       systemIcon: "calendar.badge.clock",
                                       image: viewModel.rearImage) {
                            activeSide = .rear; showSourceChoice = true
                        }

                        // Scan OCR errors
                        if let error = viewModel.errorMessage {
                            Label(error, systemImage: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        // Scan button
                        if viewModel.isScanning {
                            VStack(spacing: .spacingS) {
                                ProgressView()
                                Text("Reading licence…")
                                    .font(.subheadline).foregroundStyle(.secondary)
                            }
                            .padding(.top, .spacingS)
                        } else {
                            Button { Task { await viewModel.processBothSides() } } label: {
                                Label("Scan Licence", systemImage: "wand.and.stars")
                                    .primaryButtonStyle()
                            }
                            .disabled(!viewModel.readyToScan)
                            .opacity(viewModel.readyToScan ? 1 : 0.45)
                            .padding(.horizontal, .spacingL)
                        }
                    }
                }
            }
            .padding(.bottom, .spacingXXL)
        }
        .navigationTitle("Driver Licence")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Select Image Source", isPresented: $showSourceChoice, titleVisibility: .visible) {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button("Take Photo") { imageSource = .camera; showPicker = true }
            }
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                Button("Choose from Library") { imageSource = .photoLibrary; showPicker = true }
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showPicker) {
            LicenseCameraView(sourceType: imageSource) { image in
                if activeSide == .front { viewModel.frontImage = image } else { viewModel.rearImage = image }
            }
        }
        // Navigate to success screen when booking confirmed
        .navigationDestination(isPresented: $navigateToSuccess) {
            BookingSuccessView(
                vehicleName: bookingViewModel.vehicle.name,
                bookingId: bookingViewModel.confirmedBookingId ?? "",
                pickupDate: bookingViewModel.pickupDate,
                returnDate: bookingViewModel.returnDate,
                pickupLocation: bookingViewModel.pickupLocation,
                totalPrice: bookingViewModel.totalPrice
            )
        }
        .onChange(of: bookingViewModel.bookingSuccess) { _, success in
            if success { navigateToSuccess = true }
        }
    }

    // MARK: - Actions
    private func confirmWithScannedLicense() async {
        guard let user = authViewModel.currentUser, let userId = user.id else {
            viewModel.errorMessage = "Please sign in again to confirm your booking."
            return
        }
        guard let updatedUser = await viewModel.saveLicense(merging: user) else { return }
        authViewModel.currentUser = updatedUser
        await bookingViewModel.confirmBooking(userId: userId)
    }
}

// MARK: - Booking Confirm View (shown after OCR, before placing the order)
private struct BookingLicenseConfirmView: View {
    @State var info: LicenseInfo
    let bookingViewModel: BookingViewModel
    let isWorking: Bool
    let errorMessage: String?
    let onConfirm: () -> Void
    let onRescan: () -> Void

    var body: some View {
        VStack(spacing: .spacingL) {
            // ── Scan success header ──────────────────────────────────────────
            VStack(spacing: .spacingS) {
                ZStack {
                    Circle()
                        .fill(Color.fallbackBlue.opacity(0.12))
                        .frame(width: 90, height: 90)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(Color.fallbackBlue)
                }
                Text("Licence Verified ✓")
                    .font(.title2.bold())
                    .foregroundStyle(Color.fallbackNavy)
                Text("Review your details before placing the order.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, .spacingS)

            // ── Extracted licence fields ─────────────────────────────────────
            VStack(alignment: .leading, spacing: .spacingM) {
                sectionTitle("Licence Details")
                ConfirmRow(icon: "person.fill",         label: "Full Name",       value: info.fullName.isEmpty ? "—" : info.fullName)
                ConfirmRow(icon: "creditcard.fill",     label: "Licence Number",  value: info.licenseNumber.isEmpty ? "—" : info.licenseNumber)
                ConfirmRow(icon: "calendar",            label: "Date of Birth",   value: info.formattedDateOfBirth.isEmpty ? "—" : info.formattedDateOfBirth)
                ConfirmRow(icon: "calendar.badge.clock",label: "Expiry Date",     value: info.formattedExpiryDate.isEmpty ? "—" : info.formattedExpiryDate,
                           isWarning: info.isExpired)
            }
            .padding(.spacingL)
            .cardStyle()
            .padding(.horizontal, .spacingL)

            // ── Trip summary card ────────────────────────────────────────────
            VStack(alignment: .leading, spacing: .spacingM) {
                sectionTitle("Booking Summary")
                ConfirmRow(icon: "car.fill",        label: "Vehicle",      value: bookingViewModel.vehicle.name)
                ConfirmRow(icon: "mappin.circle",   label: "Pick-up",      value: bookingViewModel.pickupLocation)
                ConfirmRow(icon: "mappin.and.ellipse", label: "Drop-off",  value: bookingViewModel.dropOffLocation)
                ConfirmRow(icon: "clock",           label: "Pick-up Date", value: bookingViewModel.pickupDate.displayDate)
                ConfirmRow(icon: "clock.arrow.circlepath", label: "Return", value: bookingViewModel.returnDate.displayDate)
                Divider()
                HStack {
                    Text("Total")
                        .font(.headline)
                        .foregroundStyle(Color.fallbackNavy)
                    Spacer()
                    Text(PriceCalculator.format(bookingViewModel.totalPrice))
                        .font(.title3.bold())
                        .foregroundStyle(Color.fallbackBlue)
                }
            }
            .padding(.spacingL)
            .cardStyle()
            .padding(.horizontal, .spacingL)

            // ── Expired warning ──────────────────────────────────────────────
            if info.isExpired {
                Label("Your licence appears to be expired and cannot be used for a booking.", systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .foregroundStyle(.white)
                    .padding(.spacingM)
                    .frame(maxWidth: .infinity)
                    .background(Color.orange)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, .spacingL)
            }

            // ── Booking error ────────────────────────────────────────────────
            if let error = errorMessage {
                Label(error, systemImage: "xmark.octagon.fill")
                    .font(.footnote)
                    .foregroundStyle(.white)
                    .padding(.spacingM)
                    .frame(maxWidth: .infinity)
                    .background(Color.red.opacity(0.85))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, .spacingL)
            }

            // ── Action buttons ───────────────────────────────────────────────
            VStack(spacing: .spacingS) {
                Button(action: onConfirm) {
                    Group {
                        if isWorking {
                            HStack(spacing: 10) {
                                ProgressView().tint(.white)
                                Text("Placing Order…")
                            }
                        } else {
                            Label("Confirm & Place Order", systemImage: "checkmark.seal.fill")
                        }
                    }
                    .primaryButtonStyle()
                }
                .disabled(isWorking || info.isExpired)
                .opacity((isWorking || info.isExpired) ? 0.55 : 1)
                .padding(.horizontal, .spacingL)

                Button(action: onRescan) {
                    Label("Rescan Licence", systemImage: "arrow.counterclockwise")
                        .secondaryButtonStyle()
                }
                .padding(.horizontal, .spacingL)
                .disabled(isWorking)
            }
        }
        .padding(.bottom, .spacingXXL)
    }

    @ViewBuilder
    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
    }
}

/// A single labelled row inside a confirm card.
private struct ConfirmRow: View {
    let icon: String
    let label: String
    let value: String
    var isWarning = false

    var body: some View {
        HStack(spacing: .spacingM) {
            Image(systemName: icon)
                .frame(width: 22)
                .foregroundStyle(isWarning ? .orange : Color.fallbackBlue)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isWarning ? .orange : Color.fallbackNavy)
            }
            Spacer()
        }
    }
}

// MARK: - Side Picker Card (re‑used from LicenseScanView)
private struct SidePickerCard: View {
    let title: String
    let subtitle: String
    let systemIcon: String
    let image: UIImage?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
                    .overlay(RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(image != nil ? Color.fallbackBlue : Color.gray.opacity(0.3), lineWidth: image != nil ? 2 : 1))
                if let captured = image {
                    Image(uiImage: captured)
                        .resizable()
                        .scaledToFill()
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        .overlay(alignment: .topTrailing) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.white, Color.fallbackBlue)
                                .font(.title3)
                                .padding(10)
                        }
                        .overlay(alignment: .bottom) {
                            Text("Tap to retake")
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                                .padding(.vertical, 6)
                                .frame(maxWidth: .infinity)
                                .background(.black.opacity(0.45))
                                .clipShape(.rect(bottomLeadingRadius: 15, bottomTrailingRadius: 15))
                        }
                } else {
                    VStack(spacing: .spacingS) {
                        Image(systemName: systemIcon)
                            .font(.system(size: 36))
                            .foregroundStyle(Color.fallbackBlue.opacity(0.7))
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(Color.fallbackNavy)
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Label("Add Photo", systemImage: "plus.circle")
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.fallbackBlue)
                            .padding(.top, 2)
                    }
                    .padding(.vertical, .spacingL)
                    .padding(.horizontal)
                }
            }
            .frame(height: 200)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, .spacingL)
    }
}

#Preview {
    NavigationStack {
        DriverLicenseScanView(bookingViewModel: BookingViewModel(vehicle: Vehicle.sampleVehicles[0]))
            .environmentObject(AuthViewModel())
    }
}
