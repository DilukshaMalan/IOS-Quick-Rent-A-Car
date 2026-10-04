import SwiftUI

struct OnboardingView: View {
    @AppStorage(Constants.UserDefaultsKeys.hasCompletedOnboarding) var hasCompletedOnboarding = false
    @State private var currentPage = 0

    let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Find Your Ride",
            subtitle: "Browse hundreds of vehicles. Filter by type, price and location to find your perfect match.",
            icon: "car.2.fill",
            color: Color.fallbackBlue
        ),
        OnboardingPage(
            title: "Easy Booking",
            subtitle: "Select dates, review pricing, and confirm your booking in just a few taps.",
            icon: "calendar.badge.checkmark",
            color: Color.fallbackNavy
        ),
        OnboardingPage(
            title: "Smart Pickup",
            subtitle: "MapKit guides you to your vehicle. Geofencing confirms when you arrive at the pickup zone.",
            icon: "location.fill",
            color: Color(red: 0.0, green: 0.7, blue: 0.5)
        ),
        OnboardingPage(
            title: "AR Preview",
            subtitle: "See your vehicle in your real environment before booking with Augmented Reality.",
            icon: "arkit",
            color: Color(red: 0.6, green: 0.2, blue: 0.9)
        ),
        OnboardingPage(
            title: "Stay Informed",
            subtitle: "Push notifications and a Home Screen widget keep you updated on your active rental.",
            icon: "bell.badge.fill",
            color: Color(red: 1.0, green: 0.5, blue: 0.0)
        )
    ]

    var body: some View {
        VStack {
            // MARK: - Page Content
            TabView(selection: $currentPage) {
                ForEach(pages.indices, id: \.self) { index in
                    OnboardingPageView(page: pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // MARK: - Page Dots
            HStack(spacing: 8) {
                ForEach(pages.indices, id: \.self) { index in
                    Capsule()
                        .fill(currentPage == index ? Color.fallbackBlue : Color.gray.opacity(0.3))
                        .frame(width: currentPage == index ? 24 : 8, height: 8)
                        .animation(.spring(response: 0.4), value: currentPage)
                }
            }
            .padding(.bottom, .spacingL)

            // MARK: - CTA Button
            Button {
                if currentPage < pages.count - 1 {
                    withAnimation { currentPage += 1 }
                } else {
                    hasCompletedOnboarding = true
                }
            } label: {
                Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                    .primaryButtonStyle()
            }
            .padding(.horizontal, .spacingL)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Page Model
struct OnboardingPage {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
}

// MARK: - Page View
struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: .spacingL) {
            Spacer()

            ZStack {
                Circle()
                    .fill(page.color.opacity(0.12))
                    .frame(width: 160, height: 160)

                Image(systemName: page.icon)
                    .font(.system(size: 64))
                    .foregroundStyle(page.color)
            }

            VStack(spacing: .spacingS) {
                Text(page.title)
                    .font(.title.bold())
                    .foregroundStyle(Color.fallbackNavy)
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, .spacingXL)
            }

            Spacer()
        }
    }
}

// MARK: - Forgot Password
struct ForgotPasswordView: View {
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var sent = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: .spacingL) {
                Text("Enter your email address and we'll send you a link to reset your password.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top)

                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color.gray.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusS))

                if let error = errorMessage {
                    Text(error).foregroundStyle(.red).font(.caption)
                }

                if sent {
                    Label("Reset email sent!", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }

                Button("Send Reset Link") {
                    Task {
                        do {
                            try await AuthService.shared.resetPassword(email: email)
                            sent = true
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                    }
                }
                .primaryButtonStyle()

                Spacer()
            }
            .padding(.horizontal, .spacingL)
            .navigationTitle("Reset Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

#Preview { OnboardingView() }
