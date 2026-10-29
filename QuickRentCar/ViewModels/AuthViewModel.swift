import Foundation
import FirebaseAuth
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var authStateHandle: AuthStateDidChangeListenerHandle?
    private let authService = AuthService.shared
    private let firestoreService = FirestoreService.shared

    init() {
        setupAuthStateListener()
    }

    deinit {
        if let handle = authStateHandle {
            authService.removeAuthStateListener(handle)
        }
    }

    private func setupAuthStateListener() {
        authStateHandle = authService.addAuthStateListener { [weak self] firebaseUser in
            Task { @MainActor in
                if let firebaseUser = firebaseUser {
                    self?.isAuthenticated = true
                    self?.loadCurrentUser(uid: firebaseUser.uid)
                } else {
                    self?.isAuthenticated = false
                    self?.currentUser = nil
                }
            }
        }
    }

    private func loadCurrentUser(uid: String) {
        Task {
            do {
                self.currentUser = try await firestoreService.fetchUser(id: uid)
            } catch {
            }
        }
    }

    private func logDiagnostics(_ error: Error, context: String) {
        #if DEBUG
        print("❌ AuthViewModel.\(context) failed:\n\(error.diagnosticDescription)")
        #endif
    }

    func signIn(email: String, password: String) async {
        guard email.isValidEmail else {
            errorMessage = "Please enter a valid email address."
            return
        }
        guard password.isNotEmpty else {
            errorMessage = "Please enter your password."
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await authService.signIn(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
            logDiagnostics(error, context: "signIn")
        }
    }

    func register(email: String, password: String, fullName: String, phoneNumber: String) async {
        guard email.isValidEmail else {
            errorMessage = "Please enter a valid email address."
            return
        }
        guard password.isValidPassword else {
            errorMessage = "Password must be at least 8 characters."
            return
        }
        guard fullName.isNotEmpty else {
            errorMessage = "Please enter your full name."
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let firebaseUser = try await authService.register(email: email, password: password)
            let user = User(
                id: firebaseUser.uid,
                email: email,
                fullName: fullName,
                phoneNumber: phoneNumber
            )
            try await firestoreService.createUser(user)
            self.currentUser = user
        } catch {
            errorMessage = error.localizedDescription
            logDiagnostics(error, context: "register")
        }
    }

    func signOut() {
        do {
            try authService.signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
