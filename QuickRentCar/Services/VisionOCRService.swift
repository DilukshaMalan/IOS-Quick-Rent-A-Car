import Foundation
import Vision
import UIKit

class VisionOCRService {
    static let shared = VisionOCRService()
    private init() {}

    // MARK: - Extract License Info from Image
    func extractLicenseInfo(from image: UIImage) async throws -> LicenseInfo {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }

        let rawText = try await recognizeText(in: cgImage)
        return parseLicenseFields(from: rawText)
    }

    // MARK: - Text Recognition
    private func recognizeText(in cgImage: CGImage) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let recognizedText = observations.compactMap { observation -> String? in
                    guard let candidate = observation.topCandidates(1).first,
                          candidate.confidence >= Constants.OCR.minimumConfidence else { return nil }
                    return candidate.string
                }.joined(separator: "\n")

                continuation.resume(returning: recognizedText)
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    // MARK: - Parse License Fields
    private func parseLicenseFields(from text: String) -> LicenseInfo {
        let lines = text.components(separatedBy: .newlines)
        var licenseInfo = LicenseInfo(rawExtractedText: text)

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US")

        for (index, line) in lines.enumerated() {
            let cleanLine = line.trimmingCharacters(in: .whitespaces)

            // Name — typically "SURNAME, GIVEN NAME" or all caps line
            if cleanLine.allSatisfy({ $0.isLetter || $0.isWhitespace || $0 == "," }) && cleanLine.count > 5 {
                if licenseInfo.fullName.isEmpty { licenseInfo.fullName = cleanLine }
            }

            // License Number — alphanumeric sequence
            if cleanLine.range(of: #"[A-Z]{1,3}\d{6,8}"#, options: .regularExpression) != nil {
                licenseInfo.licenseNumber = cleanLine
            }

            // Dates — DOB/Expiry typically labeled
            if cleanLine.lowercased().contains("dob") || cleanLine.lowercased().contains("birth") {
                if let date = extractDate(from: lines, near: index, formatter: dateFormatter) {
                    licenseInfo.dateOfBirth = date
                }
            }

            if cleanLine.lowercased().contains("exp") {
                if let date = extractDate(from: lines, near: index, formatter: dateFormatter) {
                    licenseInfo.expiryDate = date
                }
            }
        }

        return licenseInfo
    }

    private func extractDate(from lines: [String], near index: Int, formatter: DateFormatter) -> Date? {
        let formats = ["MM/dd/yyyy", "dd/MM/yyyy", "yyyy-MM-dd", "dd-MM-yyyy", "MM-dd-yyyy"]
        let range = max(0, index-1)...min(lines.count-1, index+1)

        for i in range {
            let text = lines[i]
            for format in formats {
                formatter.dateFormat = format
                if let date = formatter.date(from: text.trimmingCharacters(in: .whitespaces)) {
                    return date
                }
                // Try extracting a date substring
                let dateRegex = #"\d{2}[/\-]\d{2}[/\-]\d{2,4}"#
                if let match = text.range(of: dateRegex, options: .regularExpression) {
                    let dateString = String(text[match])
                    formatter.dateFormat = format
                    if let date = formatter.date(from: dateString) {
                        return date
                    }
                }
            }
        }
        return nil
    }
}

// MARK: - Errors
enum OCRError: LocalizedError {
    case invalidImage
    case noTextFound

    var errorDescription: String? {
        switch self {
        case .invalidImage: return "Could not process the image."
        case .noTextFound:  return "No text was detected in the image."
        }
    }
}
