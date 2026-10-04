import Foundation
import FirebaseFirestore

struct User: Identifiable, Codable {
    @DocumentID var id: String?
    var email: String
    var fullName: String
    var phoneNumber: String
    var profileImageURL: String?
    var licenseNumber: String?
    var licenseExpiry: Date?
    var isFaceIDEnabled: Bool
    var fcmToken: String?
    var createdAt: Date

    init(
        id: String? = nil,
        email: String,
        fullName: String,
        phoneNumber: String = "",
        profileImageURL: String? = nil,
        licenseNumber: String? = nil,
        licenseExpiry: Date? = nil,
        isFaceIDEnabled: Bool = false,
        fcmToken: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.email = email
        self.fullName = fullName
        self.phoneNumber = phoneNumber
        self.profileImageURL = profileImageURL
        self.licenseNumber = licenseNumber
        self.licenseExpiry = licenseExpiry
        self.isFaceIDEnabled = isFaceIDEnabled
        self.fcmToken = fcmToken
        self.createdAt = createdAt
    }
}
