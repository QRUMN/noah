import Foundation
import FirebaseFirestore

struct JournalEntry: Identifiable, Codable {
    let id: String
    let userId: String
    let title: String
    let content: String
    let mood: Mood
    let prompt: JournalPrompt?
    let tags: [String]
    let createdAt: Date
    let updatedAt: Date
    var isFavorite: Bool
    
    enum Mood: String, Codable, CaseIterable {
        case joyful = "Joyful"
        case grateful = "Grateful"
        case calm = "Calm"
        case neutral = "Neutral"
        case anxious = "Anxious"
        case sad = "Sad"
        case frustrated = "Frustrated"
        
        var emoji: String {
            switch self {
            case .joyful: return "😊"
            case .grateful: return "🙏"
            case .calm: return "😌"
            case .neutral: return "😐"
            case .anxious: return "😰"
            case .sad: return "😢"
            case .frustrated: return "😤"
            }
        }
        
        var color: String {
            switch self {
            case .joyful: return "journal.yellow"
            case .grateful: return "journal.green"
            case .calm: return "journal.blue"
            case .neutral: return "journal.gray"
            case .anxious: return "journal.purple"
            case .sad: return "journal.indigo"
            case .frustrated: return "journal.red"
            }
        }
    }
    
    var dictionary: [String: Any] {
        [
            "id": id,
            "userId": userId,
            "title": title,
            "content": content,
            "mood": mood.rawValue,
            "prompt": prompt?.dictionary,
            "tags": tags,
            "createdAt": createdAt,
            "updatedAt": updatedAt,
            "isFavorite": isFavorite
        ].compactMapValues { $0 }
    }
    
    static func from(_ document: DocumentSnapshot) -> JournalEntry? {
        guard
            let data = document.data(),
            let userId = data["userId"] as? String,
            let title = data["title"] as? String,
            let content = data["content"] as? String,
            let moodRaw = data["mood"] as? String,
            let mood = Mood(rawValue: moodRaw),
            let tags = data["tags"] as? [String],
            let createdAt = (data["createdAt"] as? Timestamp)?.dateValue(),
            let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue(),
            let isFavorite = data["isFavorite"] as? Bool
        else { return nil }
        
        let promptData = data["prompt"] as? [String: Any]
        let prompt = promptData.flatMap(JournalPrompt.from)
        
        return JournalEntry(
            id: document.documentID,
            userId: userId,
            title: title,
            content: content,
            mood: mood,
            prompt: prompt,
            tags: tags,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isFavorite: isFavorite
        )
    }
}

struct JournalPrompt: Codable {
    let id: String
    let category: Category
    let text: String
    let followUpQuestions: [String]
    
    enum Category: String, Codable, CaseIterable {
        case selfDiscovery = "Self Discovery"
        case gratitude = "Gratitude"
        case emotions = "Emotional Awareness"
        case goals = "Goals & Aspirations"
        case relationships = "Relationships"
        case reflection = "Daily Reflection"
        
        var systemImage: String {
            switch self {
            case .selfDiscovery: return "person.fill.questionmark"
            case .gratitude: return "heart.fill"
            case .emotions: return "brain.head.profile"
            case .goals: return "target"
            case .relationships: return "person.2.fill"
            case .reflection: return "sun.and.horizon.fill"
            }
        }
    }
    
    var dictionary: [String: Any] {
        [
            "id": id,
            "category": category.rawValue,
            "text": text,
            "followUpQuestions": followUpQuestions
        ]
    }
    
    static func from(_ dictionary: [String: Any]) -> JournalPrompt? {
        guard
            let id = dictionary["id"] as? String,
            let categoryRaw = dictionary["category"] as? String,
            let category = Category(rawValue: categoryRaw),
            let text = dictionary["text"] as? String,
            let followUpQuestions = dictionary["followUpQuestions"] as? [String]
        else { return nil }
        
        return JournalPrompt(
            id: id,
            category: category,
            text: text,
            followUpQuestions: followUpQuestions
        )
    }
    
    static let samples = [
        JournalPrompt(
            id: "1",
            category: .selfDiscovery,
            text: "What are three things that make you unique, and how do they contribute to your personal growth?",
            followUpQuestions: [
                "How have these qualities helped you overcome challenges?",
                "In what ways would you like to further develop these traits?",
                "How do others respond to these unique aspects of your personality?"
            ]
        ),
        JournalPrompt(
            id: "2",
            category: .gratitude,
            text: "Describe a recent moment of joy or kindness that you experienced. What made it special?",
            followUpQuestions: [
                "How did this moment affect your mood for the rest of the day?",
                "What can you do to create more moments like this?",
                "Who would you like to share this experience with?"
            ]
        ),
        JournalPrompt(
            id: "3",
            category: .emotions,
            text: "Think about a strong emotion you felt today. What triggered it, and how did you respond?",
            followUpQuestions: [
                "How did your body feel during this emotional experience?",
                "What coping strategies did you use, if any?",
                "What would you do differently next time?"
            ]
        )
    ]
}
