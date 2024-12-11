import SwiftUI
import FirebaseAuth
import FirebaseFirestore

@MainActor
class JournalViewModel: ObservableObject {
    @Published var entries: [JournalEntry] = []
    @Published var prompts: [JournalPrompt] = []
    @Published var selectedPrompt: JournalPrompt?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var selectedMood: JournalEntry.Mood?
    @Published var selectedTags: Set<String> = []
    
    private var listener: ListenerRegistration?
    
    init() {
        loadPrompts()
        setupEntriesListener()
    }
    
    private func setupEntriesListener() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        listener = db.collection("journalEntries")
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                self?.entries = documents.compactMap(JournalEntry.from)
            }
    }
    
    private func loadPrompts() {
        // For now, use sample prompts
        prompts = JournalPrompt.samples
    }
    
    var filteredEntries: [JournalEntry] {
        entries.filter { entry in
            let matchesSearch = searchText.isEmpty ||
                entry.title.localizedCaseInsensitiveContains(searchText) ||
                entry.content.localizedCaseInsensitiveContains(searchText)
            
            let matchesMood = selectedMood == nil || entry.mood == selectedMood
            
            let matchesTags = selectedTags.isEmpty ||
                !selectedTags.isDisjoint(with: Set(entry.tags))
            
            return matchesSearch && matchesMood && matchesTags
        }
    }
    
    func createEntry(title: String, content: String, mood: JournalEntry.Mood, tags: [String]) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "JournalError", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let entry = JournalEntry(
            id: UUID().uuidString,
            userId: userId,
            title: title,
            content: content,
            mood: mood,
            prompt: selectedPrompt,
            tags: tags,
            createdAt: Date(),
            updatedAt: Date(),
            isFavorite: false
        )
        
        let db = Firestore.firestore()
        try await db.collection("journalEntries")
            .document(entry.id)
            .setData(entry.dictionary)
    }
    
    func updateEntry(_ entry: JournalEntry, title: String, content: String, mood: JournalEntry.Mood, tags: [String]) async throws {
        let updatedEntry = JournalEntry(
            id: entry.id,
            userId: entry.userId,
            title: title,
            content: content,
            mood: mood,
            prompt: entry.prompt,
            tags: tags,
            createdAt: entry.createdAt,
            updatedAt: Date(),
            isFavorite: entry.isFavorite
        )
        
        let db = Firestore.firestore()
        try await db.collection("journalEntries")
            .document(entry.id)
            .setData(updatedEntry.dictionary)
    }
    
    func toggleFavorite(_ entry: JournalEntry) async throws {
        let db = Firestore.firestore()
        try await db.collection("journalEntries")
            .document(entry.id)
            .updateData(["isFavorite": !entry.isFavorite])
    }
    
    func deleteEntry(_ entry: JournalEntry) async throws {
        let db = Firestore.firestore()
        try await db.collection("journalEntries")
            .document(entry.id)
            .delete()
    }
    
    func selectRandomPrompt(for category: JournalPrompt.Category? = nil) {
        let filteredPrompts = category == nil ?
            prompts :
            prompts.filter { $0.category == category }
        
        selectedPrompt = filteredPrompts.randomElement()
    }
    
    deinit {
        listener?.remove()
    }
}
