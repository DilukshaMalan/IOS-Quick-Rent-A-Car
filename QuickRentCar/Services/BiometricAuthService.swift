import Foundation
import LocalAuthentication

class BiometricAuthService {
    static let shared = BiometricAuthService()
    private init() {}

    private let context = LAContext()

    // MARK: - Availability
    var isBiometricAvailable: Bool {
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    var biometricType: LABiometryType {
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        return context.biometryType
    }

    var biometricTypeName: String {
        switch biometricType {
        case .faceID:       return "Face ID"
        case .touchID:      return "Touch ID"
        case .opticID:      return "Optic ID"
        default:            return "Biometrics"
        }
    }

    // MARK: - Authenticate
    func authenticate(reason: String) async -> Bool {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return false
        }

        do {
            return try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
        } catch {
            return false
        }
    }

    // MARK: - Face ID Preference
    var isFaceIDEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: Constants.UserDefaultsKeys.isFaceIDEnabled) }
        set { UserDefaults.standard.set(newValue, forKey: Constants.UserDefaultsKeys.isFaceIDEnabled) }
    }
}
