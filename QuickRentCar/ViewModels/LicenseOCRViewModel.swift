import Foundation
import UIKit

@MainActor
class LicenseOCRViewModel: ObservableObject {

    @Published var frontImage: UIImage?
    @Published var rearImage: UIImage?

    @Published var capturedImage: UIImage?

    @Published var extractedInfo: LicenseInfo?
    @Published var isScanning = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var scanComplete = false

    var readyToScan: Bool { frontImage != nil && rearImage != nil }

    private let ocrService = VisionOCRService.shared
    private let firestoreService = FirestoreService.shared

    func processBothSides() async {
        guard let front = frontImage, let rear = rearImage else {
            errorMessage = "Please select both the front and rear of your licence."
            return
        }
        isScanning = true
        errorMessage = nil

        do {
            async let frontInfo = ocrService.extractFrontInfo(from: front)
            async let expiryDate = ocrService.extractExpiryDate(from: rear)

            var info = try await frontInfo
            info.expiryDate = try await expiryDate
            extractedInfo = info
            scanComplete = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isScanning = false
    }

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

    func saveLicenseInfo(userId: String) async {
        guard let info = extractedInfo else { return }
        isSaving = true
        defer { isSaving = false }

        do {
            let user = User(
                id: userId,
                email: "",
                fullName: info.fullName,
                licenseNumber: info.licenseNumber,
                licenseExpiry: info.expiryDate,
                licenseAddress: info.address
            )

            try await firestoreService.updateUser(user)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveLicense(merging user: User) async -> User? {
        guard let info = extractedInfo else { return nil }

        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        var updated = user
        updated.licenseNumber = info.licenseNumber
        updated.licenseExpiry = info.expiryDate
        updated.licenseAddress = info.address

        do {
            try await FirestoreService.shared.updateUser(updated)
            return updated
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func reset() {
        frontImage = nil
        rearImage = nil
        capturedImage = nil
        extractedInfo = nil
        scanComplete = false
        errorMessage = nil
    }
}
