import Foundation

/// Model for Vision OCR extracted driver license fields
struct LicenseInfo: Codable {
    var fullName: String
    var dateOfBirth: Date?
    var licenseNumber: String
    var expiryDate: Date?
    var issuingAuthority: String?
    var rawExtractedText: String

    var isExpired: Bool {
        guard let expiry = expiryDate else { return false }
        return expiry < Date()
    }

    var formattedDateOfBirth: String {
        guard let dob = dateOfBirth else { return "" }
        return dob.formatted(date: .long, time: .omitted)
    }

    var formattedExpiryDate: String {
        guard let expiry = expiryDate else { return "" }
        return expiry.formatted(date: .long, time: .omitted)
    }

    init(
        fullName: String = "",
        dateOfBirth: Date? = nil,
        licenseNumber: String = "",
        expiryDate: Date? = nil,
        issuingAuthority: String? = nil,
        rawExtractedText: String = ""
    ) {
        self.fullName = fullName
        self.dateOfBirth = dateOfBirth
        self.licenseNumber = licenseNumber
        self.expiryDate = expiryDate
        self.issuingAuthority = issuingAuthority
        self.rawExtractedText = rawExtractedText
    }
}
