import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab: Tab = .home
    @State private var isLocked = false

    enum Tab: Int {
        case home, bookings, stats, profile
    }

    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                mainTabView
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
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .background:
                if authViewModel.isAuthenticated && BiometricAuthService.shared.isFaceIDEnabled {
                    isLocked = true
                }
            case .active:
                break
            default:
                break
            }
        }
        .task {
            if authViewModel.isAuthenticated && BiometricAuthService.shared.isFaceIDEnabled {
                isLocked = true
            }
        }
        .onChange(of: authViewModel.isAuthenticated) { _, authenticated in
            if !authenticated { isLocked = false }
        }
    }

    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(Tab.home)

            BookingsTabView()
                .tabItem { Label("Bookings", systemImage: "calendar.badge.clock") }
                .tag(Tab.bookings)

            VehicleStatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar.fill") }
                .tag(Tab.stats)

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.circle.fill") }
                .tag(Tab.profile)
        }
        .tint(.appBlue)
        .adaptiveTabStyle()
        .onReceive(NotificationCenter.default.publisher(for: .navigateToHome)) { _ in
            selectedTab = .home
        }
    }
}

private extension View {
    @ViewBuilder
    func adaptiveTabStyle() -> some View {
        if #available(iOS 18.0, *) {
            self.tabViewStyle(.sidebarAdaptable)
        } else {
            self
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
}
