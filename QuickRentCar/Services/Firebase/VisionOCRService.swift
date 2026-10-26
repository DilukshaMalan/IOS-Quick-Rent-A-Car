import Foundation
import Vision
import UIKit
import ImageIO

class VisionOCRService {
    static let shared = VisionOCRService()
    private init() {}

    // MARK: - Two-Side Helpers

    func extractFrontInfo(from image: UIImage) async throws -> LicenseInfo {
        guard let cgImage = image.cgImage else { throw OCRError.invalidImage }
        let orientation = CGImagePropertyOrientation(uiOrientation: image.imageOrientation)
        let lines = try await recognizeLines(in: cgImage, orientation: orientation)
        guard !lines.isEmpty else { throw OCRError.noTextFound }
        var info = parseLicenseFields(from: lines)
        info.expiryDate = nil   // expiry comes from the rear; clear any mis-read value
        #if DEBUG
        printDebug(label: "FRONT", lines: lines, info: info)
        #endif
        return info
    }

    func extractExpiryDate(from image: UIImage) async throws -> Date? {
        guard let cgImage = image.cgImage else { throw OCRError.invalidImage }
        let orientation = CGImagePropertyOrientation(uiOrientation: image.imageOrientation)
        let lines = try await recognizeLines(in: cgImage, orientation: orientation)
        guard !lines.isEmpty else { throw OCRError.noTextFound }

        // Try labelled expiry first, then fall back to the latest date on the rear card.
        var expiry = labelledDate(
            matching: #"(?i)\b(expiry|expires|expiration|exp\.?|valid\s+(to|until|thru))"#,
            in: lines, endOfDay: true)
        if expiry == nil {
            let allDates = lines.flatMap { dateParts(in: $0) }.compactMap { makeDate($0, endOfDay: true) }
            expiry = allDates.max()
        }
        #if DEBUG
        print("🔎 [OCR] REAR \(lines.count) rows recognised:")
        for (index, line) in lines.enumerated() { print("   \(index): \(line)") }
        print("🔎 [OCR] REAR expiry: \(String(describing: expiry))")
        #endif
        return expiry
    }

    // MARK: - Extract License Info from Image
    func extractLicenseInfo(from image: UIImage) async throws -> LicenseInfo {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }

        let orientation = CGImagePropertyOrientation(uiOrientation: image.imageOrientation)
        let lines = try await recognizeLines(in: cgImage, orientation: orientation)
        guard !lines.isEmpty else { throw OCRError.noTextFound }

