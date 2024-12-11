import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                // User Profile Section
                Section {
                    HStack(spacing: 15) {
                        if let photoURL = viewModel.photoURL {
                            AsyncImage(url: photoURL) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 60, height: 60)
                                .foregroundColor(.gray)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(viewModel.displayName ?? "User")
                                .font(.headline)
                            Text(viewModel.email ?? "")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Preferences Section
                Section("Preferences") {
                    Toggle("Push Notifications", isOn: $viewModel.pushNotificationsEnabled)
                    Toggle("Severe Weather Alerts", isOn: $viewModel.severeWeatherAlertsEnabled)
                    
                    Picker("Temperature Unit", selection: $viewModel.temperatureUnit) {
                        Text("Fahrenheit").tag(TemperatureUnit.fahrenheit)
                        Text("Celsius").tag(TemperatureUnit.celsius)
                    }
                    
                    NavigationLink("Location Settings") {
                        LocationSettingsView()
                    }
                }
                
                // Account Section
                Section("Account") {
                    NavigationLink("Edit Profile") {
                        EditProfileView()
                    }
                    
                    NavigationLink("Change Password") {
                        ChangePasswordView()
                    }
                    
                    NavigationLink("Privacy Settings") {
                        PrivacySettingsView()
                    }
                }
                
                // Support Section
                Section("Support") {
                    Button(action: viewModel.contactSupport) {
                        Label("Contact Support", systemImage: "envelope")
                    }
                    
                    Button(action: viewModel.visitWebsite) {
                        Label("Visit Website", systemImage: "safari")
                    }
                    
                    NavigationLink("About NOAH") {
                        AboutView()
                    }
                }
                
                // Sign Out Section
                Section {
                    Button(role: .destructive, action: viewModel.signOut) {
                        Label("Sign Out", systemImage: "arrow.right.square")
                    }
                }
            }
            .navigationTitle("Profile")
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred")
            }
        }
    }
}

class ProfileViewModel: ObservableObject {
    @Published var displayName: String?
    @Published var email: String?
    @Published var photoURL: URL?
    @Published var pushNotificationsEnabled = true
    @Published var severeWeatherAlertsEnabled = true
    @Published var temperatureUnit = TemperatureUnit.fahrenheit
    @Published var showError = false
    @Published var errorMessage: String?
    
    private let authService = FirebaseAuthService.shared
    
    init() {
        loadUserProfile()
    }
    
    private func loadUserProfile() {
        if let user = Auth.auth().currentUser {
            displayName = user.displayName
            email = user.email
            if let photoURLString = user.photoURL?.absoluteString {
                photoURL = URL(string: photoURLString)
            }
        }
    }
    
    func signOut() {
        do {
            try authService.signOut()
        } catch {
            showError(message: "Failed to sign out")
        }
    }
    
    func contactSupport() {
        // TODO: Implement contact support
        if let url = URL(string: "mailto:support@noah-weather.com") {
            UIApplication.shared.open(url)
        }
    }
    
    func visitWebsite() {
        // TODO: Implement website visit
        if let url = URL(string: "https://noah-weather.com") {
            UIApplication.shared.open(url)
        }
    }
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}

enum TemperatureUnit: String, CaseIterable {
    case fahrenheit = "°F"
    case celsius = "°C"
}

// Placeholder Views
struct LocationSettingsView: View {
    var body: some View {
        Text("Location Settings")
            .navigationTitle("Location Settings")
    }
}

struct EditProfileView: View {
    var body: some View {
        Text("Edit Profile")
            .navigationTitle("Edit Profile")
    }
}

struct ChangePasswordView: View {
    var body: some View {
        Text("Change Password")
            .navigationTitle("Change Password")
    }
}

struct PrivacySettingsView: View {
    var body: some View {
        Text("Privacy Settings")
            .navigationTitle("Privacy Settings")
    }
}

struct AboutView: View {
    var body: some View {
        Text("About NOAH")
            .navigationTitle("About")
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
