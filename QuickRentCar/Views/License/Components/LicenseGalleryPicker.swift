import SwiftUI
import PhotosUI

/// Lets the user pick a license photo from the gallery. Uses the system photo picker, which runs
/// outside the app, so no photo-library permission (and no Info.plist key) is needed.
/// The label is up to the caller, so it fits both the dark booking screen and the light profile screen.
struct LicenseGalleryPicker<Content: View>: View {
    @State private var selectedItem: PhotosPickerItem?
    private let onImage: (UIImage) -> Void
    private let onFailure: (() -> Void)?
    private let label: Content

    init(onImage: @escaping (UIImage) -> Void,
         onFailure: (() -> Void)? = nil,
         @ViewBuilder label: () -> Content) {
        self.onImage = onImage
        self.onFailure = onFailure
        self.label = label()
    }

    var body: some View {
        PhotosPicker(selection: $selectedItem, matching: .images) {
            label
        }
        .onChange(of: selectedItem) { _, item in
            guard let item else { return }
            Task {
                // UIImage(data:) keeps the photo's orientation flag, which the OCR step relies on.
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    onImage(image)
                } else {
                    onFailure?()
                }
                selectedItem = nil      // lets the same photo be picked again
            }
        }
    }
}

/// Outline button look for the dark scan screen (same style as `ScanSecondaryButton`).
struct ScanSecondaryLabel: View {
    let title: String
    var systemImage: String? = nil

    var body: some View {
        HStack(spacing: 8) {
            if let systemImage { Image(systemName: systemImage) }
            Text(title)
        }
        .font(.headline)
        .foregroundStyle(Color.scanAccent)
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.scanBorder, lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 18))
    }
}
