import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @StateObject private var viewModel = EditProfileViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Form {
            Section {
                // Profile Photo
                HStack {
                    Spacer()
                    PhotosPicker(selection: $viewModel.selectedPhoto) {
                        VStack {
                            if let image = viewModel.profileImage {
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.blue, lineWidth: 2))
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .frame(width: 100, height: 100)
                                    .foregroundColor(.gray)
                            }
                            
                            Text("Change Photo")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    Spacer()
                }
                .padding(.vertical)
                
                // Profile Information
                TextField("Display Name", text: $viewModel.displayName)
                    .textContentType(.name)
                
                TextField("Email", text: $viewModel.email)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .disabled(true)
                
                TextField("Phone Number", text: $viewModel.phoneNumber)
                    .textContentType(.telephoneNumber)
                    .keyboardType(.phonePad)
            }
            
            Section(header: Text("Notification Preferences")) {
                Toggle("Daily Weather Updates", isOn: $viewModel.dailyUpdates)
                Toggle("Severe Weather Alerts", isOn: $viewModel.severeWeatherAlerts)
                Toggle("Rain Alerts", isOn: $viewModel.rainAlerts)
            }
            
            Section(header: Text("Account")) {
                NavigationLink("Change Password") {
                    ChangePasswordView()
                }
                
                NavigationLink("Privacy Settings") {
                    PrivacySettingsView()
                }
                
                Button(role: .destructive, action: viewModel.deleteAccount) {
                    Text("Delete Account")
                }
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarItems(trailing: Button("Save") {
            Task {
                if await viewModel.saveChanges() {
                    dismiss()
                }
            }
        })
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
        .alert("Delete Account", isPresented: $viewModel.showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.confirmDeleteAccount()
                }
            }
        } message: {
            Text("Are you sure you want to delete your account? This action cannot be undone.")
        }
    }
}

@MainActor
class EditProfileViewModel: ObservableObject {
    @Published var selectedPhoto: PhotosPickerItem? {
        didSet {
            Task {
                await loadImage()
            }
        }
    }
    @Published var profileImage: Image?
    @Published var displayName = ""
    @Published var email = ""
    @Published var phoneNumber = ""
    @Published var dailyUpdates = true
    @Published var severeWeatherAlerts = true
    @Published var rainAlerts = false
    @Published var showError = false
    @Published var errorMessage: String?
    @Published var showDeleteConfirmation = false
    
    private let authService = FirebaseAuthService.shared
    
    init() {
        loadUserProfile()
    }
    
    private func loadUserProfile() {
        if let user = authService.user {
            displayName = user.displayName ?? ""
            email = user.email ?? ""
            // TODO: Load other user preferences from UserDefaults or Firestore
        }
    }
    
    private func loadImage() async {
        guard let selectedPhoto else { return }
        
        do {
            if let data = try await selectedPhoto.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                profileImage = Image(uiImage: uiImage)
            }
        } catch {
            showError(message: "Failed to load image")
        }
    }
    
    func saveChanges() async -> Bool {
        guard !displayName.isEmpty else {
            showError(message: "Please enter a display name")
            return false
        }
        
        do {
            // Update display name
            if let user = authService.user {
                let changeRequest = user.createProfileChangeRequest()
                changeRequest.displayName = displayName
                try await changeRequest.commitChanges()
            }
            
            // TODO: Save other preferences to UserDefaults or Firestore
            
            return true
        } catch {
            showError(message: "Failed to save changes")
            return false
        }
    }
    
    func deleteAccount() {
        showDeleteConfirmation = true
    }
    
    func confirmDeleteAccount() async {
        do {
            // TODO: Implement account deletion
            try await authService.user?.delete()
        } catch {
            showError(message: "Failed to delete account")
        }
    }
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}

struct EditProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            EditProfileView()
        }
    }
}
