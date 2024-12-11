import SwiftUI
import FirebaseAuth

struct ChangePasswordView: View {
    @StateObject private var viewModel = ChangePasswordViewModel()
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Form {
            Section {
                SecureField("Current Password", text: $viewModel.currentPassword)
                    .textContentType(.password)
                
                SecureField("New Password", text: $viewModel.newPassword)
                    .textContentType(.newPassword)
                
                SecureField("Confirm New Password", text: $viewModel.confirmPassword)
                    .textContentType(.newPassword)
            } footer: {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Password must:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    PasswordRequirementRow(
                        isValid: viewModel.hasMinimumLength,
                        text: "Be at least 8 characters long"
                    )
                    
                    PasswordRequirementRow(
                        isValid: viewModel.hasUppercase,
                        text: "Contain at least one uppercase letter"
                    )
                    
                    PasswordRequirementRow(
                        isValid: viewModel.hasLowercase,
                        text: "Contain at least one lowercase letter"
                    )
                    
                    PasswordRequirementRow(
                        isValid: viewModel.hasNumber,
                        text: "Contain at least one number"
                    )
                    
                    PasswordRequirementRow(
                        isValid: viewModel.hasSpecialCharacter,
                        text: "Contain at least one special character"
                    )
                }
                .padding(.vertical, 8)
            }
            
            Section {
                Button(action: {
                    Task {
                        if await viewModel.changePassword() {
                            appState.logMessage("Password changed successfully")
                            dismiss()
                        }
                    }
                }) {
                    HStack {
                        Text("Change Password")
                        Spacer()
                        if viewModel.isLoading {
                            ProgressView()
                        }
                    }
                }
                .disabled(!viewModel.isValid || viewModel.isLoading)
            }
        }
        .navigationTitle("Change Password")
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
    }
}

struct PasswordRequirementRow: View {
    let isValid: Bool
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isValid ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isValid ? .green : .secondary)
                .font(.caption)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

@MainActor
class ChangePasswordViewModel: ObservableObject {
    @Published var currentPassword = ""
    @Published var newPassword = ""
    @Published var confirmPassword = ""
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage: String?
    
    var hasMinimumLength: Bool {
        newPassword.count >= 8
    }
    
    var hasUppercase: Bool {
        newPassword.contains { $0.isUppercase }
    }
    
    var hasLowercase: Bool {
        newPassword.contains { $0.isLowercase }
    }
    
    var hasNumber: Bool {
        newPassword.contains { $0.isNumber }
    }
    
    var hasSpecialCharacter: Bool {
        let specialCharacters = CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?")
        return newPassword.unicodeScalars.contains { specialCharacters.contains($0) }
    }
    
    var isValid: Bool {
        !currentPassword.isEmpty &&
        hasMinimumLength &&
        hasUppercase &&
        hasLowercase &&
        hasNumber &&
        hasSpecialCharacter &&
        newPassword == confirmPassword
    }
    
    func changePassword() async -> Bool {
        guard isValid else { return false }
        
        isLoading = true
        defer { isLoading = false }
        
        guard let user = Auth.auth().currentUser,
              let email = user.email else {
            showError(message: "User not found")
            return false
        }
        
        do {
            // Reauthenticate user
            let credential = EmailAuthProvider.credential(
                withEmail: email,
                password: currentPassword
            )
            
            try await user.reauthenticate(with: credential)
            
            // Change password
            try await user.updatePassword(to: newPassword)
            
            return true
        } catch {
            if let errorCode = AuthErrorCode.Code(rawValue: (error as NSError).code) {
                switch errorCode {
                case .wrongPassword:
                    showError(message: "Current password is incorrect")
                case .requiresRecentLogin:
                    showError(message: "Please sign in again before changing your password")
                default:
                    showError(message: "Failed to change password")
                }
            } else {
                showError(message: "An error occurred")
            }
            return false
        }
    }
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}

struct ChangePasswordView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ChangePasswordView()
                .environmentObject(AppState())
        }
    }
}
