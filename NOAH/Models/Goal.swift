import Foundation
import FirebaseFirestore

enum GoalCategory: String, Codable, CaseIterable {
    case mood = "Mood Improvement"
    case meditation = "Meditation Practice"
    case journaling = "Journaling"
    case selfCare = "Self Care"
    case social = "Social Connection"
    case exercise = "Physical Activity"
    case sleep = "Sleep"
    case custom = "Custom"
}

enum GoalFrequency: String, Codable, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case custom = "Custom"
}

struct Goal: Identifiable, Codable {
    let id: String
    let userId: String
    let title: String
    let description: String
    let category: GoalCategory
    let frequency: GoalFrequency
    let target: Int
    let progress: Int
    var isCompleted: Bool
    let startDate: Date
    let endDate: Date?
    let reminderTime: Date?
    
    var progressPercentage: Double {
        return min(Double(progress) / Double(target) * 100, 100)
    }
}

struct Achievement: Identifiable, Codable {
    let id: String
    let userId: String
    let title: String
    let description: String
    let category: GoalCategory
    let imageURL: String?
    let unlockedDate: Date
    let criteria: String
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: unlockedDate)
    }
}

struct Milestone: Identifiable, Codable {
    let id: String
    let goalId: String
    let title: String
    let description: String
    let target: Int
    var isCompleted: Bool
    let completedDate: Date?
}
