import SwiftUI

struct PriceSummaryView: View {
    let dailyRate: Double
    let days: Int
    let subtotal: Double
    let tax: Double
    let total: Double

    var body: some View {
        VStack(spacing: .spacingS) {
            PriceRow(
                label: "\(PriceCalculator.format(dailyRate)) × \(days) day\(days == 1 ? "" : "s")",
                value: PriceCalculator.format(subtotal)
            )
            PriceRow(label: "Tax (\(Int(Constants.Pricing.taxRate * 100))%)", value: PriceCalculator.format(tax))
            Divider()
            PriceRow(label: "Total", value: PriceCalculator.format(total), isTotal: true)
        }
        .padding()
        .cardStyle()
    }
}

struct PriceRow: View {
    let label: String
    let value: String
    var isTotal = false

    var body: some View {
        HStack {
            Text(label)
                .font(isTotal ? .headline : .subheadline)
                .foregroundStyle(isTotal ? Color.fallbackNavy : .secondary)
            Spacer()
            Text(value)
                .font(isTotal ? .title3.bold() : .subheadline)
                .foregroundStyle(isTotal ? Color.fallbackBlue : .primary)
        }
    }
}
