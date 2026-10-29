import XCTest
@testable import QuickRentCar

final class PriceCalculatorTests: XCTestCase {

    func testTotalPrice_multiDayRental_calculatesCorrectSubtotal() {
        let pickup = Date()
        let returnDate = pickup.adding(days: 3)
        let dailyRate: Double = 65.0

        let total = PriceCalculator.totalPrice(dailyRate: dailyRate, pickupDate: pickup, returnDate: returnDate)

        XCTAssertEqual(total, 195.0, accuracy: 0.001, "3 days at $65.00/day should equal $195.00")
    }

    func testTotalPrice_sameDayRental_enforcesMinimumOneDay() {
        let pickup = Date()
        let returnDate = pickup // same day
        let dailyRate: Double = 80.0

        let total = PriceCalculator.totalPrice(dailyRate: dailyRate, pickupDate: pickup, returnDate: returnDate)

        XCTAssertEqual(total, 80.0, accuracy: 0.001, "Same-day rentals must be charged for at least 1 day")
    }

    func testTaxAmount_calculatesTenPercent() {
        let subtotal: Double = 500.0

        let tax = PriceCalculator.taxAmount(subtotal: subtotal)

        let expectedTax = subtotal * Constants.Pricing.taxRate
        XCTAssertEqual(tax, expectedTax, accuracy: 0.001, "Tax should equal subtotal * taxRate (10%)")
        XCTAssertEqual(tax, 50.0, accuracy: 0.001)
    }

    func testTotalWithTax_addsTenPercentToSubtotal() {
        let pickup = Date()
        let returnDate = pickup.adding(days: 2)
        let dailyRate: Double = 100.0

        let totalWithTax = PriceCalculator.totalWithTax(dailyRate: dailyRate, pickupDate: pickup, returnDate: returnDate)

        // Subtotal = 200.0, Tax = 20.0, Total = 220.0
        XCTAssertEqual(totalWithTax, 220.0, accuracy: 0.001, "Total with 10% tax on 2 days @ 100.0 should be 220.0")
    }

    func testRentalDays_calculatesDayDifference() {
        let pickup = Date()
        let returnDate = pickup.adding(days: 7)

        let days = PriceCalculator.rentalDays(from: pickup, to: returnDate)

        XCTAssertEqual(days, 7, "Rental period from pickup to +7 days should return 7 days")
    }

    func testFormat_formatsCurrencyStringWithLKR() {
        let amount: Double = 12500.50

        let formatted = PriceCalculator.format(amount)

        let expected = "\(Constants.Pricing.currency) 12500.50"
        XCTAssertEqual(formatted, expected, "Currency formatting should match '<Currency> <Amount.2f>'")
    }
}
