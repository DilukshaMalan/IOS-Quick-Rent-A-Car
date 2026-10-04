import Foundation

struct PriceCalculator {
    /// Calculates total rental price
    static func totalPrice(dailyRate: Double, pickupDate: Date, returnDate: Date) -> Double {
        let days = pickupDate.days(to: returnDate)
        return dailyRate * Double(days)
    }

    /// Total price with tax
    static func totalWithTax(dailyRate: Double, pickupDate: Date, returnDate: Date) -> Double {
        let subtotal = totalPrice(dailyRate: dailyRate, pickupDate: pickupDate, returnDate: returnDate)
        return subtotal * (1 + Constants.Pricing.taxRate)
    }

    /// Tax amount only
    static func taxAmount(subtotal: Double) -> Double {
        subtotal * Constants.Pricing.taxRate
    }

    /// Number of rental days (minimum 1)
    static func rentalDays(from pickupDate: Date, to returnDate: Date) -> Int {
        pickupDate.days(to: returnDate)
    }

    /// Format as currency string
    static func format(_ amount: Double) -> String {
        String(format: "%@ %.2f", Constants.Pricing.currency, amount)
    }
}
