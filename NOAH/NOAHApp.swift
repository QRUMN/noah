import SwiftUI
import FirebaseCore

@main
struct NOAHApp: App {
    @StateObject private var themeManager = ThemeManager.shared
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(themeManager.selectedTheme.colorScheme)
        }
    }
}

struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                if authViewModel.isAdmin {
                    AdminPortalView()
                } else {
                    MainTabView()
                }
            } else {
                AuthenticationView()
            }
        }
    }
}
