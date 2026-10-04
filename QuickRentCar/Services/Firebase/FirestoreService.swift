import Foundation
import FirebaseFirestore

class FirestoreService {
    static let shared = FirestoreService()
    private let db = Firestore.firestore()
    private init() {}

    // MARK: - Generic Helpers

    private func collection(_ name: String) -> CollectionReference {
        db.collection(name)
    }

    // MARK: - Users
    func createUser(_ user: User) async throws {
        guard let id = user.id else { throw FirestoreError.missingID }
        try collection(Constants.Firestore.users).document(id).setData(from: user)
    }

    func fetchUser(id: String) async throws -> User {
        let doc = try await collection(Constants.Firestore.users).document(id).getDocument()
        guard let user = try? doc.data(as: User.self) else { throw FirestoreError.decodingFailed }
        return user
    }

    func updateUser(_ user: User) async throws {
        guard let id = user.id else { throw FirestoreError.missingID }
        try collection(Constants.Firestore.users).document(id).setData(from: user, merge: true)
    }

    // MARK: - Vehicles
    func fetchVehicles() async throws -> [Vehicle] {
        let snapshot = try await collection(Constants.Firestore.vehicles)
            .whereField("isAvailable", isEqualTo: true)
            .order(by: "dailyPrice")
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Vehicle.self) }
    }

    func fetchVehicles(category: Vehicle.VehicleCategory) async throws -> [Vehicle] {
        let snapshot = try await collection(Constants.Firestore.vehicles)
            .whereField("category", isEqualTo: category.rawValue)
            .whereField("isAvailable", isEqualTo: true)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Vehicle.self) }
    }

    func fetchVehicle(id: String) async throws -> Vehicle {
        let doc = try await collection(Constants.Firestore.vehicles).document(id).getDocument()
        guard let vehicle = try? doc.data(as: Vehicle.self) else { throw FirestoreError.decodingFailed }
        return vehicle
    }

    // MARK: - Bookings
    func createBooking(_ booking: Booking) async throws -> String {
        let ref = try collection(Constants.Firestore.bookings).addDocument(from: booking)
        return ref.documentID
    }

    func fetchBookings(userId: String) async throws -> [Booking] {
        let snapshot = try await collection(Constants.Firestore.bookings)
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Booking.self) }
    }

    func updateBookingStatus(_ bookingId: String, status: Booking.BookingStatus) async throws {
        try await collection(Constants.Firestore.bookings).document(bookingId)
            .updateData(["status": status.rawValue])
    }

    // MARK: - Payments
    func fetchPayments(userId: String) async throws -> [PaymentRecord] {
        let snapshot = try await collection(Constants.Firestore.payments)
            .whereField("userId", isEqualTo: userId)
            .order(by: "transactionDate", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: PaymentRecord.self) }
    }

    // MARK: - Driving Stats
    func fetchStats(userId: String) async throws -> [DrivingStats] {
        let snapshot = try await collection(Constants.Firestore.stats)
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: DrivingStats.self) }
    }
}

// MARK: - Errors
enum FirestoreError: LocalizedError {
    case missingID
    case decodingFailed
    case documentNotFound

    var errorDescription: String? {
        switch self {
        case .missingID:         return "Document ID is missing."
        case .decodingFailed:   return "Failed to decode document data."
        case .documentNotFound: return "Document not found."
        }
    }
}
