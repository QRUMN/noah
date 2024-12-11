import SwiftUI
import FirebaseAuth

@MainActor
class DailyCheckInViewModel: ObservableObject {
    @Published var responses: [CheckIn.Question: Int] = [:]
    @Published var notes: String = ""
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage: String?
    
    private let mentalHealthService = MentalHealthService()
    
    var timeBasedGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }
    
    func submitCheckIn() async -> Bool {
        guard let userId = Auth.auth().currentUser?.uid else {
            showError(message: "Please sign in to continue")
            return false
        }
        
        // Ensure all questions are answered
        let unansweredQuestions = CheckIn.Question.allCases.filter { responses[$0] == nil }
        if !unansweredQuestions.isEmpty {
            showError(message: "Please answer all questions")
            return false
        }
        
        isLoading = true
        defer { isLoading = false }
        
        // Create check-in object
        let checkIn = CheckIn(
            id: UUID().uuidString,
            userId: userId,
            timestamp: Date(),
            responses: responses,
            notes: notes.isEmpty ? nil : notes,
            flags: determineFlags()
        )
        
        do {
            try await mentalHealthService.saveCheckIn(checkIn)
            await analyzeMentalState()
            return true
        } catch {
            showError(message: "Failed to save check-in")
            return false
        }
    }
    
    private func determineFlags() -> [CheckIn.Flag] {
        var flags: [CheckIn.Flag] = []
        
        // Calculate average response
        let average = Double(responses.values.reduce(0, +)) / Double(responses.count)
        
        // Check for concerning patterns
        if average <= 2 {
            flags.append(.needsAttention)
        }
        
        // Check for very low scores in critical areas
        if responses[.mood] ?? 0 <= 2 || responses[.anxiety] ?? 0 <= 2 {
            flags.append(.needsAttention)
        }
        
        // Add crisis flag for extremely low scores
        if responses.values.contains(where: { $0 == 1 }) {
            flags.append(.crisis)
        }
        
        return flags
    }
    
    private func analyzeMentalState() async {
        // Get previous check-ins for comparison
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        do {
            let recentCheckIns = try await mentalHealthService.getCheckIns(forUserId: userId, limit: 7)
            var flags = Set<CheckIn.Flag>()
            
            // Analyze trends
            if recentCheckIns.count >= 3 {
                let recentAverages = recentCheckIns.prefix(3).map { checkIn in
                    Double(checkIn.responses.values.reduce(0, +)) / Double(checkIn.responses.count)
                }
                
                if recentAverages.allSatisfy({ $0 < 3 }) {
                    flags.insert(.declining)
                } else if recentAverages.allSatisfy({ $0 > 3 }) {
                    flags.insert(.improvement)
                } else {
                    flags.insert(.consistent)
                }
            }
            
            // Update the latest check-in with trend flags
            if let latestCheckIn = recentCheckIns.first {
                var updatedCheckIn = latestCheckIn
                updatedCheckIn.flags = Array(flags)
                try await mentalHealthService.saveCheckIn(updatedCheckIn)
            }
        } catch {
            print("Failed to analyze mental state: \(error.localizedDescription)")
        }
    }
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}
