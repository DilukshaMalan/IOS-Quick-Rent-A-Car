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

    // MARK: - Auth State
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
                // User document may not exist yet (just registered)
            }
        }
    }

    // MARK: - Diagnostics

    /// Firebase's `localizedDescription` hides the real cause behind a generic
    /// "internal error" message. In DEBUG, dump the full nested error chain.
    private func logDiagnostics(_ error: Error, context: String) {
        #if DEBUG
        print("❌ AuthViewModel.\(context) failed:\n\(error.diagnosticDescription)")
        #endif
    }

    // MARK: - Sign In
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

            // If Face ID is enabled, require biometric confirmation after credential sign-in.
            if BiometricAuthService.shared.isFaceIDEnabled {
                let success = await BiometricAuthService.shared.authenticate(
                    reason: "Sign in to QuickRentCar"
                )
                if !success {
                    errorMessage = "Biometric authentication failed."
                    try? authService.signOut()
                }
            }
        } catch {
            errorMessage = error.localizedDescription
            logDiagnostics(error, context: "signIn")
        }
    }

    // MARK: - Biometric-only Sign In
    /// Used when the user taps the Face ID / Touch ID button on the login screen.
    /// This path skips entering email & password — it verifies the biometric locally,
    /// then checks that Firebase still has a valid cached session (the user was
    /// previously logged in). If Firebase has no session the user must sign in with
    /// credentials first so the token can be cached.
    func signInWithBiometrics() async {
        guard BiometricAuthService.shared.isBiometricAvailable else {
            errorMessage = "\(BiometricAuthService.shared.biometricTypeName) is not available on this device."
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        // Step 1: local biometric check
        let biometricOK = await BiometricAuthService.shared.authenticate(
            reason: "Sign in to QuickRentCar"
        )
        guard biometricOK else {
            errorMessage = "\(BiometricAuthService.shared.biometricTypeName) authentication failed."
            return
        }

        // Step 2: confirm Firebase has a live session (currentUser non-nil means the
        //         token is cached from the last credential sign-in).
        if authService.currentUser != nil {
            // Session is already active — just mark authenticated.
            isAuthenticated = true
        } else {
            errorMessage = "No saved session found. Please sign in with your email and password first to enable \(BiometricAuthService.shared.biometricTypeName) login."
        }
    }

    // MARK: - Register
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

    // MARK: - Sign Out
    func signOut() {
        do {
            try authService.signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
