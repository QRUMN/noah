import Foundation
import FirebaseFirestore

struct MoodAnalytics: Codable, Identifiable {
    let id: String
    let userId: String
    let period: String // "daily", "weekly", "monthly"
    let moodDistribution: [String: Int] // mood: count
    let averageMoodScore: Double
    let timestamp: Date
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: timestamp)
    }
}

struct JournalAnalytics: Codable, Identifiable {
    let id: String
    let userId: String
    let period: String
    let entryCount: Int
    let averageWordCount: Int
    let topTags: [String: Int]
    let timestamp: Date
}

struct MeditationAnalytics: Codable, Identifiable {
    let id: String
    let userId: String
    let period: String
    let totalSessions: Int
    let totalMinutes: Int
    let preferredCategories: [String: Int]
    let timestamp: Date
}

struct ProgressSnapshot: Codable, Identifiable {
    let id: String
    let userId: String
    let date: Date
    let moodScore: Double
    let journalStreak: Int
    let meditationMinutes: Int
    let goalsCompleted: Int
    let weeklyProgress: Double // 0-100%
}
