import SwiftUI

/// Sticky bottom bar: tap-to-expand price details, total, and the
/// "Continue to Driver's License" button.
struct BookingContinueBar: View {
    let dailyRate: Double
    let days: Int
    let subtotal: Double
    let tax: Double
    let total: Double
    var includedMileage: Int? = nil
    let hint: String?
    let isEnabled: Bool
    var isLoading = false
    let action: () -> Void

    @State private var showsBreakdown = false

    var body: some View {
        VStack(spacing: .spacingS) {
            if let hint {
                Label(hint, systemImage: "exclamationmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if showsBreakdown {
                PriceSummaryView(
                    dailyRate: dailyRate,
                    days: days,
                    subtotal: subtotal,
                    tax: tax,
                    includedMileage: includedMileage
                )
                .padding(.vertical, .spacingS)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            // Total row — tap to show / hide the breakdown
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { showsBreakdown.toggle() }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Total")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 4) {
                            Text("Price details")
                                .font(.caption.weight(.semibold))
                            Image(systemName: "chevron.up")
                                .font(.caption2.weight(.bold))
                                .rotationEffect(.degrees(showsBreakdown ? 180 : 0))
                        }
                        .foregroundStyle(Color.fallbackBlue)
                    }

                    Spacer()

                    Text(PriceCalculator.format(total))
                        .font(.title3.bold())
                        .foregroundStyle(Color.fallbackBlue)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("Shows the price breakdown")

            Button(action: action) {
                Group {
                    if isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("Continue to Driver's License")
                    }
                }
                .primaryButtonStyle()
            }
            .disabled(!isEnabled || isLoading)
            .opacity(isEnabled ? 1 : 0.5)

            Text("Next: driver's license check")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, .spacingL)
        .padding(.top, .spacingM)
        .padding(.bottom, .spacingS)
        .background(.regularMaterial)
    }
}

#Preview {
    BookingContinueBar(
        dailyRate: 140, days: 3, subtotal: 420, tax: 42, total: 462,
        includedMileage: 200,
        hint: nil,
        isEnabled: true
    ) {}
}
