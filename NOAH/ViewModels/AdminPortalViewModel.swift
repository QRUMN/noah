import SwiftUI
import FirebaseFirestore
import FirebaseAuth

class AdminPortalViewModel: ObservableObject {
    @Published var resources: [CrisisResource] = []
    @Published var pendingProviders: [SupportProvider] = []
    @Published var users: [UserProfile] = []
    @Published var analytics = Analytics()
    
    private let db = Firestore.firestore()
    
    init() {
        refreshData()
    }
    
    func refreshData() {
        fetchResources()
        fetchPendingProviders()
        fetchUsers()
        fetchAnalytics()
    }
    
    // MARK: - Resource Management
    private func fetchResources() {
        db.collection("crisis_resources")
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    print("Error fetching resources: \(error)")
                    return
                }
                
                self?.resources = snapshot?.documents.compactMap { document in
                    try? document.data(as: CrisisResource.self)
                } ?? []
            }
    }
    
    func addResource(_ resource: CrisisResource) {
        do {
            try db.collection("crisis_resources").addDocument(from: resource)
            fetchResources()
        } catch {
            print("Error adding resource: \(error)")
        }
    }
    
    func editResource(_ resource: CrisisResource) {
        guard let id = resource.id else { return }
        
        do {
            try db.collection("crisis_resources").document(id).setData(from: resource)
            fetchResources()
        } catch {
            print("Error updating resource: \(error)")
        }
    }
    
    func deleteResource(_ resource: CrisisResource) {
        guard let id = resource.id else { return }
        
        db.collection("crisis_resources").document(id).delete { error in
            if let error = error {
                print("Error deleting resource: \(error)")
                return
            }
            self.fetchResources()
        }
    }
    
    // MARK: - Provider Verification
    private func fetchPendingProviders() {
        db.collection("support_providers")
            .whereField("isVerified", isEqualTo: false)
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    print("Error fetching providers: \(error)")
                    return
                }
                
                self?.pendingProviders = snapshot?.documents.compactMap { document in
                    try? document.data(as: SupportProvider.self)
                } ?? []
            }
    }
    
    func verifyProvider(_ provider: SupportProvider) {
        guard let id = provider.id else { return }
        
        var updatedProvider = provider
        updatedProvider.isVerified = true
        
        do {
            try db.collection("support_providers").document(id).setData(from: updatedProvider)
            fetchPendingProviders()
        } catch {
            print("Error verifying provider: \(error)")
        }
    }
    
    func rejectProvider(_ provider: SupportProvider) {
        guard let id = provider.id else { return }
        
        db.collection("support_providers").document(id).delete { error in
            if let error = error {
                print("Error rejecting provider: \(error)")
                return
            }
            self.fetchPendingProviders()
        }
    }
    
    // MARK: - User Management
    private func fetchUsers() {
        db.collection("users")
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    print("Error fetching users: \(error)")
                    return
                }
                
                self?.users = snapshot?.documents.compactMap { document in
                    try? document.data(as: UserProfile.self)
                } ?? []
            }
    }
    
    func viewUserDetails(_ user: UserProfile) {
        // Navigate to user details view
    }
    
    func suspendUser(_ user: UserProfile) {
        guard let id = user.id else { return }
        
        var updatedUser = user
        updatedUser.isSuspended = true
        
        do {
            try db.collection("users").document(id).setData(from: updatedUser)
            fetchUsers()
        } catch {
            print("Error suspending user: \(error)")
        }
    }
    
    // MARK: - Analytics
    private func fetchAnalytics() {
        // Fetch active users
        db.collection("analytics")
            .document("usage")
            .getDocument { [weak self] snapshot, error in
                if let error = error {
                    print("Error fetching analytics: \(error)")
                    return
                }
                
                if let data = snapshot?.data() {
                    self?.analytics.activeUsers = data["activeUsers"] as? Int ?? 0
                    self?.analytics.emergencyCalls = data["emergencyCalls"] as? Int ?? 0
                    self?.analytics.resourcesAccessed = data["resourcesAccessed"] as? Int ?? 0
                    self?.analytics.avgEmergencyResponseTime = data["avgEmergencyResponseTime"] as? Double ?? 0
                    self?.analytics.avgCrisisLineResponseTime = data["avgCrisisLineResponseTime"] as? Double ?? 0
                }
            }
        
        // Fetch resource usage
        db.collection("analytics")
            .document("resourceUsage")
            .getDocument { [weak self] snapshot, error in
                if let error = error {
                    print("Error fetching resource usage: \(error)")
                    return
                }
                
                if let data = snapshot?.data() {
                    self?.analytics.resourceUsage = (data["usage"] as? [[String: Any]])?.compactMap {
                        guard let name = $0["name"] as? String,
                              let count = $0["count"] as? Double else { return nil }
                        return (name, count)
                    } ?? []
                }
            }
        
        // Fetch recent feedback
        db.collection("feedback")
            .order(by: "timestamp", descending: true)
            .limit(to: 5)
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    print("Error fetching feedback: \(error)")
                    return
                }
                
                self?.analytics.recentFeedback = snapshot?.documents.compactMap {
                    guard let data = $0.data() as? [String: Any],
                          let title = data["title"] as? String,
                          let message = data["message"] as? String,
                          let timestamp = data["timestamp"] as? Timestamp else { return nil }
                    return (title, message, timestamp.dateValue())
                } ?? []
            }
    }
}

// MARK: - Analytics Model
struct Analytics {
    var activeUsers: Int = 0
    var emergencyCalls: Int = 0
    var resourcesAccessed: Int = 0
    var avgEmergencyResponseTime: Double = 0
    var avgCrisisLineResponseTime: Double = 0
    var resourceUsage: [(String, Double)] = []
    var recentFeedback: [(String, String, Date)] = []
}

// MARK: - User Profile Model
struct UserProfile: Identifiable, Codable {
    var id: String?
    var name: String
    var email: String
    var lastActive: Date
    var isSuspended: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case lastActive
        case isSuspended
    }
}

// MARK: - Support Provider Model
struct SupportProvider: Identifiable, Codable {
    var id: String?
    var name: String
    var credentials: String
    var specialties: [String]
    var isVerified: Bool
    var rating: Double
    var reviewCount: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case credentials
        case specialties
        case isVerified
        case rating
        case reviewCount
    }
}
