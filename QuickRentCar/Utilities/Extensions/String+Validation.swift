import Foundation

extension String {
    /// Basic email validation
    var isValidEmail: Bool {
        let emailRegex = #"^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#
        return self.range(of: emailRegex, options: .regularExpression) != nil
    }

    /// Password must be at least 8 characters
    var isValidPassword: Bool {
        self.count >= 8
    }

    /// Phone number — digits only, 10+ chars
    var isValidPhoneNumber: Bool {
        let digits = self.filter { $0.isNumber }
        return digits.count >= 10
    }

    /// Trim whitespace and newlines
    var trimmed: String {
        self.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Check if string is non-empty after trimming
    var isNotEmpty: Bool {
        !trimmed.isEmpty
    }
}
