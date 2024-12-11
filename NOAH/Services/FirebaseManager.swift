import FirebaseAuth
import FirebaseFirestore

class FirebaseManager {
    static let shared = FirebaseManager()
    private let db = Firestore.firestore()
    
    private init() {}
    
    // MARK: - Authentication
    
    func signIn(email: String, password: String) async throws {
        try await Auth.auth().signIn(withEmail: email, password: password)
    }
    
    func signUp(email: String, password: String, name: String) async throws -> User {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        let user = User(id: result.user.uid, email: email, name: name)
        try await saveUser(user)
        return user
    }
    
    // MARK: - User Management
    
    func fetchUser(userId: String) async throws -> User {
        let document = try await db.collection("users").document(userId).getDocument()
        guard let data = document.data() else {
            throw NSError(domain: "FirebaseManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found"])
        }
        return try User(dictionary: data)
    }
    
    func saveUser(_ user: User) async throws {
        try await db.collection("users").document(user.id).setData(user.dictionary)
    }
    
    func updateUser(_ user: User) async throws {
        try await db.collection("users").document(user.id).updateData(user.dictionary)
    }
}
