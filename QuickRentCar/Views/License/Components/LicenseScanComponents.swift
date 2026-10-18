import SwiftUI

// MARK: - Dark scan-screen palette
extension Color {
    static let scanBackground = Color(red: 0.043, green: 0.075, blue: 0.145)
    static let scanCard       = Color(red: 0.075, green: 0.137, blue: 0.231)
    static let scanBorder     = Color(red: 0.18,  green: 0.37,  blue: 0.84)
    static let scanAccent     = Color(red: 0.30,  green: 0.70,  blue: 0.95)
    static let scanIconBg     = Color(red: 0.10,  green: 0.19,  blue: 0.31)
    static let scanButton     = Color(red: 0.18,  green: 0.42,  blue: 0.92)
}

struct LicenseScanHeader: View {
    let title: String
    var subtitle: String? = nil
    let onBack: () -> Void

    var body: some View {
        ZStack {
            VStack(spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }

            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(Color.scanCard)
                        .clipShape(Circle())
                }
                Spacer()
            }
        }
        .padding(.horizontal, .spacingL)
        .padding(.top, .spacingS)
        .padding(.bottom, .spacingS)
    }
}

// MARK: - Square scan icon
struct ScanFrameIcon: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3)
                .stroke(Color.scanAccent, lineWidth: 3)
                .frame(width: 36, height: 36)
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.scanAccent)
                .frame(width: 14, height: 14)
        }
    }
}

// MARK: - Big framed card ("Scan Your Driver's License")
struct LicenseScanFrameCard: View {
    let isScanning: Bool

    var body: some View {
        VStack(spacing: .spacingM) {
            if isScanning {
                ProgressView()
                    .tint(Color.scanAccent)
                    .scaleEffect(1.4)
                    .frame(width: 36, height: 36)
            } else {
                ScanFrameIcon()
            }

            Text(isScanning ? "Scanning..." : "Scan Your Driver's License")
                .font(.title2.bold())
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text(isScanning
                 ? "Reading your license on this device."
                 : "Secure on-device OCR extracts your details.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, .spacingL)
        .frame(maxWidth: .infinity)
        .frame(height: 290)
        .background(Color.scanCard)
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(Color.scanBorder, lineWidth: 1)
        )
    }
}

// MARK: - Feature row (icon circle + label)
struct LicenseFeatureRow: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: .spacingM) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color.scanAccent)
                .frame(width: 44, height: 44)
                .background(Color.scanIconBg)
                .clipShape(Circle())

            Text(title)
                .font(.body.weight(.semibold))
                .foregroundStyle(.white)

            Spacer()
        }
    }
}

/// The three feature rows shown under the scan card.
struct LicenseFeatureList: View {
    var body: some View {
        VStack(spacing: .spacingM) {
            LicenseFeatureRow(icon: "checkmark", title: "Fast & Accurate")
            LicenseFeatureRow(icon: "arrow.up.right", title: "Auto-fill Agreement")
            LicenseFeatureRow(icon: "diamond.fill", title: "Secure & Private")
        }
    }
}

// MARK: - Buttons
struct ScanPrimaryButton: View {
    let title: String
    var isLoading = false
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text(title)
                }
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(Color.scanButton)
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .disabled(!isEnabled || isLoading)
        .opacity(isEnabled ? 1 : 0.45)
    }
}

struct ScanSecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.scanAccent)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.scanBorder, lineWidth: 1)
                )
        }
    }
}

// MARK: - Review card (after a successful scan)
struct LicenseReviewCard: View {
    @Binding var info: LicenseInfo

    var body: some View {
        VStack(alignment: .leading, spacing: .spacingM) {
            HStack(spacing: .spacingS) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.scanAccent)
                Text("Scan complete - please review")
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            reviewRow(label: "Full name", value: info.fullName)

            VStack(alignment: .leading, spacing: 4) {
                Text("License number")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                TextField(
                    "",
                    text: $info.licenseNumber,
                    prompt: Text("License number").foregroundStyle(.white.opacity(0.4))
                )
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .foregroundStyle(.white)
                .padding(.vertical, .spacingXS)
                .overlay(Rectangle().frame(height: 1).foregroundStyle(Color.scanBorder.opacity(0.5)), alignment: .bottom)
            }

            reviewRow(label: "Expiry date", value: info.formattedExpiryDate)
            reviewRow(label: "Date of birth", value: info.formattedDateOfBirth)

            if info.isExpired {
                Label("This license has expired, so it can't be used for a booking.", systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .foregroundStyle(.orange)
            }
        }
        .padding(.spacingL)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.scanCard)
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(Color.scanBorder, lineWidth: 1)
        )
    }

    private func reviewRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
            Text(value.isEmpty ? "-" : value)
                .foregroundStyle(.white)
                .padding(.vertical, .spacingXS)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(Rectangle().frame(height: 1).foregroundStyle(Color.scanBorder.opacity(0.25)), alignment: .bottom)
        }
    }
}
