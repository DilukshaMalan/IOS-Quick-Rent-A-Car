import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab: Tab = .home
    /// True when the app is locked and waiting for Face ID/Touch ID
    @State private var isLocked = false

    enum Tab: Int {
        case home, bookings, ar, stats, profile
    }

    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                mainTabView
                    // Show the lock screen as a full-screen overlay
                    .overlay {
                        if isLocked {
                            AppLockView {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isLocked = false
                                }
                            }
                            .transition(.opacity)
                        }
                    }
            } else {
                NavigationStack {
                    LoginView()
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authViewModel.isAuthenticated)
        .animation(.easeInOut(duration: 0.25), value: isLocked)
        // Lock the app whenever it goes to the background (if Face ID is enabled)
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .background:
                // Only lock when user is logged in AND Face ID feature is on
                if authViewModel.isAuthenticated && BiometricAuthService.shared.isFaceIDEnabled {
                    isLocked = true
                }
            case .active:
                break   // AppLockView handles the prompt automatically on appear
            default:
                break
            }
        }
        // Also lock on first launch if session exists and Face ID is enabled
        .task {
            if authViewModel.isAuthenticated && BiometricAuthService.shared.isFaceIDEnabled {
                isLocked = true
            }
        }
        // Reset lock when user signs out
        .onChange(of: authViewModel.isAuthenticated) { _, authenticated in
            if !authenticated { isLocked = false }
        }
    }

    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(Tab.home)

            BookingHistoryView()
                .tabItem { Label("Bookings", systemImage: "calendar.badge.clock") }
                .tag(Tab.bookings)

            ARPreviewView()
                .tabItem { Label("AR", systemImage: "arkit") }
                .tag(Tab.ar)

            VehicleStatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar.fill") }
                .tag(Tab.stats)

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.circle.fill") }
                .tag(Tab.profile)
        }
        .tint(.appBlue)
        .onReceive(NotificationCenter.default.publisher(for: .navigateToHome)) { _ in
            selectedTab = .home
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
}
