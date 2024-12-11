import SwiftUI

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SignUpViewModel()
    
    var body: some View {
        ZStack {
            Color.blue.opacity(0.1).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    Text("Create Account")
                        .font(.system(size: 28, weight: .bold))
                        .padding(.top, 40)
                    
                    // Input Fields
                    VStack(spacing: 16) {
                        TextField("Full Name", text: $viewModel.fullName)
                            .textFieldStyle(CustomTextFieldStyle())
                            .textContentType(.name)
                        
                        TextField("Email", text: $viewModel.email)
                            .textFieldStyle(CustomTextFieldStyle())
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                        
                        SecureField("Password", text: $viewModel.password)
                            .textFieldStyle(CustomTextFieldStyle())
                            .textContentType(.newPassword)
                        
                        SecureField("Confirm Password", text: $viewModel.confirmPassword)
                            .textFieldStyle(CustomTextFieldStyle())
                            .textContentType(.newPassword)
                    }
                    .padding(.horizontal, 24)
                    
                    // Terms and Conditions
                    HStack {
                        Toggle("", isOn: $viewModel.acceptedTerms)
                            .labelsHidden()
                        
                        Text("I accept the ")
                            .foregroundColor(.gray) +
                        Text("Terms and Conditions")
                            .foregroundColor(.blue)
                            .underline()
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer(minLength: 30)
                    
                    // Sign Up Button
                    Button(action: viewModel.signUp) {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Create Account")
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal, 24)
                    .disabled(viewModel.isLoading || !viewModel.acceptedTerms)
                    .opacity(viewModel.acceptedTerms ? 1 : 0.6)
                    
                    // Social Sign Up Options
                    VStack(spacing: 16) {
                        Text("Or sign up with")
                            .foregroundColor(.gray)
                        
                        HStack(spacing: 20) {
                            SocialSignInButton(image: "apple.logo", action: viewModel.signUpWithApple)
                            SocialSignInButton(image: "g.circle.fill", action: viewModel.signUpWithGoogle)
                        }
                    }
                    .padding(.vertical, 20)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.blue)
                }
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SignUpView()
        }
    }
}
