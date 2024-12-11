import SwiftUI

struct JournalEntryView: View {
    let entry: JournalEntry
    @StateObject private var viewModel = JournalViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteAlert = false
    @State private var showingEditSheet = false
    @State private var isEditing = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Text(entry.mood.emoji)
                        .font(.system(size: 44))
                    
                    VStack(alignment: .leading) {
                        Text(entry.title)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(formatDate(entry.createdAt))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemBackground))
                
                // Prompt if present
                if let prompt = entry.prompt {
                    PromptView(prompt: prompt)
                        .padding(.horizontal)
                }
                
                // Content
                Text(entry.content)
                    .font(.body)
                    .padding(.horizontal)
                
                // Tags
                if !entry.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(entry.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color(.systemGray6))
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        toggleFavorite()
                    } label: {
                        Label(
                            entry.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                            systemImage: entry.isFavorite ? "star.fill" : "star"
                        )
                    }
                    
                    Button {
                        showingEditSheet = true
                    } label: {
                        Label("Edit Entry", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("Delete Entry", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            NavigationView {
                EditJournalEntryView(entry: entry)
            }
        }
        .alert("Delete Entry", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteEntry()
            }
        } message: {
            Text("Are you sure you want to delete this journal entry? This action cannot be undone.")
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func toggleFavorite() {
        Task {
            do {
                try await viewModel.toggleFavorite(entry)
            } catch {
                viewModel.errorMessage = error.localizedDescription
            }
        }
    }
    
    private func deleteEntry() {
        Task {
            do {
                try await viewModel.deleteEntry(entry)
                dismiss()
            } catch {
                viewModel.errorMessage = error.localizedDescription
            }
        }
    }
}

struct EditJournalEntryView: View {
    let entry: JournalEntry
    @StateObject private var viewModel = JournalViewModel()
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?
    
    @State private var title: String
    @State private var content: String
    @State private var selectedMood: JournalEntry.Mood
    @State private var tags: [String]
    @State private var isSaving = false
    
    enum Field {
        case title, content
    }
    
    init(entry: JournalEntry) {
        self.entry = entry
        _title = State(initialValue: entry.title)
        _content = State(initialValue: entry.content)
        _selectedMood = State(initialValue: entry.mood)
        _tags = State(initialValue: entry.tags)
    }
    
    var body: some View {
        Form {
            Section {
                TextField("Title", text: $title)
                    .focused($focusedField, equals: .title)
                
                MoodPicker(selectedMood: $selectedMood)
            }
            
            Section {
                if let prompt = entry.prompt {
                    PromptView(prompt: prompt)
                }
                
                TextEditor(text: $content)
                    .focused($focusedField, equals: .content)
                    .frame(minHeight: 200)
            }
            
            Section {
                TagEditor(tags: $tags)
            } header: {
                Text("Tags")
            }
        }
        .navigationTitle("Edit Entry")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    save()
                }
                .disabled(title.isEmpty || content.isEmpty || isSaving)
            }
            
            ToolbarItem(placement: .keyboard) {
                HStack {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
                    }
                }
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
    }
    
    private func save() {
        isSaving = true
        
        Task {
            do {
                try await viewModel.updateEntry(
                    entry,
                    title: title,
                    content: content,
                    mood: selectedMood,
                    tags: tags
                )
                dismiss()
            } catch {
                viewModel.errorMessage = error.localizedDescription
            }
            isSaving = false
        }
    }
}

#Preview {
    NavigationView {
        JournalEntryView(entry: JournalEntry(
            id: UUID().uuidString,
            userId: "preview",
            title: "My First Entry",
            content: "This is a preview of a journal entry with some content to show how it looks.",
            mood: .joyful,
            prompt: JournalPrompt.samples[0],
            tags: ["personal", "reflection"],
            createdAt: Date(),
            updatedAt: Date(),
            isFavorite: true
        ))
    }
}
