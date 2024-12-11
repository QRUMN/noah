import SwiftUI

class SignInViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func signIn() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields"
            return
        }
        
        isLoading = true
        // TODO: Implement actual sign in logic
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.isLoading = false
        }
    }
    
    func signInWithApple() {
        // TODO: Implement Apple Sign In
        print("Sign in with Apple tapped")
    }
    
    func signInWithGoogle() {
        // TODO: Implement Google Sign In
        print("Sign in with Google tapped")
    }
    
    func forgotPassword() {
        // TODO: Implement forgot password flow
        print("Forgot password tapped")
    }
}
