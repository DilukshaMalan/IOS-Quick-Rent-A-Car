import SwiftUI

/// Sticky bottom bar: total price + "Continue to Driver's License" button.
struct BookingContinueBar: View {
    let total: Double
    let hint: String?
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        VStack(spacing: .spacingS) {
            if let hint {
                Label(hint, systemImage: "exclamationmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack {
                Text("Total")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(PriceCalculator.format(total))
                    .font(.title3.bold())
                    .foregroundStyle(Color.fallbackBlue)
            }

            Button(action: action) {
                Text("Continue to Driver's License")
                    .primaryButtonStyle()
            }
            .disabled(!isEnabled)
            .opacity(isEnabled ? 1 : 0.5)
        }
        .padding(.horizontal, .spacingL)
        .padding(.top, .spacingM)
        .padding(.bottom, .spacingS)
        .background(.regularMaterial)
    }
}

#Preview {
    BookingContinueBar(total: 420, hint: "Enter pickup and drop-off locations to continue.", isEnabled: false) {}
}
