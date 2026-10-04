import Foundation
import FirebaseFirestore

struct PaymentRecord: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var bookingId: String
    var vehicleName: String
    var amount: Double
    var currency: String
    var status: PaymentStatus
    var paymentMethod: String
    var transactionDate: Date
    var invoiceNumber: String

    enum PaymentStatus: String, Codable {
        case pending = "Pending"
        case completed = "Completed"
        case failed = "Failed"
        case refunded = "Refunded"
    }

    var formattedAmount: String {
        String(format: "%@ %.2f", currency, amount)
    }

    var formattedDate: String {
        transactionDate.formatted(date: .abbreviated, time: .shortened)
    }
}
