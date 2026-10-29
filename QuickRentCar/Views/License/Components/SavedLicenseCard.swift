import SwiftUI

struct SavedLicenseCard: View {
    let maskedNumber: String
    let expiry: Date

    var body: some View {
        VStack(spacing: .spacingM) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 30))
                .foregroundStyle(Color.scanAccent)
                .frame(width: 64, height: 64)
                .background(Color.scanIconBg)
                .clipShape(Circle())

            Text("Using your saved license")
                .font(.title2.bold())
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            VStack(spacing: 4) {
                Text(maskedNumber)
                    .font(.headline.monospaced())
                    .foregroundStyle(.white)
                Text("Valid until \(expiry.displayDate)")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }

            Text("No need to scan again. Scan a different license if someone else will be driving.")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.top, .spacingXS)
        }
        .padding(.spacingL)
        .frame(maxWidth: .infinity)
        .background(Color.scanCard)
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(Color.scanBorder, lineWidth: 1)
        )
    }
}

#Preview {
    SavedLicenseCard(maskedNumber: "•••• 4821", expiry: Date().adding(days: 900))
        .padding()
        .background(Color.scanBackground)
}
