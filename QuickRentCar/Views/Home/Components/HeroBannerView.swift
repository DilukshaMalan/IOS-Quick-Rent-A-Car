import SwiftUI

// MARK: - Hero Banner (Figma-style)
struct HeroBannerView: View {
    var body: some View {
        ZStack(alignment: .bottomLeading) {

            // Background image
            Image("hero_banner")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity)
                .frame(height: 210)
                .clipped()

            // Dark gradient scrim from bottom-left
            LinearGradient(
                colors: [
                    Color.fallbackNavy.opacity(0.80),
                    Color.fallbackNavy.opacity(0.45),
                    Color.clear
                ],
                startPoint: .bottomLeading,
                endPoint: .topTrailing
            )

            // Text overlay (bottom-left, like Figma)
            VStack(alignment: .leading, spacing: 5) {
                Text("Premium Cars\nfor Every Journey")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    ForEach(["Rent", "Drive", "Explore"], id: \.self) { word in
                        Text(word)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.85))
                        if word != "Explore" {
                            Text("•")
                                .font(.system(size: 10))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }
                }
            }
            .padding(.horizontal, .spacingM)
            .padding(.bottom, .spacingL)
        }
        .frame(height: 210)
        .clipShape(Rectangle())     // no rounding on hero — full bleed
    }
}

#Preview {
    HeroBannerView()
}
