import Foundation
import FirebaseAuth

@MainActor
class AuthService {
    static let shared = AuthService()
    private init() {}


    var currentUser: FirebaseAuth.User? {
        Auth.auth().currentUser
    }

    var currentUserId: String? {
        currentUser?.uid
    }

    func signIn(email: String, password: String) async throws {
        try await Auth.auth().signIn(withEmail: email, password: password)
    }

    func register(email: String, password: String) async throws -> FirebaseAuth.User {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        return result.user
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }

    func resetPassword(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }

    func addAuthStateListener(completion: @escaping (FirebaseAuth.User?) -> Void) -> AuthStateDidChangeListenerHandle {
        Auth.auth().addStateDidChangeListener { _, user in
            completion(user)
        }
    }


    nonisolated func removeAuthStateListener(_ handle: AuthStateDidChangeListenerHandle) {
        Auth.auth().removeStateDidChangeListener(handle)
    }
}
