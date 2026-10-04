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
        // Sorted in Swift rather than with `order(by:)`. Combining a where-filter with an
        // orderBy on a *different* field makes Firestore demand a composite index, and the
        // query fails with FAILED_PRECONDITION until that index is created in the console.
        let snapshot = try await collection(Constants.Firestore.vehicles)
            .whereField("isAvailable", isEqualTo: true)
            .getDocuments()
        return snapshot.documents
            .compactMap { try? $0.data(as: Vehicle.self) }
            .sorted { $0.dailyPrice < $1.dailyPrice }
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

    /// Creates a booking only if the vehicle is still free for the requested period.
    ///
    /// Runs inside a Firestore transaction: it re-reads the vehicle document, compares the
    /// requested period against the periods already booked, then writes the booking **and**
    /// the updated vehicle in one atomic commit — or aborts with `.vehicleUnavailable`.
    /// That is what stops two users reserving the same car for overlapping dates.
    ///
    /// The check runs against the vehicle document rather than a query because the iOS
    /// SDK's `Transaction` can only read single documents, not run queries.
    func createBooking(_ booking: Booking) async throws -> String {
        guard !booking.vehicleId.isEmpty else { throw FirestoreError.missingID }

        let period = DateRange(start: booking.pickupDate, end: booking.returnDate)
        guard period.isValid else { throw FirestoreError.invalidPeriod }

        let vehicleRef = collection(Constants.Firestore.vehicles).document(booking.vehicleId)
        let bookingRef = collection(Constants.Firestore.bookings).document()

        _ = try await db.runTransaction { transaction, errorPointer -> Any? in
            let snapshot: DocumentSnapshot
            do {
                snapshot = try transaction.getDocument(vehicleRef)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }

            guard let vehicle = try? snapshot.data(as: Vehicle.self) else {
                errorPointer?.pointee = FirestoreError.vehicleNotFound as NSError
                return nil
            }

            guard vehicle.canBeBooked(for: period) else {
                errorPointer?.pointee = FirestoreError.vehicleUnavailable as NSError
                return nil
            }

            var updated = vehicle
            updated.bookedPeriods = (vehicle.bookedPeriods ?? []) + [period]

            do {
                try transaction.setData(from: updated, forDocument: vehicleRef)
                try transaction.setData(from: booking, forDocument: bookingRef)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }

            return nil
        }

        return bookingRef.documentID
    }

    func fetchBookings(userId: String) async throws -> [Booking] {
        // Newest first, sorted in Swift to avoid needing a composite index
        // (where-filter + orderBy on a different field).
        let snapshot = try await collection(Constants.Firestore.bookings)
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        return snapshot.documents
            .compactMap { try? $0.data(as: Booking.self) }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func updateBookingStatus(_ bookingId: String, status: Booking.BookingStatus) async throws {
        try await collection(Constants.Firestore.bookings).document(bookingId)
            .updateData(["status": status.rawValue])
    }

    // MARK: - Payments
    func fetchPayments(userId: String) async throws -> [PaymentRecord] {
        // Newest first, sorted in Swift to avoid needing a composite index.
        let snapshot = try await collection(Constants.Firestore.payments)
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        return snapshot.documents
            .compactMap { try? $0.data(as: PaymentRecord.self) }
            .sorted { $0.transactionDate > $1.transactionDate }
    }

    // MARK: - Driving Stats
    func fetchStats(userId: String) async throws -> [DrivingStats] {
        let snapshot = try await collection(Constants.Firestore.stats)
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: DrivingStats.self) }
    }

    // MARK: - Seeding

    /// Writes the supplied vehicles using each vehicle's `id` as the document ID, so running
    /// it again overwrites instead of duplicating. Backs the debug "Seed Firestore" action
    /// that fills an empty database with the sample catalogue.
    func seedVehicles(_ vehicles: [Vehicle]) async throws {
        let batch = db.batch()
        for vehicle in vehicles {
            guard let id = vehicle.id, !id.isEmpty else { continue }
            let ref = collection(Constants.Firestore.vehicles).document(id)
            try batch.setData(from: vehicle, forDocument: ref)
        }
        try await batch.commit()
    }
}

// MARK: - Errors
enum FirestoreError: LocalizedError {
    case missingID
    case decodingFailed
    case documentNotFound
    case invalidPeriod
    case vehicleNotFound
    case vehicleUnavailable

    var errorDescription: String? {
        switch self {
        case .missingID:          return "Document ID is missing."
        case .decodingFailed:     return "Failed to decode document data."
        case .documentNotFound:   return "Document not found."
        case .invalidPeriod:      return "The return date must be after the pickup date."
        case .vehicleNotFound:    return "This vehicle is no longer in the catalogue."
        case .vehicleUnavailable: return "This vehicle has just been booked for your dates. Please choose another vehicle or change your dates."
        }
    }
}
