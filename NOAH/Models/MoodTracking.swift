import Foundation
import FirebaseFirestore

struct MoodEntry: Identifiable, Codable {
    var id: String = UUID().uuidString
    var userId: String
    var timestamp: Date
    var moodScore: Int // 1-5 scale
    var emotions: [String] // Multiple emotions can be selected
    var activities: [String] // What activities influenced the mood
    var notes: String?
    var location: String?
    var weather: String?
}

struct JournalEntry: Identifiable, Codable {
    var id: String = UUID().uuidString
    var userId: String
    var timestamp: Date
    var content: String
    var prompt: String?
    var tags: [String]
    var moodBefore: Int?
    var moodAfter: Int?
    var aiAnalysis: JournalAnalysis?
}

struct JournalAnalysis: Codable {
    var sentimentScore: Double
    var emotionalThemes: [String]
    var suggestedCopingStrategies: [String]
    var identifiedPatterns: [String]
    var suggestedPrompts: [String]
}

struct MoodSummary: Codable {
    var averageMoodScore: Double
    var dominantEmotions: [String: Int]
    var commonActivities: [String: Int]
    var moodTrends: [String: Double] // Day of week to average mood
    var insightMessages: [String]
}

// Helper for generating smart journal prompts
struct JournalPromptGenerator {
    static func generatePrompt(based on: MoodEntry) -> String {
        let prompts = [
            "How did your [activity] today influence your feeling of [emotion]?",
            "What thoughts were going through your mind when you felt [emotion]?",
            "What would you like to do differently next time you feel this way?",
            "What are three things that helped you cope with these feelings today?",
            "How does this mood compare to how you felt yesterday?",
            "What would you tell a friend who was feeling this way?"
        ]
        
        // For now return a random prompt, but this will be enhanced with AI
        return prompts.randomElement() ?? prompts[0]
    }
}

// Analytics helper for mood insights
struct MoodAnalytics {
    static func analyzeMoodTrends(_ entries: [MoodEntry]) -> MoodSummary {
        // Mock implementation - will be enhanced with actual analytics
        return MoodSummary(
            averageMoodScore: 3.5,
            dominantEmotions: ["calm": 5, "happy": 3],
            commonActivities: ["exercise": 4, "work": 3],
            moodTrends: ["Monday": 3.8, "Tuesday": 4.0],
            insightMessages: ["You tend to feel better after exercise",
                            "Your mood is typically higher in the morning"]
        )
    }
}
