import Foundation

struct MeditationSession: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let duration: TimeInterval
    let category: Category
    let audioURL: URL
    let imageURL: URL
    let tags: [String]
    
    enum Category: String, Codable, CaseIterable {
        case mindfulness = "Mindfulness"
        case stress = "Stress Relief"
        case sleep = "Better Sleep"
        case anxiety = "Anxiety Relief"
        case focus = "Focus"
        
        var systemImage: String {
            switch self {
            case .mindfulness: return "brain.head.profile"
            case .stress: return "leaf.fill"
            case .sleep: return "moon.stars.fill"
            case .anxiety: return "heart.circle.fill"
            case .focus: return "target"
            }
        }
        
        var color: String {
            switch self {
            case .mindfulness: return "meditation.purple"
            case .stress: return "meditation.green"
            case .sleep: return "meditation.blue"
            case .anxiety: return "meditation.pink"
            case .focus: return "meditation.orange"
            }
        }
    }
    
    static let preview = MeditationSession(
        id: UUID().uuidString,
        title: "Mindful Breathing",
        description: "A gentle introduction to mindfulness meditation focusing on breath awareness.",
        duration: 600, // 10 minutes
        category: .mindfulness,
        audioURL: URL(string: "https://example.com/meditations/mindful-breathing.mp3")!,
        imageURL: URL(string: "https://example.com/meditations/mindful-breathing.jpg")!,
        tags: ["beginner", "breathing", "mindfulness"]
    )
}

struct MeditationProgress: Codable {
    let id: String
    let userId: String
    let sessionId: String
    let startTime: Date
    let duration: TimeInterval
    let completed: Bool
    
    var dictionary: [String: Any] {
        [
            "id": id,
            "userId": userId,
            "sessionId": sessionId,
            "startTime": startTime,
            "duration": duration,
            "completed": completed
        ]
    }
}
