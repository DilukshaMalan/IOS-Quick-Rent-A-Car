import SwiftUI
import UIKit
import AVFoundation

private enum LicenseSide { case front, rear }

struct LicenseScanView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = LicenseOCRViewModel()

    @State private var activeSide: LicenseSide = .front
    @State private var showSourceChoice = false
    @State private var showPicker = false
    @State private var imageSource: UIImagePickerController.SourceType = .camera

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.scanComplete, let info = viewModel.extractedInfo {
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
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: .spacingL) {
                            VStack(spacing: .spacingS) {
                                Image(systemName: "creditcard.viewfinder")
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
                            .padding(.top, .spacingL)

                            SidePickerCard(
                                title: "Front Side",
                                subtitle: "Name • Licence Number • Date of Birth",
                                systemIcon: "person.text.rectangle",
                                image: viewModel.frontImage
                            ) {
                                activeSide = .front
                                showSourceChoice = true
                            }

                            SidePickerCard(
                                title: "Rear Side",
                                subtitle: "Expiry Date",
                                systemIcon: "calendar.badge.clock",
                                image: viewModel.rearImage
                            ) {
                                activeSide = .rear
                                showSourceChoice = true
                            }

                            if let error = viewModel.errorMessage {
                                Text(error)
                                    .font(.caption)
                                    .foregroundStyle(.red)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }

                            if viewModel.isScanning {
                                VStack(spacing: .spacingS) {
                                    ProgressView()
                                    Text("Scanning licence…")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.top, .spacingS)
                            } else {
                                Button {
                                    Task { await viewModel.processBothSides() }
                                } label: {
                                    Label("Scan Licence", systemImage: "wand.and.stars")
                                        .primaryButtonStyle()
                                }
                                .disabled(!viewModel.readyToScan)
                                .opacity(viewModel.readyToScan ? 1 : 0.45)
                                .padding(.horizontal, .spacingL)
                            }

                            Spacer(minLength: .spacingXL)
                        }
                        .padding(.bottom, .spacingXL)
                        .frame(maxWidth: 680)
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle("Driver Licence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
            .confirmationDialog("Select Image Source", isPresented: $showSourceChoice, titleVisibility: .visible) {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    Button("Take Photo") {
                        imageSource = .camera
                        showPicker = true
                    }
                }
                if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                    Button("Choose from Library") {
                        imageSource = .photoLibrary
                        showPicker = true
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $showPicker) {
                LicenseCameraView(sourceType: imageSource) { image in
                    if activeSide == .front {
                        viewModel.frontImage = image
                    } else {
                        viewModel.rearImage = image
                    }
                }
            }
        }
    }
}

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
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                image != nil ? Color.fallbackBlue : Color.gray.opacity(0.3),
                                lineWidth: image != nil ? 2 : 1
                            )
                    )

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
                                .clipShape(
                                    .rect(
                                        bottomLeadingRadius: 15,
                                        bottomTrailingRadius: 15
                                    )
                                )
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
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity, alignment: .center)
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

struct LicenseCameraView: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType = .camera
    let onCapture: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        if sourceType == .camera {
            picker.cameraCaptureMode = .photo
        }
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
