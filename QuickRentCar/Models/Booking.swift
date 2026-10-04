import Foundation
import FirebaseFirestore

struct Booking: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var vehicleId: String
    var vehicleName: String
    var vehicleImageURL: String
    var pickupLocation: String
    var dropOffLocation: String
    var pickupDate: Date
    var returnDate: Date
    var totalDays: Int
    var dailyRate: Double
    var totalPrice: Double
    var status: BookingStatus
    var createdAt: Date
    var licenseVerified: Bool

    enum BookingStatus: String, Codable {
        case pending = "Pending"
        case confirmed = "Confirmed"
        case active = "Active"
        case completed = "Completed"
        case cancelled = "Cancelled"

        var colorName: String {
            switch self {
            case .pending:   return "orange"
            case .confirmed: return "blue"
            case .active:    return "green"
            case .completed: return "gray"
            case .cancelled: return "red"
            }
        }

        var icon: String {
            switch self {
            case .pending:   return "clock"
            case .confirmed: return "checkmark.circle"
            case .active:    return "car.fill"
            case .completed: return "checkmark.seal.fill"
            case .cancelled: return "xmark.circle"
            }
        }
    }

    init(
        id: String? = nil,
        userId: String,
        vehicleId: String,
        vehicleName: String,
        vehicleImageURL: String,
        pickupLocation: String,
        dropOffLocation: String,
        pickupDate: Date,
        returnDate: Date,
        totalDays: Int,
        dailyRate: Double,
        totalPrice: Double,
        status: BookingStatus = .pending,
        createdAt: Date = Date(),
        licenseVerified: Bool = false
    ) {
        self.id = id
        self.userId = userId
        self.vehicleId = vehicleId
        self.vehicleName = vehicleName
        self.vehicleImageURL = vehicleImageURL
        self.pickupLocation = pickupLocation
        self.dropOffLocation = dropOffLocation
        self.pickupDate = pickupDate
        self.returnDate = returnDate
        self.totalDays = totalDays
        self.dailyRate = dailyRate
        self.totalPrice = totalPrice
        self.status = status
        self.createdAt = createdAt
        self.licenseVerified = licenseVerified
    }
}
