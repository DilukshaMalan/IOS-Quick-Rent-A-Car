import Foundation

extension Error {
    var diagnosticDescription: String {
        var lines: [String] = []
        var current: NSError? = self as NSError
        var depth = 0

        while let error = current, depth < 5 {
            let indent = String(repeating: "  ", count: depth)
            lines.append("\(indent)[\(depth)] \(error.domain) code=\(error.code)")
            lines.append("\(indent)    description: \(error.localizedDescription)")

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
