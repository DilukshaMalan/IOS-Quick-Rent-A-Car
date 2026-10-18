import Foundation

extension LicenseOCRViewModel {
    /// Saves the scanned license number/expiry onto a copy of the *existing* user profile and
    /// returns the updated user (nil on failure). Unlike `saveLicenseInfo(userId:)`, this keeps
    /// the user's email, phone number, createdAt, Face ID setting etc. untouched.
    @discardableResult
    func saveLicense(merging user: User) async -> User? {
        guard let info = extractedInfo else { return nil }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        var updated = user
        updated.licenseNumber = info.licenseNumber
        updated.licenseExpiry = info.expiryDate

        do {
            try await FirestoreService.shared.updateUser(updated)
            return updated
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
