import SwiftUI

class SignUpViewModel: ObservableObject {
    @Published var fullName = ""
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var acceptedTerms = false
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage: String?
    
    func signUp() {
        // Validate input
        guard !fullName.isEmpty, !email.isEmpty, !password.isEmpty else {
            showError(message: "Please fill in all fields")
            return
        }
        
        guard password == confirmPassword else {
            showError(message: "Passwords do not match")
            return
        }
        
        guard acceptedTerms else {
            showError(message: "Please accept the terms and conditions")
            return
        }
        
        isLoading = true
        // TODO: Implement actual sign up logic
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.isLoading = false
        }
    }
    
    func signUpWithApple() {
        // TODO: Implement Apple Sign Up
        print("Sign up with Apple tapped")
    }
    
    func signUpWithGoogle() {
        // TODO: Implement Google Sign Up
        print("Sign up with Google tapped")
    }
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}
