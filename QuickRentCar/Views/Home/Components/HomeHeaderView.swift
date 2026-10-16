import SwiftUI

// MARK: - Top Navigation Bar  (Figma-style)
struct HomeTopBarView: View {
    let userName: String

    var body: some View {
        HStack(alignment: .center) {
            // Left: logo + title stack
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.fallbackBlue)
                        .frame(width: 36, height: 36)
                    Image(systemName: "car.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text("QuickRentCar")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Color.fallbackNavy)
                    Text("Drive Your Next Adventure")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Right: notification bell
            NavigationLink(destination: Text("Notifications").padding()) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.fallbackNavy)
                        .frame(width: 40, height: 40)
                        .background(Color.gray.opacity(0.09))
                        .clipShape(Circle())

                    Circle()
                        .fill(.red)
                        .frame(width: 9, height: 9)
                        .offset(x: 1, y: 0)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, .spacingM)
        .padding(.top, .spacingS)
        .padding(.bottom, 4)
    }
}

#Preview {
    HomeTopBarView(userName: "Diluksha")
        .padding(.vertical)
}
