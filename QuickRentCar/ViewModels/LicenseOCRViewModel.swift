import Foundation
import UIKit

@MainActor
class LicenseOCRViewModel: ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var extractedInfo: LicenseInfo?
    @Published var isScanning = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var scanComplete = false

    private let ocrService = VisionOCRService.shared
    private let firestoreService = FirestoreService.shared

    // MARK: - Process Captured Image
    func processImage(_ image: UIImage) async {
        capturedImage = image
        isScanning = true
        errorMessage = nil

        do {
            let info = try await ocrService.extractLicenseInfo(from: image)
            extractedInfo = info
            scanComplete = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isScanning = false
    }

    // MARK: - Save to Profile
    func saveLicenseInfo(userId: String) async {
        guard let info = extractedInfo else { return }
        isSaving = true

        do {
            let user = User(
                id: userId,
                email: "",
                fullName: info.fullName,
                licenseNumber: info.licenseNumber,
                licenseExpiry: info.expiryDate
            )
            try await firestoreService.updateUser(user)
        } catch {
            errorMessage = error.localizedDescription
        }

        isSaving = false
    }

    // MARK: - Reset
    func reset() {
        capturedImage = nil
        extractedInfo = nil
        scanComplete = false
        errorMessage = nil
    }
}
