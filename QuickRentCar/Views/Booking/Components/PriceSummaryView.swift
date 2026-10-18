import SwiftUI

/// Price breakdown (rate × days, tax, included mileage). Flat — it sits inside the sticky bar,
/// which already shows the total.
struct PriceSummaryView: View {
    let dailyRate: Double
    let days: Int
    let subtotal: Double
    let tax: Double
    var includedMileage: Int? = nil

    var body: some View {
        VStack(spacing: .spacingS) {
            PriceRow(
                label: "\(PriceCalculator.format(dailyRate)) × \(days) day\(days == 1 ? "" : "s")",
                value: PriceCalculator.format(subtotal)
            )
            PriceRow(label: "Tax (\(Int(Constants.Pricing.taxRate * 100))%)", value: PriceCalculator.format(tax))

            if let includedMileage {
                Label("Includes \(includedMileage) km per day", systemImage: "speedometer")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
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
