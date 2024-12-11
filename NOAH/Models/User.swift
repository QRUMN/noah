import Foundation

struct User: Identifiable, Codable {
    let id: String
    var email: String
    var name: String
    var profileImageUrl: String?
    var preferences: UserPreferences
    var createdAt: Date
    var updatedAt: Date
    
    init(id: String, email: String, name: String, profileImageUrl: String? = nil) {
        self.id = id
        self.email = email
        self.name = name
        self.profileImageUrl = profileImageUrl
        self.preferences = UserPreferences()
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

extension User {
    init(dictionary: [String: Any]) throws {
        guard let id = dictionary["id"] as? String,
              let email = dictionary["email"] as? String,
              let name = dictionary["name"] as? String,
              let createdAt = (dictionary["createdAt"] as? Timestamp)?.dateValue(),
              let updatedAt = (dictionary["updatedAt"] as? Timestamp)?.dateValue()
        else {
            throw NSError(domain: "User", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid user data"])
        }
        
        self.id = id
        self.email = email
        self.name = name
        self.profileImageUrl = dictionary["profileImageUrl"] as? String
        self.preferences = try UserPreferences(dictionary: dictionary["preferences"] as? [String: Any] ?? [:])
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    var dictionary: [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "email": email,
            "name": name,
            "preferences": preferences.dictionary,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: Date())
        ]
        
        if let profileImageUrl = profileImageUrl {
            dict["profileImageUrl"] = profileImageUrl
        }
        
        return dict
    }
}

struct UserPreferences: Codable {
    var notificationsEnabled: Bool
    var darkModeEnabled: Bool
    var emailNotificationsEnabled: Bool
    
    init(notificationsEnabled: Bool = true,
         darkModeEnabled: Bool = false,
         emailNotificationsEnabled: Bool = true) {
        self.notificationsEnabled = notificationsEnabled
        self.darkModeEnabled = darkModeEnabled
        self.emailNotificationsEnabled = emailNotificationsEnabled
    }
    
    init(dictionary: [String: Any]) throws {
        self.notificationsEnabled = dictionary["notificationsEnabled"] as? Bool ?? true
        self.darkModeEnabled = dictionary["darkModeEnabled"] as? Bool ?? false
        self.emailNotificationsEnabled = dictionary["emailNotificationsEnabled"] as? Bool ?? true
    }
    
    var dictionary: [String: Any] {
        return [
            "notificationsEnabled": notificationsEnabled,
            "darkModeEnabled": darkModeEnabled,
            "emailNotificationsEnabled": emailNotificationsEnabled
        ]
    }
}
