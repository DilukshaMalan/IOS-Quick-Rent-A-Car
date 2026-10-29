import SwiftUI

struct BookingStepIndicator: View {
    let step: Int
    let total: Int
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            HStack(spacing: 4) {
                ForEach(1...total, id: \.self) { index in
                    Capsule()
                        .fill(index <= step ? Color.fallbackBlue : Color.gray.opacity(0.25))
                        .frame(height: 4)
                }
            }

            Text("Step \(step) of \(total) · \(title)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    BookingStepIndicator(step: 1, total: 2, title: "Trip details")
        .padding()
}
