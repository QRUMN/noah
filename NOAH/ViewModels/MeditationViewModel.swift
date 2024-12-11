import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import AVFoundation

@MainActor
class MeditationViewModel: ObservableObject {
    @Published var sessions: [MeditationSession] = []
    @Published var filteredSessions: [MeditationSession] = []
    @Published var selectedCategory: MeditationSession.Category?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Audio player properties
    @Published var isPlaying = false
    @Published var progress: Double = 0
    @Published var currentTime: TimeInterval = 0
    private var audioPlayer: AVPlayer?
    private var timeObserver: Any?
    
    init() {
        Task {
            await loadSessions()
        }
    }
    
    func loadSessions() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let db = Firestore.firestore()
            let snapshot = try await db.collection("meditations").getDocuments()
            
            sessions = snapshot.documents.compactMap { document -> MeditationSession? in
                guard let title = document.data()["title"] as? String,
                      let description = document.data()["description"] as? String,
                      let duration = document.data()["duration"] as? TimeInterval,
                      let categoryRaw = document.data()["category"] as? String,
                      let category = MeditationSession.Category(rawValue: categoryRaw),
                      let audioURLString = document.data()["audioURL"] as? String,
                      let imageURLString = document.data()["imageURL"] as? String,
                      let tags = document.data()["tags"] as? [String],
                      let audioURL = URL(string: audioURLString),
                      let imageURL = URL(string: imageURLString) else {
                    return nil
                }
                
                return MeditationSession(
                    id: document.documentID,
                    title: title,
                    description: description,
                    duration: duration,
                    category: category,
                    audioURL: audioURL,
                    imageURL: imageURL,
                    tags: tags
                )
            }
            
            filterSessions()
        } catch {
            errorMessage = "Failed to load meditation sessions: \(error.localizedDescription)"
        }
    }
    
    func filterSessions() {
        if let category = selectedCategory {
            filteredSessions = sessions.filter { $0.category == category }
        } else {
            filteredSessions = sessions
        }
    }
    
    func selectCategory(_ category: MeditationSession.Category?) {
        selectedCategory = category
        filterSessions()
    }
    
    func startSession(_ session: MeditationSession) {
        // Stop any existing audio
        stopAudio()
        
        // Create and configure audio player
        let playerItem = AVPlayerItem(url: session.audioURL)
        audioPlayer = AVPlayer(playerItem: playerItem)
        
        // Add time observer
        timeObserver = audioPlayer?.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            guard let self = self,
                  let duration = self.audioPlayer?.currentItem?.duration.seconds,
                  duration.isFinite else { return }
            
            self.currentTime = time.seconds
            self.progress = time.seconds / duration
            
            if time.seconds >= duration {
                self.completeSession(session)
            }
        }
        
        // Start playing
        audioPlayer?.play()
        isPlaying = true
    }
    
    func togglePlayPause() {
        if isPlaying {
            audioPlayer?.pause()
        } else {
            audioPlayer?.play()
        }
        isPlaying.toggle()
    }
    
    func stopAudio() {
        audioPlayer?.pause()
        if let timeObserver = timeObserver {
            audioPlayer?.removeTimeObserver(timeObserver)
        }
        audioPlayer = nil
        isPlaying = false
        progress = 0
        currentTime = 0
    }
    
    func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        audioPlayer?.seek(to: cmTime)
    }
    
    func completeSession(_ session: MeditationSession) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        Task {
            let progress = MeditationProgress(
                id: UUID().uuidString,
                userId: userId,
                sessionId: session.id,
                startTime: Date().addingTimeInterval(-session.duration),
                duration: session.duration,
                completed: true
            )
            
            do {
                try await saveMeditationProgress(progress)
            } catch {
                errorMessage = "Failed to save meditation progress: \(error.localizedDescription)"
            }
        }
    }
    
    private func saveMeditationProgress(_ progress: MeditationProgress) async throws {
        let db = Firestore.firestore()
        try await db.collection("meditationProgress")
            .document(progress.id)
            .setData(progress.dictionary)
    }
    
    deinit {
        stopAudio()
    }
}
