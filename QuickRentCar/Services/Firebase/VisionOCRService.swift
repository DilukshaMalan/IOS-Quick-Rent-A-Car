import Foundation
import Vision
import UIKit
import ImageIO

class VisionOCRService {
    static let shared = VisionOCRService()
    private init() {}

    // MARK: - Two-Side Helpers

    /// Extracts name, licence number and date of birth from the **front** side.
    func extractFrontInfo(from image: UIImage) async throws -> LicenseInfo {
        guard let cgImage = image.cgImage else { throw OCRError.invalidImage }
        let orientation = CGImagePropertyOrientation(uiOrientation: image.imageOrientation)
        let lines = try await recognizeLines(in: cgImage, orientation: orientation)
        guard !lines.isEmpty else { throw OCRError.noTextFound }
        var info = parseLicenseFields(from: lines)
        info.expiryDate = nil   // expiry comes from the rear; clear any mis-read value
        return info
    }

    /// Extracts only the expiry date from the **rear** side.
    func extractExpiryDate(from image: UIImage) async throws -> Date? {
        guard let cgImage = image.cgImage else { throw OCRError.invalidImage }
        let orientation = CGImagePropertyOrientation(uiOrientation: image.imageOrientation)
        let lines = try await recognizeLines(in: cgImage, orientation: orientation)
        // Try labelled expiry first, then fall back to the latest date on the rear card.
        if let expiry = labelledDate(
            matching: #"(?i)\b(expiry|expires|expiration|exp\.?|valid\s+(to|until|thru))"#,
            in: lines, endOfDay: true) {
            return expiry
        }
        let allDates = lines.flatMap { dateParts(in: $0) }.compactMap { makeDate($0, endOfDay: true) }
        return allDates.max()
    }

    // MARK: - Extract License Info from Image
    func extractLicenseInfo(from image: UIImage) async throws -> LicenseInfo {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }

        // Photos from the camera and the gallery are usually stored sideways with an orientation flag.
        // Vision must be told about it, otherwise it reads the card rotated and finds little or nothing.
        let orientation = CGImagePropertyOrientation(uiOrientation: image.imageOrientation)
        let lines = try await recognizeLines(in: cgImage, orientation: orientation)
        guard !lines.isEmpty else { throw OCRError.noTextFound }

        let info = parseLicenseFields(from: lines)
        #if DEBUG
        printDebug(lines: lines, info: info)
        #endif
        return info
    }

    // MARK: - Text Recognition
    /// Returns one string per visual row of the card (top to bottom, left to right).
    private func recognizeLines(in cgImage: CGImage,
                                orientation: CGImagePropertyOrientation) async throws -> [String] {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let request = VNRecognizeTextRequest()
                request.recognitionLevel = .accurate
                // Correction "fixes" names and ID numbers into real words, which hurts here.
                request.usesLanguageCorrection = false

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

    /// Groups the recognised fragments into rows by their position, so "Date of Expiry" and its
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

    // MARK: - Parse License Fields
    private func parseLicenseFields(from lines: [String]) -> LicenseInfo {
        var info = LicenseInfo(rawExtractedText: lines.joined(separator: "\n"))

        info.fullName = parseName(from: lines)
        info.licenseNumber = parseLicenseNumber(from: lines)

        info.dateOfBirth = labelledDate(
            matching: #"(?i)\b(d\.?o\.?b\.?|birth)"#,
            in: lines
        )
        info.expiryDate = labelledDate(
            matching: #"(?i)\b(expiry|expires|expiration|exp\.?|valid\s+(to|until|thru))"#,
            in: lines,
            endOfDay: true
        )

        // An expiry date can't be before the date of birth, so it must have been misread.
        if let expiry = info.expiryDate, let dob = info.dateOfBirth, expiry <= dob {
            info.expiryDate = nil
        }

        // Fallbacks when a label could not be read: on a licence the expiry is the latest date
        // and the date of birth is the earliest.
        let allDates = lines.flatMap { dateParts(in: $0) }.compactMap { makeDate($0) }
        if allDates.count >= 2, let earliest = allDates.min(), let latest = allDates.max() {
            if info.expiryDate == nil, latest > (info.dateOfBirth ?? .distantPast) {
                info.expiryDate = endOfDay(latest)
            }
            if info.dateOfBirth == nil, latest.timeIntervalSince(earliest) > 5 * 365 * 86_400 {
                info.dateOfBirth = earliest
            }
        }

        return info
    }

    // MARK: Name
    /// Words that appear on the card itself and are never part of a person's name.
    private let headerWords: Set<String> = [
        "DRIVING", "LICENCE", "LICENSE", "REPUBLIC", "DEMOCRATIC", "SOCIALIST", "SRI", "LANKA",
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

    private func parseName(from lines: [String]) -> String {
        // 1) Use the "Name" label: value on the same row, or on the row below.
        for (index, line) in lines.enumerated() {
            guard let label = line.range(of: #"(?i)\b(full\s+)?names?\b\s*[:.\-]?"#, options: .regularExpression) else { continue }
            let lower = line.lowercased()
            if lower.contains("father") || lower.contains("mother") || lower.contains("spouse") { continue }

            let sameRow = cleanName(String(line[label.upperBound...]))
            if isPlausibleName(sameRow) { return sameRow }

            if index + 1 < lines.count {
                let nextRow = cleanName(lines[index + 1])
                if isPlausibleName(nextRow) { return nextRow }
            }
        }

        // 2) No label found: first row that looks like a person's name (2+ words, letters only).
        for line in lines where !line.contains(where: { $0.isNumber }) {
            let candidate = cleanName(line)
            if candidate.split(separator: " ").count >= 2, candidate.count >= 8, isPlausibleName(candidate) {
                return candidate
            }
        }
        return ""
    }

    // MARK: Licence number
    private func parseLicenseNumber(from lines: [String]) -> String {
        let candidate = #"[A-Z]{0,3}\s?\d{6,9}"#

        // 1) After a "Licence No" style label (same row or the row below)
        for (index, line) in lines.enumerated() {
            guard let label = line.range(of: #"(?i)\b(licen[cs]e|driving|d\.?l\.?)\s*(no|number|#)\.?"#, options: .regularExpression) else { continue }
            let sameRow = String(line[label.upperBound...]).uppercased()
            let nextRow = index + 1 < lines.count ? lines[index + 1].uppercased() : ""
            for text in [sameRow, nextRow] {
                if let match = text.range(of: candidate, options: .regularExpression) {
                    return String(text[match]).replacingOccurrences(of: " ", with: "")
                }
            }
        }

        // 2) No label: first thing shaped like a licence number (1–3 letters + 6–8 digits).
        //    Rows mentioning an NIC / passport number are skipped.
        for line in lines {
            let upper = line.uppercased()
            if upper.range(of: #"\bNIC\b"#, options: .regularExpression) != nil || upper.contains("PASSPORT") { continue }
            if let match = upper.range(of: #"\b[A-Z]{1,3}\s?\d{6,8}\b"#, options: .regularExpression) {
                return String(upper[match]).replacingOccurrences(of: " ", with: "")
            }
        }
        return ""
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
    /// (Contains personal data — remove or keep DEBUG-only.)
    private func printDebug(lines: [String], info: LicenseInfo) {
        print("🔎 [OCR] \(lines.count) rows recognised:")
        for (index, line) in lines.enumerated() { print("   \(index): \(line)") }
        print("🔎 [OCR] name: '\(info.fullName)' | number: '\(info.licenseNumber)' | dob: \(String(describing: info.dateOfBirth)) | expiry: \(String(describing: info.expiryDate))")
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
