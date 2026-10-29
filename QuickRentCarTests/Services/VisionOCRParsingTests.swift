import XCTest
import UIKit
@testable import QuickRentCar

final class VisionOCRParsingTests: XCTestCase {

    func testOCRError_localizedDescriptions_areUserFriendly() {
        let invalidImageError = OCRError.invalidImage
        let noTextError = OCRError.noTextFound

        XCTAssertEqual(invalidImageError.errorDescription, "Could not process the image.")
        XCTAssertEqual(noTextError.errorDescription, "No text was detected. Use good light and keep the whole license in the picture.")
    }

    func testExtractLicenseInfo_withEmptyBlankImage_throwsInvalidImageError() async {
        let blankImage = UIImage() // has no underlying CGImage

        do {
            _ = try await VisionOCRService.shared.extractLicenseInfo(from: blankImage)
            XCTFail("Expected extractLicenseInfo to throw OCRError.invalidImage")
        } catch let error as OCRError {
            XCTAssertEqual(error, OCRError.invalidImage)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testExtractExpiryDate_withInvalidImage_throwsInvalidImageError() async {
        let blankImage = UIImage()

        do {
            _ = try await VisionOCRService.shared.extractExpiryDate(from: blankImage)
            XCTFail("Expected extractExpiryDate to throw OCRError.invalidImage")
        } catch let error as OCRError {
            XCTAssertEqual(error, OCRError.invalidImage)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
}