        let info = parseLicenseFields(from: lines)
        #if DEBUG
        printDebug(label: "SINGLE", lines: lines, info: info)
        #endif
        return info
    }

    // MARK: - Text Recognition
    /// Returns one string per visual row of the card (top to bottom, left to right).
    /// Fragments that sit on the same row are separated by TWO spaces — the parser relies on that.
    private func recognizeLines(in cgImage: CGImage,
                                orientation: CGImagePropertyOrientation) async throws -> [String] {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let request = VNRecognizeTextRequest()
                request.recognitionLevel = .accurate
                // Correction "fixes" names and ID numbers into real words, which hurts here.
                request.usesLanguageCorrection = false
                // The printed address and name are small (about 2% of the card photo's height).
                // Vision skips text smaller than its default minimum height, so allow smaller text.
                request.minimumTextHeight = 0.01

                let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
                do {
                    try handler.perform([request])
                    let observations = request.results ?? []
                    continuation.resume(returning: Self.makeLines(from: observations))
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private struct Piece {
        let text: String
        let box: CGRect
    }

    /// Groups the recognised fragments into rows by their position, so "4a." and its
    /// value end up on the same line even though Vision returns them as separate fragments.
    private static func makeLines(from observations: [VNRecognizedTextObservation]) -> [String] {
        let pieces: [Piece] = observations.compactMap { observation in
            guard let candidate = observation.topCandidates(1).first,
                  candidate.confidence >= Constants.OCR.minimumConfidence else { return nil }
            return Piece(text: candidate.string, box: observation.boundingBox)
        }

        // Vision's origin is the bottom-left corner, so a larger midY means higher on the card.
        let sorted = pieces.sorted { $0.box.midY > $1.box.midY }

        var rows: [[Piece]] = []
        for piece in sorted {
            if let reference = rows.last?.first,
               abs(piece.box.midY - reference.box.midY) < max(piece.box.height, reference.box.height) * 0.6 {
                rows[rows.count - 1].append(piece)
            } else {
                rows.append([piece])
            }
        }

        return rows.map { row in
            row.sorted { $0.box.minX < $1.box.minX }
                .map(\.text)
                .joined(separator: "  ")
        }
    }

    // MARK: - Printed field numbers
    //
    // The Sri Lankan licence numbers its fields instead of naming them:
    //   1,2 name   3 date of birth   4a date of issue   4b authority   4c NIC
    //   5 licence number   8 address   12 restrictions
    // so there is no "Name" or "Licence No" word to search for — the number label is the anchor.

    private struct CardField {
        let label: String   // normalised: "5", "4c", "1,2", "8", "3"
        let value: String   // text after the label; separate OCR fragments are divided by two spaces
        let row: Int
    }

    /// A field label sits at the start of a row, or after the two-space gap between fragments.
    /// "5.B5817846D" (no space after the dot) is accepted. Day-of-month numbers such as "15."
    /// are not labels (only 1–12 are), and a label inside a fragment ("15.08.2001") is ignored.
    private static let fieldLabelRegex = try? NSRegularExpression(
        pattern: #"(?:^|(?<=\s\s))(1\s*[,.]\s*2|(?:1[0-2]|[1-9])[a-cA-C]?)\s*[.)]\s*"#
    )

    private func cardFields(from lines: [String]) -> [CardField] {
        guard let regex = Self.fieldLabelRegex else { return [] }
        var fields: [CardField] = []

        for (row, line) in lines.enumerated() {
            let ns = line as NSString
            let matches = regex.matches(in: line, range: NSRange(location: 0, length: ns.length))
            for (index, match) in matches.enumerated() {
                let valueStart = match.range.location + match.range.length
                let valueEnd = index + 1 < matches.count ? matches[index + 1].range.location : ns.length
                guard valueEnd >= valueStart else { continue }

                let label = ns.substring(with: match.range(at: 1))
                    .replacingOccurrences(of: " ", with: "")
                    .replacingOccurrences(of: ".", with: ",")
                    .lowercased()
                let value = ns.substring(with: NSRange(location: valueStart, length: valueEnd - valueStart))
                    .trimmingCharacters(in: .whitespaces)
                fields.append(CardField(label: label, value: value, row: row))
            }
        }
        return fields
    }

    private func hasFieldLabel(_ line: String) -> Bool {
        guard let regex = Self.fieldLabelRegex else { return false }
        let ns = line as NSString
        guard let match = regex.firstMatch(in: line, range: NSRange(location: 0, length: ns.length)) else { return false }
        return match.range.location == 0
    }

    /// Splits a row value into its OCR fragments (they are separated by two or more spaces).
    private func fragments(_ text: String) -> [String] {
        text.components(separatedBy: "  ")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    private func stripFieldNumber(_ line: String) -> String {
        line.replacingOccurrences(
            of: #"^\s*\d{1,2}[a-cA-C]?(\s*,\s*\d{1,2})?\s*[.)]\s*"#,
            with: "",
            options: .regularExpression
        )
    }

    // MARK: - Parse License Fields
    private func parseLicenseFields(from lines: [String]) -> LicenseInfo {
        var info = LicenseInfo(rawExtractedText: lines.joined(separator: "\n"))
        let fields = cardFields(from: lines)

        let number = parseLicenseNumber(from: lines, fields: fields)
        info.licenseNumber = number.number

        let name = parseName(from: lines, fields: fields, afterRow: number.row)
        info.fullName = name.name

        info.address = parseAddress(from: lines, fields: fields, nameRow: name.row)

        // Date of birth: printed field "3", else a "Date of birth" label (below: earliest old-enough date).
        if let field = fields.first(where: { $0.label == "3" }),
           let parts = dateParts(in: field.value).first {
            info.dateOfBirth = makeDate(parts)
        }
        if info.dateOfBirth == nil {
            info.dateOfBirth = labelledDate(matching: #"(?i)\b(d\.?o\.?b\.?|birth)"#, in: lines)
        }

        // Expiry (only used by the one-photo flow; the two-photo flow reads it from the rear).
        info.expiryDate = labelledDate(
            matching: #"(?i)\b(expiry|expires|expiration|exp\.?|valid\s+(to|until|thru))"#,
            in: lines,
            endOfDay: true
        )

        // An expiry date can't be before the date of birth, so it must have been misread.
        if let expiry = info.expiryDate, let dob = info.dateOfBirth, expiry <= dob {
            info.expiryDate = nil
        }

        // Fallbacks when a label could not be read. The date of issue (field 4a) is left out,
        // because it is neither the date of birth nor the expiry.
        let issueRows = Set(fields.filter { $0.label == "4a" }.map(\.row))
        let allDates = lines.enumerated()
            .filter { !issueRows.contains($0.offset) }
            .flatMap { dateParts(in: $0.element) }
            .compactMap { makeDate($0) }

        if info.dateOfBirth == nil {
            // Only a date at least 16 years back can be a date of birth.
            let cutoff = Calendar(identifier: .gregorian).date(byAdding: .year, value: -16, to: Date()) ?? Date()
            if let earliest = allDates.min(), earliest <= cutoff {
                info.dateOfBirth = earliest
            }
        }
        if info.expiryDate == nil, allDates.count >= 2, let latest = allDates.max(),
           latest > (info.dateOfBirth ?? .distantPast) {
            info.expiryDate = endOfDay(latest)
        }

        return info
    }

    // MARK: Name
    /// Words that appear on the card itself and are never part of a person's name.
    /// ("SRI" and "LANKA" are deliberately NOT here: "Sri" is a common part of Sri Lankan names.)
    private let headerWords: Set<String> = [
        "DRIVING", "LICENCE", "LICENSE", "REPUBLIC", "DEMOCRATIC", "SOCIALIST",
        "DEPARTMENT", "MOTOR", "TRAFFIC", "VEHICLE", "VEHICLES", "CLASS", "CLASSES", "CATEGORY",
        "ADDRESS", "DATE", "BIRTH", "EXPIRY", "ISSUE", "BLOOD", "GROUP", "SIGNATURE",
        "COMMISSIONER", "GENERAL", "NATIONAL", "IDENTITY", "CARD", "NIC", "VALID",
        "RESTRICTIONS", "ENDORSEMENTS", "HOLDER"
    ]

    private func cleanName(_ text: String) -> String {
        var s = text.trimmingCharacters(in: CharacterSet(charactersIn: " :.-–—\t"))
        if let firstDigit = s.firstIndex(where: { $0.isNumber }) {
            s = String(s[..<firstDigit])          // anything after a digit is another field
        }
        let allowed = CharacterSet.letters.union(CharacterSet(charactersIn: " .,'-"))
        s = String(s.unicodeScalars.filter { allowed.contains($0) })
        return s.trimmingCharacters(in: CharacterSet(charactersIn: " :.-,"))
    }

    private func isPlausibleName(_ text: String) -> Bool {
        let letters = text.filter { $0.isLetter }.count
        guard text.count >= 3, letters >= 3 else { return false }
        let words = text.split(separator: " ").map { $0.trimmingCharacters(in: CharacterSet(charactersIn: ".,'-")).uppercased() }
        return !words.contains(where: { headerWords.contains($0) })
    }

    private func lettersOK(_ text: String) -> Bool {
        text.count >= 3 && text.filter { $0.isLetter }.count >= 3
    }

    /// A name from one row's fragments. Tiny fragments (like the "SL" mark printed beside the
    /// name) are dropped; the remaining fragments are joined with single spaces.
    private func nameFrom(_ value: String) -> String {
        fragments(value)
            .map { cleanName($0) }
            .filter { piece in piece.filter { $0.isLetter }.count >= 3 }
            .joined(separator: " ")
    }

    /// Returns the name and the row it was found on (used to find the address below it).
    private func parseName(from lines: [String], fields: [CardField], afterRow numberRow: Int?) -> (name: String, row: Int?) {
        // 1) Printed field "1,2" (surname and given names) — the label is reliable, so no word filtering.
        if let field = fields.first(where: { $0.label == "1,2" }) {
            let name = nameFrom(field.value)
            if lettersOK(name) { return (name, field.row) }
        }
        // 1b) Separate fields "1" and "2"
        if let surname = fields.first(where: { $0.label == "1" }),
           let given = fields.first(where: { $0.label == "2" }) {
            let name = (nameFrom(surname.value) + " " + nameFrom(given.value)).trimmingCharacters(in: .whitespaces)
            if lettersOK(name) { return (name, given.row) }
        }

        // 2) A "Name" word label: value on the same row, or on the row below.
        for (index, line) in lines.enumerated() {
            guard let label = line.range(of: #"(?i)\b(full\s+)?names?\b\s*[:.\-]?"#, options: .regularExpression) else { continue }
            let lower = line.lowercased()
            if lower.contains("father") || lower.contains("mother") || lower.contains("spouse") { continue }

            let sameRow = nameFrom(String(line[label.upperBound...]))
            if isPlausibleName(sameRow) { return (sameRow, index) }

            if index + 1 < lines.count {
                let nextRow = nameFrom(lines[index + 1])
                if isPlausibleName(nextRow) { return (nextRow, index + 1) }
            }
        }

        // 3) No label found: the first row after the licence number that is ALL CAPITAL LETTERS,
        //    2+ words, with the field number (if any) removed. Mixed-case OCR noise is skipped.
        let start = numberRow ?? -1
        for (index, line) in lines.enumerated() where index > start {
            let stripped = stripFieldNumber(line)
            if stripped.contains(where: { $0.isNumber }) { continue }
            let candidate = nameFrom(stripped)
            if candidate == candidate.uppercased(),
               candidate.split(separator: " ").count >= 2,
               candidate.count >= 8,
               isPlausibleName(candidate) {
                return (candidate, index)
            }
        }
        return ("", nil)
    }

    // MARK: Licence number
    /// Returns the licence number and the row it was found on.
    private func parseLicenseNumber(from lines: [String], fields: [CardField]) -> (number: String, row: Int?) {
        // 1) Printed field "5". Letters + digits + optional trailing letter(s), e.g. B5817846D.
        if let field = fields.first(where: { $0.label == "5" }) {
            let token = (fragments(field.value).first ?? "").uppercased().replacingOccurrences(of: " ", with: "")
            if let match = token.range(of: #"[A-Z]{1,3}\d{6,8}[A-Z]{0,2}"#, options: .regularExpression) {
                return (String(token[match]), field.row)
            }
            let alnum = token.filter { $0.isLetter || $0.isNumber }
            if alnum.count >= 6, alnum.filter({ $0.isNumber }).count >= 5 {
                return (alnum, field.row)
            }
        }

        // 2) A "Licence No" word label (same row or the row below)
        let candidate = #"[A-Z]{0,3}\s?\d{6,9}[A-Z]{0,2}"#
        for (index, line) in lines.enumerated() {
            guard let label = line.range(of: #"(?i)\b(licen[cs]e|driving|d\.?l\.?)\s*(no|number|#)\.?"#, options: .regularExpression) else { continue }
            let sameRow = String(line[label.upperBound...]).uppercased()
            let nextRow = index + 1 < lines.count ? lines[index + 1].uppercased() : ""
            for text in [sameRow, nextRow] {
                if let match = text.range(of: candidate, options: .regularExpression) {
                    return (String(text[match]).replacingOccurrences(of: " ", with: ""), index)
                }
            }
        }

        // 3) No label: first thing shaped like a licence number (1–3 letters, 6–8 digits, optional letters).
        //    Rows mentioning an NIC / passport number are skipped (a bare NIC has no letter prefix anyway).
        for (index, line) in lines.enumerated() {
            let upper = line.uppercased()
            if upper.range(of: #"\bNIC\b"#, options: .regularExpression) != nil || upper.contains("PASSPORT") { continue }
            if let match = upper.range(of: #"\b[A-Z]{1,3}\s?\d{6,8}[A-Z]{0,2}\b"#, options: .regularExpression) {
                return (String(upper[match]).replacingOccurrences(of: " ", with: ""), index)
            }
        }
        return ("", nil)
    }

    // MARK: Address
    /// Only rows that clearly belong to other printed fields end an address.
    private let addressStopWords: Set<String> = [
        "BLOOD", "GROUP", "SIGNATURE", "HOLDER", "COMMISSIONER", "RESTRICTIONS", "ENDORSEMENTS",
        "DRIVING", "LICENCE", "LICENSE", "DEMOCRATIC", "SOCIALIST", "REPUBLIC"
    ]

    /// Keeps address-like fragments; short noise fragments (e.g. "S", "SS") are dropped.
    private func cleanAddress(_ text: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: " /,.-'"))
        return fragments(text)
            .map { fragment -> String in
                String(fragment.unicodeScalars.filter { allowed.contains($0) })
                    .trimmingCharacters(in: CharacterSet(charactersIn: " ,.-"))
            }
            .filter { piece in piece.filter { $0.isLetter || $0.isNumber }.count >= 3 }
            .joined(separator: " ")
    }

    /// The address is printed over 2–3 rows. It starts at printed field "8" — or, if that label was
    /// not read, on the row right below the name — and continues until the next printed field
    /// (e.g. "3." date of birth) or a date.
    private func parseAddress(from lines: [String], fields: [CardField], nameRow: Int?) -> String {
        var parts: [String] = []
        let startRow: Int
        var row: Int

        if let field = fields.first(where: { $0.label == "8" }) {
            startRow = field.row
            let first = cleanAddress(field.value)
            if !first.isEmpty { parts.append(first) }
            row = field.row + 1
        } else if let nameRow {
            startRow = nameRow
            row = nameRow + 1
        } else {
            return ""
        }

        while row < lines.count, parts.count < 3, row - startRow <= 4 {
            let line = lines[row]
            if hasFieldLabel(line) || !dateParts(in: line).isEmpty { break }

            let cleaned = cleanAddress(line)
            if !cleaned.isEmpty {
                let words = cleaned.split(separator: " ")
                    .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: ".,'-")).uppercased() }
                if words.contains(where: { addressStopWords.contains($0) }) { break }
                parts.append(cleaned)
            }
            row += 1
        }
        return parts.joined(separator: ", ")
    }

    // MARK: Dates
    private struct DateParts {
        let location: Int
        let year: Int
        let month: Int
        let day: Int
    }

    /// Finds dd-mm-yyyy / dd.mm.yyyy / dd/mm/yyyy and yyyy-mm-dd dates in a piece of text.
    /// Sri Lankan documents are day-first; day and month are only swapped when the numbers
    /// make day-first impossible (e.g. 05/25/2027).
    private func dateParts(in text: String) -> [DateParts] {
        var results: [DateParts] = []
        let ns = text as NSString
        let range = NSRange(location: 0, length: ns.length)

        func number(_ match: NSTextCheckingResult, _ group: Int) -> Int {
            Int(ns.substring(with: match.range(at: group))) ?? 0
        }

        if let ymd = try? NSRegularExpression(pattern: #"(?<!\d)(\d{4})\s*[./\-]\s*(\d{1,2})\s*[./\-]\s*(\d{1,2})(?!\d)"#) {
            for m in ymd.matches(in: text, range: range) {
                results.append(DateParts(location: m.range.location,
                                         year: number(m, 1), month: number(m, 2), day: number(m, 3)))
            }
        }

        if let dmy = try? NSRegularExpression(pattern: #"(?<!\d)(\d{1,2})\s*[./\-]\s*(\d{1,2})\s*[./\-]\s*(\d{4})(?!\d)"#) {
            for m in dmy.matches(in: text, range: range) {
                let a = number(m, 1), b = number(m, 2)
                let (day, month) = (b > 12 && a <= 12) ? (b, a) : (a, b)
                results.append(DateParts(location: m.range.location, year: number(m, 3), month: month, day: day))
            }
        }

        return results
            .filter { (1900...2100).contains($0.year) && (1...12).contains($0.month) && (1...31).contains($0.day) }
            .sorted { $0.location < $1.location }
    }

    /// Builds a real date (noon, so it shows the same day in any time zone). Rejects 31/02 style overflow.
    private func makeDate(_ parts: DateParts, endOfDay: Bool = false) -> Date? {
        var components = DateComponents()
        components.year = parts.year
        components.month = parts.month
        components.day = parts.day
        components.hour = endOfDay ? 23 : 12
        components.minute = endOfDay ? 59 : 0

        let calendar = Calendar(identifier: .gregorian)
        guard let date = calendar.date(from: components) else { return nil }
        let check = calendar.dateComponents([.year, .month, .day], from: date)
        guard check.year == parts.year, check.month == parts.month, check.day == parts.day else { return nil }
        return date
    }

    private func endOfDay(_ date: Date) -> Date {
        Calendar(identifier: .gregorian).date(bySettingHour: 23, minute: 59, second: 0, of: date) ?? date
    }

    /// The first date after a label — on the same row (after the label), or on the row below.
    private func labelledDate(matching pattern: String, in lines: [String], endOfDay: Bool = false) -> Date? {
        for (index, line) in lines.enumerated() {
            guard let label = line.range(of: pattern, options: .regularExpression) else { continue }

            let afterLabel = String(line[label.upperBound...])
            if let parts = dateParts(in: afterLabel).first, let date = makeDate(parts, endOfDay: endOfDay) {
                return date
            }
            if index + 1 < lines.count,
               let parts = dateParts(in: lines[index + 1]).first,
               let date = makeDate(parts, endOfDay: endOfDay) {
                return date
            }
        }
        return nil
    }

    // MARK: - Debug
    #if DEBUG
    /// Prints what Vision read and what was extracted, to tune the rules against real licences.
    /// (Contains personal data — keep DEBUG-only.)
    private func printDebug(label: String, lines: [String], info: LicenseInfo) {
        print("🔎 [OCR] \(label): \(lines.count) rows recognised:")
        for (index, line) in lines.enumerated() { print("   \(index): \(line)") }
        print("🔎 [OCR] \(label) -> name: '\(info.fullName)' | number: '\(info.licenseNumber)' | address: '\(info.address)' | dob: \(String(describing: info.dateOfBirth)) | expiry: \(String(describing: info.expiryDate))")
    }
    #endif
}

// MARK: - Orientation
private extension CGImagePropertyOrientation {
    init(uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
        case .up:            self = .up
        case .upMirrored:    self = .upMirrored
        case .down:          self = .down
        case .downMirrored:  self = .downMirrored
        case .left:          self = .left
        case .leftMirrored:  self = .leftMirrored
        case .right:         self = .right
        case .rightMirrored: self = .rightMirrored
        @unknown default:    self = .up
        }
    }
}

// MARK: - Errors
enum OCRError: LocalizedError {
    case invalidImage
    case noTextFound

    var errorDescription: String? {
        switch self {
        case .invalidImage: return "Could not process the image."
        case .noTextFound:  return "No text was detected. Use good light and keep the whole license in the picture."
        }
    }
}
