import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedTab: Tab = .home

    enum Tab: Int {
        case home, bookings, ar, stats, profile
    }

    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                mainTabView
            } else {
                NavigationStack {
                    LoginView()
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authViewModel.isAuthenticated)
    }

    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(Tab.home)

            BookingHistoryView()
                .tabItem {
                    Label("Bookings", systemImage: "calendar.badge.clock")
                }
                .tag(Tab.bookings)

            ARPreviewView()
                .tabItem {
                    Label("AR", systemImage: "arkit")
                }
                .tag(Tab.ar)

            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }
                .tag(Tab.stats)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle.fill")
                }
                .tag(Tab.profile)
        }
        .tint(.appBlue)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
}
