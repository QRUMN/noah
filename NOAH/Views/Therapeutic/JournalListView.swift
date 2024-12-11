import SwiftUI

struct JournalListView: View {
    @StateObject private var viewModel = JournalViewModel()
    @State private var showingNewEntry = false
    @State private var showingFilters = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Search and Filter Bar
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search entries", text: $viewModel.searchText)
                }
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                Button(action: { showingFilters.toggle() }) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .foregroundColor(hasActiveFilters ? .blue : .primary)
                }
            }
            .padding()
            
            // Journal Entries List
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.filteredEntries.isEmpty {
                EmptyJournalView()
            } else {
                List {
                    ForEach(viewModel.filteredEntries) { entry in
                        NavigationLink(destination: JournalEntryView(entry: entry)) {
                            JournalEntryRow(entry: entry)
                        }
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    await viewModel.loadEntries()
                }
            }
        }
        .navigationTitle("Journal")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingNewEntry = true }) {
                    Image(systemName: "square.and.pencil")
                }
            }
        }
        .sheet(isPresented: $showingNewEntry) {
            NavigationView {
                NewJournalEntryView()
            }
        }
        .sheet(isPresented: $showingFilters) {
            JournalFiltersView(
                selectedMood: $viewModel.selectedMood,
                selectedTags: $viewModel.selectedTags
            )
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
    
    private var hasActiveFilters: Bool {
        viewModel.selectedMood != nil || !viewModel.selectedTags.isEmpty
    }
}

struct JournalEntryRow: View {
    let entry: JournalEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.mood.emoji)
                    .font(.title2)
                
                Text(entry.title)
                    .font(.headline)
                
                Spacer()
                
                if entry.isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                }
            }
            
            Text(entry.content)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            HStack {
                Text(formatDate(entry.createdAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                ForEach(entry.tags.prefix(2), id: \.self) { tag in
                    Text(tag)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray6))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct EmptyJournalView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("No Journal Entries")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Start writing about your thoughts and feelings.\nYour entries will appear here.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

struct JournalFiltersView: View {
    @Binding var selectedMood: JournalEntry.Mood?
    @Binding var selectedTags: Set<String>
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Mood") {
                    ForEach(JournalEntry.Mood.allCases, id: \.self) { mood in
                        Button(action: { toggleMood(mood) }) {
                            HStack {
                                Text(mood.emoji)
                                Text(mood.rawValue)
                                Spacer()
                                if selectedMood == mood {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
                
                Section("Common Tags") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(commonTags, id: \.self) { tag in
                                TagButton(
                                    tag: tag,
                                    isSelected: selectedTags.contains(tag)
                                ) {
                                    toggleTag(tag)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        selectedMood = nil
                        selectedTags.removeAll()
                    }
                }
            }
        }
    }
    
    private func toggleMood(_ mood: JournalEntry.Mood) {
        if selectedMood == mood {
            selectedMood = nil
        } else {
            selectedMood = mood
        }
    }
    
    private func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }
    
    private let commonTags = [
        "personal", "work", "health", "relationships",
        "goals", "gratitude", "challenges", "achievements"
    ]
}

struct TagButton: View {
    let tag: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(tag)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

#Preview {
    NavigationView {
        JournalListView()
    }
}
