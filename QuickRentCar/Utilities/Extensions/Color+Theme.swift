import SwiftUI

// MARK: - Brand Colors
extension Color {
    /// Primary brand blue — used for CTAs, icons, highlights
    static let appBlue = Color("AppBlue")

    /// Lighter shade of brand blue for backgrounds, cards
    static let appBlueLighter = Color("AppBlueLighter")

    /// Deep navy for text on white backgrounds
    static let appNavy = Color("AppNavy")

    /// Card background (light gray/white)
    static let cardBackground = Color("CardBackground")

    /// Primary text
    static let textPrimary = Color("TextPrimary")

    /// Secondary/subtitle text
    static let textSecondary = Color("TextSecondary")

    /// Destructive / error red
    static let appRed = Color.red

    /// Success green
    static let appGreen = Color.green

    // MARK: - Fallback values (used before asset catalog)
    static let fallbackBlue = Color(red: 0.0, green: 0.478, blue: 1.0)
    static let fallbackNavy = Color(red: 0.05, green: 0.12, blue: 0.28)
    static let fallbackCardBg = Color(UIColor.systemBackground)
}

// MARK: - Gradient Helpers
extension LinearGradient {
    static let appBlueFade = LinearGradient(
        colors: [Color.fallbackBlue, Color.fallbackBlue.opacity(0.7)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let heroGradient = LinearGradient(
        colors: [Color.fallbackNavy.opacity(0.7), Color.clear],
        startPoint: .bottom,
        endPoint: .top
    )
}
