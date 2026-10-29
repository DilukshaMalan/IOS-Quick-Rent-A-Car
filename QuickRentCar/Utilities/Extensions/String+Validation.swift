import Foundation

extension String {
    var isValidEmail: Bool {
        guard !self.contains("..") else { return false }
        let emailRegex = #"^[A-Za-z0-9._%+\-]+@([A-Za-z0-9\-]+\.)+[A-Za-z]{2,}$"#
        return self.range(of: emailRegex, options: .regularExpression) != nil
    }

    var isValidPassword: Bool {
        self.count >= 8
    }

    var isValidPhoneNumber: Bool {
        let digits = self.filter { $0.isNumber }
        return digits.count >= 10
    }

    var trimmed: String {
        self.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isNotEmpty: Bool {
        !trimmed.isEmpty
    }
}
