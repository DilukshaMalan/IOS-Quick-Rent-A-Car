import Foundation
import FirebaseAuth

@MainActor
class AuthService {
    static let shared = AuthService()
    private init() {}

    // MARK: - Current User
    var currentUser: FirebaseAuth.User? {
        Auth.auth().currentUser
    }

    var currentUserId: String? {
        currentUser?.uid
    }

    // MARK: - Sign In
    func signIn(email: String, password: String) async throws {
        try await Auth.auth().signIn(withEmail: email, password: password)
    }

    // MARK: - Register
    func register(email: String, password: String) async throws -> FirebaseAuth.User {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        return result.user
    }

    // MARK: - Sign Out
    func signOut() throws {
        try Auth.auth().signOut()
    }

    // MARK: - Password Reset
    func resetPassword(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }

    // MARK: - Auth State Listener
    func addAuthStateListener(completion: @escaping (FirebaseAuth.User?) -> Void) -> AuthStateDidChangeListenerHandle {
        Auth.auth().addStateDidChangeListener { _, user in
            completion(user)
        }
    }

    /// Deliberately `nonisolated`: listener removal is thread-safe in Firebase, and
    /// `deinit` is always nonisolated, so it can't call a `@MainActor` method synchronously.
    nonisolated func removeAuthStateListener(_ handle: AuthStateDidChangeListenerHandle) {
        Auth.auth().removeStateDidChangeListener(handle)
    }
}
