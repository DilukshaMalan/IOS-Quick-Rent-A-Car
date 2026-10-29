import XCTest
@testable import QuickRentCar

final class UserModelTests: XCTestCase {

    func testFirstName_withTwoWordFullName_extractsFirstWord() {
        let user = User(
            email: "kasun@example.com",
            fullName: "Kasun Perera"
        )
        XCTAssertEqual(user.firstName, "Kasun")
    }

    func testFirstName_withSingleWordName_returnsWholeName() {
        let user = User(
            email: "single@example.com",
            fullName: "Madonna"
        )
        XCTAssertEqual(user.firstName, "Madonna")
    }

    func testPaymentRecordFormattedAmount_formatsWithCurrency() {
        let record = PaymentRecord(
            userId: "u-1",
            bookingId: "b-1",
            vehicleName: "Toyota Camry",
            amount: 45000.50,
            currency: "LKR",
            status: .completed,
            paymentMethod: "Credit Card",
            transactionDate: Date(),
            invoiceNumber: "INV-001"
        )

        XCTAssertEqual(record.formattedAmount, "LKR 45000.50")
    }

    func testPaymentRecordFormattedDate_producesReadableString() {
        let record = PaymentRecord(
            userId: "u-1",
            bookingId: "b-1",
            vehicleName: "Toyota Camry",
            amount: 100.0,
            currency: "LKR",
            status: .completed,
            paymentMethod: "Card",
            transactionDate: Date(),
            invoiceNumber: "INV-002"
        )

        XCTAssertFalse(record.formattedDate.isEmpty)
    }
}
