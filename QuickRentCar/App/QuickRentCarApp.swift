import SwiftUI
import FirebaseCore

@main
struct QuickRentCarApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authViewModel = AuthViewModel()

    /// Persisted dark-mode preference. Empty string = follow system.
    @AppStorage("appColorScheme") private var appColorScheme: String = ""

    /// Maps the stored string to a SwiftUI `ColorScheme?`.
    private var preferredColorScheme: ColorScheme? {
        switch appColorScheme {
        case "dark":  return .dark
        case "light": return .light
        default:      return nil     // follow system
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .preferredColorScheme(preferredColorScheme)
        }
    }
}
