import Foundation
import FirebaseFirestore

struct CheckIn: Identifiable, Codable {
    var id: String
    var userId: String
    var timestamp: Date
    var responses: [Question: Int] // 1-5 scale responses
    var notes: String?
    var flags: [Flag]
    
    enum Question: String, Codable, CaseIterable {
        case sleep = "How well did you sleep?"
        case anxiety = "How anxious do you feel?"
        case mood = "How is your mood?"
        case energy = "How is your energy level?"
        case focus = "How is your ability to focus?"
        case appetite = "How is your appetite?"
        case socialConnection = "How connected do you feel to others?"
        case motivation = "How motivated do you feel?"
        
        var description: String {
            switch self {
            case .sleep:
                return "Rate your sleep quality from last night"
            case .anxiety:
                return "Rate your current anxiety level"
            case .mood:
                return "Rate your overall mood right now"
            case .energy:
                return "Rate your current energy level"
            case .focus:
                return "Rate your ability to concentrate today"
            case .appetite:
                return "Rate your appetite today"
            case .socialConnection:
                return "Rate how connected you feel to others"
            case .motivation:
                return "Rate your motivation level today"
            }
        }
        
        var lowDescription: String {
            switch self {
            case .sleep: return "Poor sleep"
            case .anxiety: return "Very anxious"
            case .mood: return "Low mood"
            case .energy: return "Low energy"
            case .focus: return "Unable to focus"
            case .appetite: return "Poor appetite"
            case .socialConnection: return "Disconnected"
            case .motivation: return "Unmotivated"
            }
        }
        
        var highDescription: String {
            switch self {
            case .sleep: return "Well rested"
            case .anxiety: return "Calm"
            case .mood: return "Great mood"
            case .energy: return "Energetic"
            case .focus: return "Highly focused"
            case .appetite: return "Good appetite"
            case .socialConnection: return "Well connected"
            case .motivation: return "Highly motivated"
            }
        }
    }
    
    enum Flag: String, Codable {
        case needsAttention = "Needs Attention"
        case crisis = "Crisis"
        case improvement = "Improvement"
        case consistent = "Consistent"
        case declining = "Declining"
    }
}

extension CheckIn {
    var dictionary: [String: Any] {
        [
            "id": id,
            "userId": userId,
            "timestamp": timestamp,
            "responses": responses.mapValues { $0 },
            "notes": notes ?? "",
            "flags": flags.map { $0.rawValue }
        ]
    }
    
    init?(dictionary: [String: Any]) {
        guard let id = dictionary["id"] as? String,
              let userId = dictionary["userId"] as? String,
              let timestamp = dictionary["timestamp"] as? Timestamp,
              let responsesDict = dictionary["responses"] as? [String: Int],
              let flagStrings = dictionary["flags"] as? [String] else {
            return nil
        }
        
        self.id = id
        self.userId = userId
        self.timestamp = timestamp.dateValue()
        self.notes = dictionary["notes"] as? String
        
        // Convert response dictionary
        var convertedResponses: [Question: Int] = [:]
        for (key, value) in responsesDict {
            if let question = Question(rawValue: key) {
                convertedResponses[question] = value
            }
        }
        self.responses = convertedResponses
        
        // Convert flags
        self.flags = flagStrings.compactMap { Flag(rawValue: $0) }
    }
    
    static func createInitialCheckIn(userId: String) -> CheckIn {
        CheckIn(
            id: UUID().uuidString,
            userId: userId,
            timestamp: Date(),
            responses: [:],
            notes: nil,
            flags: []
        )
    }
}
