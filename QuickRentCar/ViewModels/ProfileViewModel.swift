import Foundation

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var bookings: [Booking] = []
    @Published var payments: [PaymentRecord] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isFaceIDEnabled: Bool = BiometricAuthService.shared.isFaceIDEnabled

    private let firestoreService = FirestoreService.shared

    func loadProfile(userId: String) async {
        isLoading = true
        defer { isLoading = false }

        async let userTask = firestoreService.fetchUser(id: userId)
        async let bookingsTask = firestoreService.fetchBookings(userId: userId)
        async let paymentsTask = firestoreService.fetchPayments(userId: userId)

        do {
            (user, bookings, payments) = try await (userTask, bookingsTask, paymentsTask)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleFaceID() {
        isFaceIDEnabled.toggle()
        BiometricAuthService.shared.isFaceIDEnabled = isFaceIDEnabled
    }

    func updateProfile(fullName: String, phoneNumber: String, userId: String) async {
        guard var updatedUser = user else { return }
        updatedUser.fullName = fullName
        updatedUser.phoneNumber = phoneNumber

        do {
            try await firestoreService.updateUser(updatedUser)
            user = updatedUser
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
