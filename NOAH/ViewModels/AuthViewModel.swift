import SwiftUI
import FirebaseAuth
import FirebaseFirestore

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isAdmin = false
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    
    init() {
        auth.addStateDidChangeListener { [weak self] _, user in
            self?.isAuthenticated = user != nil
            if let user = user {
                self?.checkAdminStatus(userId: user.uid)
            }
        }
    }
    
    func signIn(email: String, password: String) async {
        isLoading = true
        showError = false
        
        do {
            let result = try await auth.signIn(withEmail: email, password: password)
            checkAdminStatus(userId: result.user.uid)
        } catch {
            showError = true
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func signInAsAdmin(email: String, password: String) async {
        isLoading = true
        showError = false
        
        do {
            let result = try await auth.signIn(withEmail: email, password: password)
            let isAdmin = await checkAdminStatus(userId: result.user.uid)
            
            if !isAdmin {
                try await auth.signOut()
                showError = true
                errorMessage = "This account does not have admin privileges."
                isAuthenticated = false
            }
        } catch {
            showError = true
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func signUp(email: String, password: String, name: String) async {
        isLoading = true
        showError = false
        
        do {
            let result = try await auth.createUser(withEmail: email, password: password)
            
            // Create user profile
            let userProfile = [
                "name": name,
                "email": email,
                "isAdmin": false,
                "createdAt": Timestamp(),
                "lastActive": Timestamp()
            ]
            
            try await db.collection("users").document(result.user.uid).setData(userProfile)
        } catch {
            showError = true
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func signInAnonymously() {
        isLoading = true
        showError = false
        
        auth.signInAnonymously { [weak self] result, error in
            if let error = error {
                self?.showError = true
                self?.errorMessage = error.localizedDescription
            }
            self?.isLoading = false
        }
    }
    
    func signOut() {
        do {
            try auth.signOut()
            isAdmin = false
        } catch {
            print("Error signing out: \(error)")
        }
    }
    
    private func checkAdminStatus(userId: String) async -> Bool {
        do {
            let document = try await db.collection("users").document(userId).getDocument()
            if let isAdmin = document.data()?["isAdmin"] as? Bool {
                self.isAdmin = isAdmin
                return isAdmin
            }
        } catch {
            print("Error checking admin status: \(error)")
        }
        return false
    }
    
    // MARK: - Admin Management
    
    func createAdminUser(email: String, password: String, name: String) async {
        isLoading = true
        showError = false
        
        do {
            let result = try await auth.createUser(withEmail: email, password: password)
            
            // Create admin profile
            let adminProfile = [
                "name": name,
                "email": email,
                "isAdmin": true,
                "createdAt": Timestamp(),
                "lastActive": Timestamp()
            ]
            
            try await db.collection("users").document(result.user.uid).setData(adminProfile)
        } catch {
            showError = true
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func grantAdminAccess(userId: String) async {
        do {
            try await db.collection("users").document(userId).updateData([
                "isAdmin": true
            ])
        } catch {
            print("Error granting admin access: \(error)")
        }
    }
    
    func revokeAdminAccess(userId: String) async {
        do {
            try await db.collection("users").document(userId).updateData([
                "isAdmin": false
            ])
        } catch {
            print("Error revoking admin access: \(error)")
        }
    }
}
