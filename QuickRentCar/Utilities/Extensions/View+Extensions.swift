import SwiftUI

// MARK: - View Modifiers
extension View {
    /// Apply rounded card style with background and shadow
    func cardStyle(cornerRadius: CGFloat = 16, shadowRadius: CGFloat = 6) -> some View {
        self
            .background(Color.fallbackCardBg)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: .black.opacity(0.08), radius: shadowRadius, x: 0, y: 2)
    }

    /// Apply primary blue button style
    func primaryButtonStyle() -> some View {
        self
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(Color.fallbackBlue)
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    /// Apply secondary outline button style
    func secondaryButtonStyle() -> some View {
        self
            .font(.headline)
            .foregroundStyle(Color.fallbackBlue)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(Color.fallbackBlue.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.fallbackBlue, lineWidth: 1.5)
            )
    }

    /// Hide the keyboard
    func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil, from: nil, for: nil
        )
    }

    /// Conditionally apply a modifier
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Spacing Constants
extension CGFloat {
    static let spacingXS: CGFloat = 4
    static let spacingS: CGFloat = 8
    static let spacingM: CGFloat = 16
    static let spacingL: CGFloat = 24
    static let spacingXL: CGFloat = 32
    static let spacingXXL: CGFloat = 48

    static let cornerRadiusS: CGFloat = 8
    static let cornerRadiusM: CGFloat = 16
    static let cornerRadiusL: CGFloat = 24
}
