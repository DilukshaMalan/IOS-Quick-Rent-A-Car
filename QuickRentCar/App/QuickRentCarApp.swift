import SwiftUI
import FirebaseCore

@main
struct QuickRentCarApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authViewModel = AuthViewModel()

    @AppStorage("appColorScheme") private var appColorScheme: String = ""

    private var preferredColorScheme: ColorScheme? {
        switch appColorScheme {
        case "dark":  return .dark
        case "light": return .light
        default:      return nil
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
