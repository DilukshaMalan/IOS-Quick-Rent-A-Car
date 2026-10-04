import SwiftUI
import AVFoundation

struct LicenseScanView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = LicenseOCRViewModel()
    @State private var showCamera = false

    var body: some View {
        NavigationStack {
            VStack(spacing: .spacingXL) {
                if viewModel.scanComplete, let info = viewModel.extractedInfo {
                    // MARK: - Scan Result
                    LicenseConfirmView(
                        info: info,
                        onSave: {
                            Task {
                                if let userId = authViewModel.currentUser?.id {
                                    await viewModel.saveLicenseInfo(userId: userId)
                                    dismiss()
                                }
                            }
                        },
                        onRescan: { viewModel.reset() }
                    )
                } else {
                    // MARK: - Scan Prompt
                    VStack(spacing: .spacingL) {
                        Spacer()

                        Image(systemName: "creditcard.viewfinder")
                            .font(.system(size: 80))
                            .foregroundStyle(Color.fallbackBlue)

                        VStack(spacing: .spacingS) {
                            Text("Scan Your License")
                                .font(.title2.bold())
                                .foregroundStyle(Color.fallbackNavy)

                            Text("Position your driver's license in the camera frame. We'll extract your details automatically.")
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        if viewModel.isScanning {
                            VStack(spacing: .spacingS) {
                                ProgressView()
                                Text("Scanning license…")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if let error = viewModel.errorMessage {
                            Text(error).font(.caption).foregroundStyle(.red)
                        }

                        Spacer()

                        Button {
                            showCamera = true
                        } label: {
                            Label("Open Camera", systemImage: "camera.fill")
                                .primaryButtonStyle()
                        }
                        .padding(.horizontal, .spacingL)
                        .padding(.bottom, .spacingXL)
                    }
                }
            }
            .navigationTitle("Driver License")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(isPresented: $showCamera) {
                LicenseCameraView { image in
                    Task { await viewModel.processImage(image) }
                }
            }
        }
    }
}

// MARK: - Confirm Extracted Fields
struct LicenseConfirmView: View {
    @State var info: LicenseInfo
    let onSave: () -> Void
    let onRescan: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: .spacingL) {
                VStack(spacing: .spacingS) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.fallbackBlue)
                    Text("Scan Complete")
                        .font(.title2.bold())
                        .foregroundStyle(Color.fallbackNavy)
                    Text("Please review and confirm your details")
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: .spacingM) {
                    EditableField(label: "Full Name", value: $info.fullName)
                    ReadOnlyField(label: "License Number", value: info.licenseNumber)
                    ReadOnlyField(label: "Expiry Date", value: info.formattedExpiryDate)
                    ReadOnlyField(label: "Date of Birth", value: info.formattedDateOfBirth)
                }
                .padding()
                .cardStyle()

                if info.isExpired {
                    Label("This license appears to be expired.", systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                }

                Button("Save Details", action: onSave).primaryButtonStyle()
                Button("Rescan", action: onRescan).secondaryButtonStyle()
            }
            .padding()
        }
    }
}

struct EditableField: View {
    let label: String
    @Binding var value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            TextField(label, text: $value)
                .padding(.vertical, .spacingXS)
                .overlay(Rectangle().frame(height: 1).foregroundStyle(Color.gray.opacity(0.3)), alignment: .bottom)
        }
    }
}

struct ReadOnlyField: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(value.isEmpty ? "—" : value)
                .foregroundStyle(Color.fallbackNavy)
                .padding(.vertical, .spacingXS)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(Rectangle().frame(height: 1).foregroundStyle(Color.gray.opacity(0.2)), alignment: .bottom)
        }
    }
}

// MARK: - Camera View (UIKit wrapper)
struct LicenseCameraView: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCapture: (UIImage) -> Void
        init(onCapture: @escaping (UIImage) -> Void) { self.onCapture = onCapture }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                onCapture(image)
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

#Preview {
    LicenseScanView()
        .environmentObject(AuthViewModel())
}
