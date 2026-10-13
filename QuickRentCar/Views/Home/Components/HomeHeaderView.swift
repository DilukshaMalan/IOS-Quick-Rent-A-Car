import SwiftUI

// MARK: - Greeting Header (Change 1)
struct HomeHeaderView: View {
    let userName: String

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default:      return "Good night"
        }
    }

    private var greetingIcon: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return "sun.rise.fill"
        case 12..<17: return "sun.max.fill"
        case 17..<21: return "sunset.fill"
        default:      return "moon.stars.fill"
        }
    }

    var body: some View {
        HStack(alignment: .center) {
            // Left — greeting text
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: greetingIcon)
                        .foregroundStyle(.orange)
                        .font(.subheadline)
                    Text(greeting + ", \(userName) 👋")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Text("Find your perfect ride")
                    .font(.title2.bold())
                    .foregroundStyle(Color.fallbackNavy)
            }

            Spacer()

            // Right — notification bell
            NavigationLink(destination: Text("Notifications").padding()) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell.fill")
                        .font(.title3)
                        .foregroundStyle(Color.fallbackNavy)
                        .frame(width: 42, height: 42)
                        .background(Color.gray.opacity(0.08))
                        .clipShape(Circle())

                    // Red dot badge
                    Circle()
                        .fill(.red)
                        .frame(width: 9, height: 9)
                        .offset(x: 1, y: -1)
                }
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    HomeHeaderView(userName: "Diluksha")
        .padding()
}
