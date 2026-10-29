import SwiftUI

extension Color {
    static let appBlue = Color("AppBlue")

    static let appBlueLighter = Color("AppBlueLighter")

    static let appNavy = Color("AppNavy")

    static let cardBackground = Color("CardBackground")

    static let textPrimary = Color("TextPrimary")

    static let textSecondary = Color("TextSecondary")

    static let appRed = Color.red

    static let appGreen = Color.green

    static let fallbackBlue = Color(red: 0.0, green: 0.478, blue: 1.0)
    static let fallbackNavy = Color(red: 0.05, green: 0.12, blue: 0.28)
    static let fallbackCardBg = Color(UIColor.systemBackground)
}

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
