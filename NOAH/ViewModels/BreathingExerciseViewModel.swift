import SwiftUI
import FirebaseAuth

@MainActor
class BreathingExerciseViewModel: ObservableObject {
    enum Phase: String {
        case inhale = "Inhale"
        case hold = "Hold"
        case exhale = "Exhale"
        case rest = "Rest"
    }
    
    // Published properties
    @Published var currentPhase: Phase = .inhale
    @Published var progress: Double = 0
    @Published var animationScale: Double = 1.0
    @Published var isActive = false
    @Published var completedCycles = 0
    @Published var totalSeconds = 0
    @Published var showStats = false
    
    // Timer properties
    private var timer: Timer?
    private var phaseStartTime: Date?
    private let phaseDurations: [Phase: Double] = [
        .inhale: 4,
        .hold: 7,
        .exhale: 8,
        .rest: 1
    ]
    
    // Computed properties
    var instruction: String {
        switch currentPhase {
        case .inhale: return "Breathe in through your nose"
        case .hold: return "Hold your breath"
        case .exhale: return "Exhale through your mouth"
        case .rest: return "Prepare for next cycle"
        }
    }
    
    var timeRemaining: String {
        guard let startTime = phaseStartTime, isActive else { return "0:00" }
        let elapsed = Date().timeIntervalSince(startTime)
        let remaining = max(0, phaseDurations[currentPhase, default: 0] - elapsed)
        return String(format: "%.1f", remaining)
    }
    
    var formattedTotalTime: String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // Exercise control methods
    func toggleExercise() {
        isActive.toggle()
        
        if isActive {
            startPhase()
        } else {
            timer?.invalidate()
            timer = nil
        }
    }
    
    func resetExercise() {
        timer?.invalidate()
        timer = nil
        isActive = false
        currentPhase = .inhale
        progress = 0
        animationScale = 1.0
        completedCycles = 0
        totalSeconds = 0
        showStats = false
        phaseStartTime = nil
    }
    
    private func startPhase() {
        phaseStartTime = Date()
        
        // Set up animations
        withAnimation(.easeInOut(duration: phaseDurations[currentPhase, default: 0])) {
            progress = 1.0
            
            switch currentPhase {
            case .inhale:
                animationScale = 1.5
            case .hold:
                animationScale = 1.5
            case .exhale:
                animationScale = 1.0
            case .rest:
                animationScale = 1.0
            }
        }
        
        // Create timer for phase transition
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateProgress()
        }
    }
    
    private func updateProgress() {
        guard let startTime = phaseStartTime,
              let phaseDuration = phaseDurations[currentPhase] else { return }
        
        let elapsed = Date().timeIntervalSince(startTime)
        progress = min(1.0, elapsed / phaseDuration)
        
        if elapsed >= phaseDuration {
            moveToNextPhase()
        }
    }
    
    private func moveToNextPhase() {
        timer?.invalidate()
        timer = nil
        progress = 0
        
        let phases: [Phase] = [.inhale, .hold, .exhale, .rest]
        guard let currentIndex = phases.firstIndex(of: currentPhase) else { return }
        
        let nextIndex = (currentIndex + 1) % phases.count
        currentPhase = phases[nextIndex]
        
        if currentPhase == .inhale {
            completedCycles += 1
        }
        
        if isActive {
            startPhase()
        }
        
        totalSeconds += Int(phaseDurations[currentPhase] ?? 0)
    }
    
    func cleanup() {
        timer?.invalidate()
        timer = nil
    }
    
    func saveExercise() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        Task {
            let exercise = TherapeuticExercise(
                id: UUID().uuidString,
                userId: userId,
                type: .breathing,
                duration: totalSeconds,
                completedCycles: completedCycles,
                timestamp: Date()
            )
            
            do {
                try await saveTherapeuticExercise(exercise)
            } catch {
                print("Failed to save breathing exercise: \(error.localizedDescription)")
            }
        }
    }
    
    private func saveTherapeuticExercise(_ exercise: TherapeuticExercise) async throws {
        let db = Firestore.firestore()
        try await db.collection("therapeuticExercises")
            .document(exercise.id)
            .setData(exercise.dictionary)
    }
}

struct TherapeuticExercise {
    let id: String
    let userId: String
    let type: ExerciseType
    let duration: Int
    let completedCycles: Int
    let timestamp: Date
    
    enum ExerciseType: String {
        case breathing = "Breathing"
        case meditation = "Meditation"
        case mindfulness = "Mindfulness"
    }
    
    var dictionary: [String: Any] {
        [
            "id": id,
            "userId": userId,
            "type": type.rawValue,
            "duration": duration,
            "completedCycles": completedCycles,
            "timestamp": timestamp
        ]
    }
}
