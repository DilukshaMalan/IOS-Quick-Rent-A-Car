import XCTest
@testable import QuickRentCar

final class LicenseInfoTests: XCTestCase {

    func testIsExpired_withPastExpiryDate_returnsTrue() {
        let yesterday = Date().adding(days: -1)
        let license = LicenseInfo(
            fullName: "John Doe",
            licenseNumber: "B1234567",
            expiryDate: yesterday
        )

        XCTAssertTrue(license.isExpired, "License with yesterday's expiry should be expired")
    }

    func testIsExpired_withFutureExpiryDate_returnsFalse() {
        let nextYear = Date().adding(days: 365)
        let license = LicenseInfo(
            fullName: "John Doe",
            licenseNumber: "B1234567",
            expiryDate: nextYear
        )

        XCTAssertFalse(license.isExpired, "License expiring in the future should not be expired")
    }

    func testIsExpired_withNilExpiryDate_returnsFalse() {
        let license = LicenseInfo(
            fullName: "John Doe",
            licenseNumber: "B1234567",
            expiryDate: nil
        )

        XCTAssertFalse(license.isExpired, "License without expiry date should not report as expired")
    }

    func testFormattedDates_whenNil_returnsEmptyString() {
        let license = LicenseInfo(dateOfBirth: nil, expiryDate: nil)

        XCTAssertEqual(license.formattedDateOfBirth, "")
        XCTAssertEqual(license.formattedExpiryDate, "")
    }

    func testFormattedDates_whenPresent_returnsFormattedString() {
        let calendar = Calendar(identifier: .gregorian)
        var dobComps = DateComponents()
        dobComps.year = 1995; dobComps.month = 5; dobComps.day = 15
        let dob = calendar.date(from: dobComps)!

        let license = LicenseInfo(dateOfBirth: dob)

        XCTAssertFalse(license.formattedDateOfBirth.isEmpty)
        XCTAssertTrue(license.formattedDateOfBirth.contains("1995"))
    }
}
