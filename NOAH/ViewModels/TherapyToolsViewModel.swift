import Foundation
import FirebaseFirestore
import Combine

@MainActor
class TherapyToolsViewModel: ObservableObject {
    private let db = Firestore.firestore()
    
    @Published var exercises: [TherapyExercise] = []
    @Published var thoughtRecords: [ThoughtRecord] = []
    @Published var currentMoodPattern: MoodPattern?
    @Published var suggestedCopingStrategy: CopingStrategy?
    @Published var currentJournalPrompt: JournalPrompt?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Exercise Management
    
    func fetchExercises() async {
        isLoading = true
        do {
            let snapshot = try await db.collection("exercises").getDocuments()
            exercises = snapshot.documents.compactMap { document in
                try? document.data(as: TherapyExercise.self)
            }
        } catch {
            errorMessage = "Failed to fetch exercises: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    func completeExercise(_ exercise: TherapyExercise) async {
        do {
            var updatedExercise = exercise
            updatedExercise.isCompleted = true
            try await db.collection("exercises").document(exercise.id).setData(from: updatedExercise)
            
            if let index = exercises.firstIndex(where: { $0.id == exercise.id }) {
                exercises[index] = updatedExercise
            }
        } catch {
            errorMessage = "Failed to update exercise: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Thought Record Management
    
    func saveThoughtRecord(_ record: ThoughtRecord) async {
        do {
            try await db.collection("thoughtRecords").document(record.id).setData(from: record)
            thoughtRecords.append(record)
            
            // Generate new mood pattern analysis
            await analyzeMoodPatterns()
        } catch {
            errorMessage = "Failed to save thought record: \(error.localizedDescription)"
        }
    }
    
    func fetchThoughtRecords() async {
        isLoading = true
        do {
            let snapshot = try await db.collection("thoughtRecords")
                .order(by: "date", descending: true)
                .limit(to: 10)
                .getDocuments()
            
            thoughtRecords = snapshot.documents.compactMap { document in
                try? document.data(as: ThoughtRecord.self)
            }
            
            // Generate mood pattern analysis
            await analyzeMoodPatterns()
        } catch {
            errorMessage = "Failed to fetch thought records: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    // MARK: - AI-Powered Features
    
    func analyzeMoodPatterns() async {
        currentMoodPattern = TherapyResponseGenerator.analyzeMoodPatterns(entries: thoughtRecords)
    }
    
    func generateCopingStrategy(situation: String, mood: String) {
        suggestedCopingStrategy = TherapyResponseGenerator.generateCopingStrategy(for: situation, mood: mood)
    }
    
    func generateSmartJournalPrompt(mood: String) {
        currentJournalPrompt = TherapyResponseGenerator.generateJournalPrompt(based: mood)
    }
    
    // MARK: - Helper Methods
    
    private func getMockExercises() -> [TherapyExercise] {
        return [
            TherapyExercise(
                id: UUID().uuidString,
                type: .cbt,
                title: "Challenging Negative Thoughts",
                description: "Learn to identify and challenge negative thought patterns",
                duration: 15,
                difficulty: "Intermediate",
                steps: [
                    "Identify the negative thought",
                    "Rate your belief in the thought (0-100%)",
                    "Find evidence for and against",
                    "Generate a balanced thought",
                    "Rate your belief in the balanced thought"
                ],
                tips: [
                    "Be specific about the thought",
                    "Consider all evidence objectively",
                    "Focus on facts rather than emotions"
                ],
                category: "Cognitive Restructuring",
                isCompleted: false,
                recommendedFrequency: "Daily"
            ),
            TherapyExercise(
                id: UUID().uuidString,
                type: .mindfulness,
                title: "Body Scan Meditation",
                description: "A guided meditation focusing on body awareness",
                duration: 10,
                difficulty: "Beginner",
                steps: [
                    "Find a comfortable position",
                    "Close your eyes",
                    "Focus on your breath",
                    "Scan your body from head to toe",
                    "Notice any sensations without judgment"
                ],
                tips: [
                    "Take your time",
                    "Return focus gently when mind wanders",
                    "Practice regularly for best results"
                ],
                category: "Meditation",
                isCompleted: false,
                recommendedFrequency: "Daily"
            )
        ]
    }
}
