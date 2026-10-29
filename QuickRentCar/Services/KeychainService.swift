import Foundation
import Security

final class KeychainService {
    static let shared = KeychainService()
    private init() {}

    private let service = "com.quickrentcar.app"

    @discardableResult
    func save(_ value: String, forKey key: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }

        delete(forKey: key)

        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
            kSecValueData:   data
        ]
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

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

extension KeychainService {
    enum Key {
        static let biometricEmail    = "biometric_email"
        static let biometricPassword = "biometric_password"
    }

    func saveBiometricCredentials(email: String, password: String) {
        save(email,    forKey: Key.biometricEmail)
        save(password, forKey: Key.biometricPassword)
    }

    var biometricCredentials: (email: String, password: String)? {
        guard let email    = read(forKey: Key.biometricEmail),
              let password = read(forKey: Key.biometricPassword),
              !email.isEmpty, !password.isEmpty else { return nil }
        return (email, password)
    }

    func clearBiometricCredentials() {
        delete(forKey: Key.biometricEmail)
        delete(forKey: Key.biometricPassword)
    }
}
