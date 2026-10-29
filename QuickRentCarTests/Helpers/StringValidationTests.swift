import XCTest
@testable import QuickRentCar

final class StringValidationTests: XCTestCase {

    func testIsValidEmail_withStandardValidEmail_returnsTrue() {
        let validEmails = [
            "user@example.com",
            "firstname.lastname@domain.co",
            "support+help@quickrentcar.com",
            "customer123@sub.domain.org"
        ]

        for email in validEmails {
            XCTAssertTrue(email.isValidEmail, "Expected \(email) to be valid")
        }
    }

    func testIsValidEmail_withInvalidEmails_returnsFalse() {
        let invalidEmails = [
            "",
            "plainaddress",
            "@missinguser.com",
            "user@.com",
            "user@domain",
            "user name@domain.com",
            "user@domain..com"
        ]

        for email in invalidEmails {
            XCTAssertFalse(email.isValidEmail, "Expected \(email) to be invalid")
        }
    }

    func testIsValidPassword_withEightOrMoreCharacters_returnsTrue() {
        XCTAssertTrue("12345678".isValidPassword)
        XCTAssertTrue("StrongP@ssw0rd!".isValidPassword)
    }

    func testIsValidPassword_withLessThanEightCharacters_returnsFalse() {
        XCTAssertFalse("1234567".isValidPassword)
        XCTAssertFalse("abc".isValidPassword)
        XCTAssertFalse("".isValidPassword)
    }

    func testIsValidPhoneNumber_withTenOrMoreDigits_returnsTrue() {
        XCTAssertTrue("0771234567".isValidPhoneNumber)
        XCTAssertTrue("+94 77 123 4567".isValidPhoneNumber)
        XCTAssertTrue("(011) 234-5678".isValidPhoneNumber)
    }

    func testIsValidPhoneNumber_withLessThanTenDigits_returnsFalse() {
        XCTAssertFalse("123456789".isValidPhoneNumber)
        XCTAssertFalse("phone".isValidPhoneNumber)
        XCTAssertFalse("".isValidPhoneNumber)
    }

    func testTrimmed_removesSurroundingWhitespaceAndNewlines() {
        let original = "  \n  Quick Rent Car \t \n"
        XCTAssertEqual(original.trimmed, "Quick Rent Car")
    }

    func testIsNotEmpty_withWhitespaceOnly_returnsFalse() {
        XCTAssertFalse("   ".isNotEmpty)
        XCTAssertFalse("\n\t  \n".isNotEmpty)
        XCTAssertFalse("".isNotEmpty)
        XCTAssertTrue("A".isNotEmpty)
        XCTAssertTrue(" Colombo ".isNotEmpty)
    }
}
