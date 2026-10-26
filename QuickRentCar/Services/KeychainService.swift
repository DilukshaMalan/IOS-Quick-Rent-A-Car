import Foundation
import Security

/// Thin wrapper around the iOS Keychain for securely storing string values.
/// Used to persist Face-ID login credentials so the user can re-authenticate
/// after a full sign-out without re-typing their email and password.
final class KeychainService {
    static let shared = KeychainService()
    private init() {}

    private let service = "com.quickrentcar.app"

    // MARK: - Save
    @discardableResult
    func save(_ value: String, forKey key: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }

        // Delete any existing entry first so SecItemAdd doesn't fail with errSecDuplicateItem.
        delete(forKey: key)

        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
            kSecValueData:   data
        ]
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    // MARK: - Read
    func read(forKey key: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass:            kSecClassGenericPassword,
            kSecAttrService:      service,
            kSecAttrAccount:      key,
            kSecReturnData:       true,
            kSecMatchLimit:       kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else { return nil }
        return value
    }

    // MARK: - Delete
    @discardableResult
    func delete(forKey key: String) -> Bool {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}

// MARK: - Typed keys
extension KeychainService {
    enum Key {
        static let biometricEmail    = "biometric_email"
        static let biometricPassword = "biometric_password"
    }

    /// Saves email + password for Face ID / Touch ID re-authentication.
    func saveBiometricCredentials(email: String, password: String) {
        save(email,    forKey: Key.biometricEmail)
        save(password, forKey: Key.biometricPassword)
    }

    /// Returns `(email, password)` if both are stored, otherwise `nil`.
    var biometricCredentials: (email: String, password: String)? {
        guard let email    = read(forKey: Key.biometricEmail),
              let password = read(forKey: Key.biometricPassword),
              !email.isEmpty, !password.isEmpty else { return nil }
        return (email, password)
    }

    /// Removes stored biometric credentials (call when Face ID is disabled).
    func clearBiometricCredentials() {
        delete(forKey: Key.biometricEmail)
        delete(forKey: Key.biometricPassword)
    }
}
