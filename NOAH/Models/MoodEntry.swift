import Foundation
import FirebaseFirestore

struct MoodEntry: Identifiable, Codable {
    var id: String
    var userId: String
    var mood: Mood
    var intensity: Int // 1-5 scale
    var activities: [Activity]
    var notes: String?
    var timestamp: Date
    var tags: [String]
    
    enum Mood: String, Codable, CaseIterable {
        case veryHappy = "Very Happy"
        case happy = "Happy"
        case neutral = "Neutral"
        case sad = "Sad"
        case verySad = "Very Sad"
        case anxious = "Anxious"
        case angry = "Angry"
        case overwhelmed = "Overwhelmed"
        
        var icon: String {
            switch self {
            case .veryHappy: return "😄"
            case .happy: return "🙂"
            case .neutral: return "😐"
            case .sad: return "😢"
            case .verySad: return "😥"
            case .anxious: return "😰"
            case .angry: return "😠"
            case .overwhelmed: return "😫"
            }
        }
        
        var color: String {
            switch self {
            case .veryHappy: return "#FFD700" // Gold
            case .happy: return "#98FB98" // Pale Green
            case .neutral: return "#87CEEB" // Sky Blue
            case .sad: return "#DDA0DD" // Plum
            case .verySad: return "#778899" // Light Slate Gray
            case .anxious: return "#F4A460" // Sandy Brown
            case .angry: return "#CD5C5C" // Indian Red
            case .overwhelmed: return "#B8860B" // Dark Golden Rod
            }
        }
    }
    
    enum Activity: String, Codable, CaseIterable {
        case exercise = "Exercise"
        case meditation = "Meditation"
        case therapy = "Therapy"
        case socializing = "Socializing"
        case work = "Work"
        case reading = "Reading"
        case nature = "Nature"
        case music = "Music"
        case art = "Art"
        case sleep = "Sleep"
        case medication = "Medication"
        case journaling = "Journaling"
        
        var icon: String {
            switch self {
            case .exercise: return "figure.walk"
            case .meditation: return "sparkles"
            case .therapy: return "heart.text.square"
            case .socializing: return "person.2"
            case .work: return "briefcase"
            case .reading: return "book"
            case .nature: return "leaf"
            case .music: return "music.note"
            case .art: return "paintbrush"
            case .sleep: return "moon"
            case .medication: return "pills"
            case .journaling: return "note.text"
            }
        }
    }
}

extension MoodEntry {
    var dictionary: [String: Any] {
        [
            "id": id,
            "userId": userId,
            "mood": mood.rawValue,
            "intensity": intensity,
            "activities": activities.map { $0.rawValue },
            "notes": notes ?? "",
            "timestamp": timestamp,
            "tags": tags
        ]
    }
    
    init?(dictionary: [String: Any]) {
        guard let id = dictionary["id"] as? String,
              let userId = dictionary["userId"] as? String,
              let moodString = dictionary["mood"] as? String,
              let mood = Mood(rawValue: moodString),
              let intensity = dictionary["intensity"] as? Int,
              let activityStrings = dictionary["activities"] as? [String],
              let timestamp = dictionary["timestamp"] as? Timestamp,
              let tags = dictionary["tags"] as? [String] else {
            return nil
        }
        
        self.id = id
        self.userId = userId
        self.mood = mood
        self.intensity = intensity
        self.activities = activityStrings.compactMap { Activity(rawValue: $0) }
        self.notes = dictionary["notes"] as? String
        self.timestamp = timestamp.dateValue()
        self.tags = tags
    }
}
