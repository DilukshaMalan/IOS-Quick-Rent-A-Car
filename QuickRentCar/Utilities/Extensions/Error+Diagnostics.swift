import Foundation

extension Error {
    /// Firebase's `localizedDescription` is often a useless wrapper, e.g.
    /// "An internal error has occurred, print and inspect the error details for more information."
    ///
    /// The real reason is nested inside `userInfo`:
    ///   `NSUnderlyingErrorKey` -> an error in `FIRAuthInternalErrorDomain`
    ///     -> `FIRAuthErrorUserInfoDeserializedResponseKey` -> the raw backend JSON.
    ///
    /// This walks that chain and returns everything worth reading.
    var diagnosticDescription: String {
        var lines: [String] = []
        var current: NSError? = self as NSError
        var depth = 0

        while let error = current, depth < 5 {
            let indent = String(repeating: "  ", count: depth)
            lines.append("\(indent)[\(depth)] \(error.domain) code=\(error.code)")
            lines.append("\(indent)    description: \(error.localizedDescription)")

            // The raw server response — this is where the actual cause usually is.
            if let response = error.userInfo["FIRAuthErrorUserInfoDeserializedResponseKey"] {
                lines.append("\(indent)    deserializedResponse: \(response)")
            }

            let extra = error.userInfo.filter { entry in
                let key = entry.key
                return key != NSLocalizedDescriptionKey
                    && key != NSUnderlyingErrorKey
                    && key != "FIRAuthErrorUserInfoDeserializedResponseKey"
            }
            if !extra.isEmpty {
                lines.append("\(indent)    userInfo: \(extra)")
            }

            current = error.userInfo[NSUnderlyingErrorKey] as? NSError
            depth += 1
        }

        return lines.joined(separator: "\n")
    }
}
