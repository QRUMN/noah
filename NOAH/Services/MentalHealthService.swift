import Foundation
import FirebaseFirestore
import FirebaseAuth

class MentalHealthService: ObservableObject {
    private let db = Firestore.firestore()
    
    // MARK: - Mood Entries
    
    func saveMoodEntry(_ entry: MoodEntry) async throws {
        try await db.collection("moodEntries")
            .document(entry.id)
            .setData(entry.dictionary)
    }
    
    func getMoodEntries(forUserId userId: String, limit: Int = 30) async throws -> [MoodEntry] {
        let snapshot = try await db.collection("moodEntries")
            .whereField("userId", isEqualTo: userId)
            .order(by: "timestamp", descending: true)
            .limit(to: limit)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            MoodEntry(dictionary: document.data())
        }
    }
    
    func getMoodEntry(id: String) async throws -> MoodEntry? {
        let document = try await db.collection("moodEntries")
            .document(id)
            .getDocument()
        
        guard let data = document.data() else { return nil }
        return MoodEntry(dictionary: data)
    }
    
    // MARK: - Check-ins
    
    func saveCheckIn(_ checkIn: CheckIn) async throws {
        try await db.collection("checkIns")
            .document(checkIn.id)
            .setData(checkIn.dictionary)
    }
    
    func getCheckIns(forUserId userId: String, limit: Int = 30) async throws -> [CheckIn] {
        let snapshot = try await db.collection("checkIns")
            .whereField("userId", isEqualTo: userId)
            .order(by: "timestamp", descending: true)
            .limit(to: limit)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            CheckIn(dictionary: document.data())
        }
    }
    
    func getLatestCheckIn(forUserId userId: String) async throws -> CheckIn? {
        let snapshot = try await db.collection("checkIns")
            .whereField("userId", isEqualTo: userId)
            .order(by: "timestamp", descending: true)
            .limit(to: 1)
            .getDocuments()
        
        guard let document = snapshot.documents.first else { return nil }
        return CheckIn(dictionary: document.data())
    }
    
    // MARK: - Journal Entries
    
    func saveJournalEntry(_ entry: JournalEntry) async throws {
        try await db.collection("journalEntries")
            .document(entry.id)
            .setData([
                "id": entry.id,
                "userId": entry.userId,
                "timestamp": entry.timestamp,
                "content": entry.content,
                "prompt": entry.prompt as Any,
                "tags": entry.tags,
                "moodBefore": entry.moodBefore as Any,
                "moodAfter": entry.moodAfter as Any
            ])
    }
    
    func getJournalEntries(forUserId userId: String, limit: Int = 30) async throws -> [JournalEntry] {
        let snapshot = try await db.collection("journalEntries")
            .whereField("userId", isEqualTo: userId)
            .order(by: "timestamp", descending: true)
            .limit(to: limit)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            let data = document.data()
            return JournalEntry(
                id: data["id"] as? String ?? UUID().uuidString,
                userId: data["userId"] as? String ?? "",
                timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date(),
                content: data["content"] as? String ?? "",
                prompt: data["prompt"] as? String,
                tags: data["tags"] as? [String] ?? [],
                moodBefore: data["moodBefore"] as? Int,
                moodAfter: data["moodAfter"] as? Int
            )
        }
    }
    
    func getJournalAnalytics(forUserId userId: String, days: Int = 30) async throws -> JournalAnalytics {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        
        let snapshot = try await db.collection("journalEntries")
            .whereField("userId", isEqualTo: userId)
            .whereField("timestamp", isGreaterThan: startDate)
            .order(by: "timestamp", descending: false)
            .getDocuments()
        
        let entries = snapshot.documents.compactMap { document in
            let data = document.data()
            return JournalEntry(
                id: data["id"] as? String ?? UUID().uuidString,
                userId: data["userId"] as? String ?? "",
                timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date(),
                content: data["content"] as? String ?? "",
                prompt: data["prompt"] as? String,
                tags: data["tags"] as? [String] ?? [],
                moodBefore: data["moodBefore"] as? Int,
                moodAfter: data["moodAfter"] as? Int
            )
        }
        
        var moodImprovementCount = 0
        var totalMoodChange = 0
        var commonTags: [String: Int] = [:]
        
        entries.forEach { entry in
            if let before = entry.moodBefore,
               let after = entry.moodAfter {
                if after > before {
                    moodImprovementCount += 1
                }
                totalMoodChange += (after - before)
            }
            
            entry.tags.forEach { tag in
                commonTags[tag, default: 0] += 1
            }
        }
        
        return JournalAnalytics(
            totalEntries: entries.count,
            moodImprovementRate: entries.isEmpty ? 0 : Double(moodImprovementCount) / Double(entries.count),
            averageMoodChange: entries.isEmpty ? 0 : Double(totalMoodChange) / Double(entries.count),
            commonTags: commonTags,
            startDate: startDate,
            endDate: Date()
        )
    }
    
    // MARK: - Analytics
    
    func getMoodAnalytics(forUserId userId: String, days: Int = 30) async throws -> MoodAnalytics {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        
        let snapshot = try await db.collection("moodEntries")
            .whereField("userId", isEqualTo: userId)
            .whereField("timestamp", isGreaterThan: startDate)
            .order(by: "timestamp", descending: false)
            .getDocuments()
        
        let entries = snapshot.documents.compactMap { MoodEntry(dictionary: $0.data()) }
        
        var moodCounts: [MoodEntry.Mood: Int] = [:]
        var activityCounts: [MoodEntry.Activity: Int] = [:]
        var averageIntensity = 0.0
        
        entries.forEach { entry in
            moodCounts[entry.mood, default: 0] += 1
            entry.activities.forEach { activity in
                activityCounts[activity, default: 0] += 1
            }
            averageIntensity += Double(entry.intensity)
        }
        
        if !entries.isEmpty {
            averageIntensity /= Double(entries.count)
        }
        
        return MoodAnalytics(
            moodFrequency: moodCounts,
            activityFrequency: activityCounts,
            averageIntensity: averageIntensity,
            totalEntries: entries.count,
            startDate: startDate,
            endDate: Date()
        )
    }
}

// MARK: - Analytics Models

struct MoodAnalytics {
    let moodFrequency: [MoodEntry.Mood: Int]
    let activityFrequency: [MoodEntry.Activity: Int]
    let averageIntensity: Double
    let totalEntries: Int
    let startDate: Date
    let endDate: Date
    
    var mostFrequentMood: (MoodEntry.Mood, Int)? {
        moodFrequency.max { $0.value < $1.value }
    }
    
    var mostFrequentActivity: (MoodEntry.Activity, Int)? {
        activityFrequency.max { $0.value < $1.value }
    }
    
    var entriesPerDay: Double {
        let days = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 1
        return Double(totalEntries) / Double(days)
    }
}

struct JournalAnalytics {
    let totalEntries: Int
    let moodImprovementRate: Double
    let averageMoodChange: Double
    let commonTags: [String: Int]
    let startDate: Date
    let endDate: Date
    
    var mostCommonTags: [(String, Int)] {
        commonTags.sorted { $0.value > $1.value }
            .prefix(5)
            .map { ($0.key, $0.value) }
    }
    
    var entriesPerDay: Double {
        let days = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 1
        return Double(totalEntries) / Double(days)
    }
}
