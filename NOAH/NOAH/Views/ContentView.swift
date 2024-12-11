import SwiftUI

struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                if authViewModel.isAdmin {
                    AdminPortalView()
                } else {
                    MainTabView()
                }
            } else {
                AuthView()
            }
        }
        .preferredColorScheme(themeManager.selectedTheme.colorScheme)
        .onChange(of: authViewModel.isAuthenticated) { _, newValue in
            if !newValue {
                if let errorMessage = authViewModel.authError {
                    appState.logError(errorMessage)
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuthViewModel())
            .environmentObject(AppState())
            .environmentObject(ThemeManager())
    }
}
