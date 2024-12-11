import SwiftUI
import FirebaseAuth

@MainActor
class MoodTrackingViewModel: ObservableObject {
    @Published var selectedMood: MoodEntry.Mood?
    @Published var intensity: Double = 3
    @Published var selectedActivities: Set<MoodEntry.Activity> = []
    @Published var notes: String = ""
    @Published var tags: [String] = []
    @Published var tagInput: String = ""
    
    @Published var showError = false
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    // MARK: - Published Properties for Analytics
    @Published var moodSummary: MoodSummary?
    @Published var weeklyMoodEntries: [MoodEntry] = []
    @Published var journalEntries: [JournalEntry] = []
    @Published var suggestedPrompts: [String] = []
    
    // MARK: - Journal Properties
    @Published var journalContent: String = ""
    @Published var selectedPrompt: String?
    @Published var moodBeforeJournaling: Int?
    @Published var moodAfterJournaling: Int?
    
    private let mentalHealthService = MentalHealthService()
    
    var isValid: Bool {
        selectedMood != nil
    }
    
    func toggleActivity(_ activity: MoodEntry.Activity) {
        if selectedActivities.contains(activity) {
            selectedActivities.remove(activity)
        } else {
            selectedActivities.insert(activity)
        }
    }
    
    func addTags() {
        let newTags = tagInput
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        tags.append(contentsOf: newTags)
        tagInput = ""
    }
    
    func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
    
    func saveMoodEntry() async -> Bool {
        guard let selectedMood = selectedMood,
              let userId = Auth.auth().currentUser?.uid else {
            showError(message: "Please select a mood")
            return false
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let entry = MoodEntry(
            id: UUID().uuidString,
            userId: userId,
            mood: selectedMood,
            intensity: Int(intensity),
            activities: Array(selectedActivities),
            notes: notes.isEmpty ? nil : notes,
            timestamp: Date(),
            tags: tags
        )
        
        do {
            try await mentalHealthService.saveMoodEntry(entry)
            return true
        } catch {
            showError(message: "Failed to save mood entry")
            return false
        }
    }
    
    // MARK: - Analytics Methods
    func fetchMoodAnalytics() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let entries = try await mentalHealthService.fetchMoodEntries(for: userId, limit: 30)
            weeklyMoodEntries = entries
            moodSummary = MoodAnalytics.analyzeMoodTrends(entries)
        } catch {
            showError(message: "Failed to fetch mood analytics")
        }
    }
    
    // MARK: - Journaling Methods
    func saveJournalEntry() async -> Bool {
        guard let userId = Auth.auth().currentUser?.uid,
              !journalContent.isEmpty else {
            showError(message: "Journal content cannot be empty")
            return false
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let entry = JournalEntry(
            userId: userId,
            timestamp: Date(),
            content: journalContent,
            prompt: selectedPrompt,
            tags: tags,
            moodBefore: moodBeforeJournaling,
            moodAfter: moodAfterJournaling
        )
        
        do {
            try await mentalHealthService.saveJournalEntry(entry)
            clearJournalForm()
            return true
        } catch {
            showError(message: "Failed to save journal entry")
            return false
        }
    }
    
    func generateJournalPrompts() {
        guard let lastMoodEntry = weeklyMoodEntries.first else { return }
        suggestedPrompts = [JournalPromptGenerator.generatePrompt(based: lastMoodEntry)]
    }
    
    private func clearJournalForm() {
        journalContent = ""
        selectedPrompt = nil
        moodBeforeJournaling = nil
        moodAfterJournaling = nil
        tags.removeAll()
    }
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}
