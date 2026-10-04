import SwiftUI
import FirebaseCore

@main
struct QuickRentCarApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
        }
    }
}
