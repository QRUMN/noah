import Foundation
import FirebaseFirestore

enum ResourceCategory: String, Codable, CaseIterable {
    case anxiety = "Anxiety"
    case depression = "Depression"
    case stress = "Stress Management"
    case relationships = "Relationships"
    case selfCare = "Self Care"
    case crisis = "Crisis Support"
    case professional = "Professional Help"
    case mindfulness = "Mindfulness"
}

struct Resource: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let category: ResourceCategory
    let content: String
    let tags: [String]
    let imageURL: String?
    let externalLinks: [String]
    let lastUpdated: Date
    let isEmergencyResource: Bool
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: lastUpdated)
    }
}

struct EmergencyContact: Identifiable, Codable {
    let id: String
    let name: String
    let phoneNumber: String
    let relationship: String
    let isHotline: Bool
    let availability: String // "24/7" or specific hours
    let notes: String?
}

struct SafetyPlan: Identifiable, Codable {
    let id: String
    let userId: String
    let warningSignals: [String]
    let copingStrategies: [String]
    let reasonsToLive: [String]
    let safeEnvironment: [String]
    let professionalContacts: [EmergencyContact]
    let personalContacts: [EmergencyContact]
    let lastUpdated: Date
}
