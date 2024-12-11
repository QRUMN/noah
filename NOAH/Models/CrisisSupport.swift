import Foundation
import CoreLocation

// MARK: - Safety Plan
struct SafetyPlan: Identifiable, Codable {
    var id: String = UUID().uuidString
    var userId: String
    var lastUpdated: Date
    var warningSignals: [String]
    var copingStrategies: [String]
    var reasonsToLive: [String]
    var supportContacts: [EmergencyContact]
    var professionalContacts: [EmergencyContact]
    var safeEnvironmentSteps: [String]
    var personalNotes: String?
}

// MARK: - Emergency Contact
struct EmergencyContact: Identifiable, Codable {
    var id: String = UUID().uuidString
    var name: String
    var relationship: String
    var phoneNumber: String
    var isAvailable24Hours: Bool
    var alternatePhoneNumber: String?
    var email: String?
    var address: String?
    var notes: String?
}

// MARK: - Crisis Resource
struct CrisisResource: Identifiable, Codable {
    var id: String = UUID().uuidString
    var name: String
    var category: ResourceCategory
    var description: String
    var phoneNumber: String?
    var website: String?
    var address: String?
    var coordinates: CLLocationCoordinate2D?
    var availabilityHours: String
    var languages: [String]
    var services: [String]
    var isVerified: Bool
    
    enum ResourceCategory: String, Codable {
        case emergency = "Emergency Services"
        case mentalHealth = "Mental Health"
        case addiction = "Addiction Support"
        case suicide = "Suicide Prevention"
        case domesticViolence = "Domestic Violence"
        case lgbtq = "LGBTQ+ Support"
        case veterans = "Veterans Support"
        case youth = "Youth Services"
    }
}

// MARK: - Helpline
struct Helpline: Identifiable, Codable {
    var id: String = UUID().uuidString
    var name: String
    var phoneNumber: String
    var smsNumber: String?
    var description: String
    var category: HelplineCategory
    var isAvailable24Hours: Bool
    var languages: [String]
    var website: String?
    
    enum HelplineCategory: String, Codable {
        case crisis = "Crisis"
        case suicide = "Suicide"
        case mentalHealth = "Mental Health"
        case addiction = "Addiction"
        case domesticViolence = "Domestic Violence"
        case lgbtq = "LGBTQ+"
        case veterans = "Veterans"
        case youth = "Youth"
    }
}

// MARK: - Emergency Service
struct EmergencyService: Identifiable, Codable {
    var id: String = UUID().uuidString
    var name: String
    var type: ServiceType
    var phoneNumber: String
    var address: String
    var coordinates: CLLocationCoordinate2D
    var distance: Double?
    var estimatedResponseTime: TimeInterval?
    
    enum ServiceType: String, Codable {
        case hospital = "Hospital"
        case police = "Police"
        case crisisCenter = "Crisis Center"
        case mentalHealthFacility = "Mental Health Facility"
        case ambulance = "Ambulance"
    }
}

// MARK: - CLLocationCoordinate2D Extension
extension CLLocationCoordinate2D: Codable {
    enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        self.init(latitude: latitude, longitude: longitude)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
    }
}
