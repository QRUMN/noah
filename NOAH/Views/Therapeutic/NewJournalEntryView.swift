import SwiftUI

struct NewJournalEntryView: View {
    @StateObject private var viewModel = JournalViewModel()
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?
    
    @State private var title = ""
    @State private var content = ""
    @State private var selectedMood: JournalEntry.Mood = .neutral
    @State private var tags: [String] = []
    @State private var showingPromptPicker = false
    @State private var showingTagEditor = false
    @State private var isSaving = false
    
    enum Field {
        case title, content
    }
    
    var body: some View {
        Form {
            Section {
                TextField("Title", text: $title)
                    .focused($focusedField, equals: .title)
                
                MoodPicker(selectedMood: $selectedMood)
            }
            
            Section {
                if let prompt = viewModel.selectedPrompt {
                    PromptView(prompt: prompt)
                }
                
                TextEditor(text: $content)
                    .focused($focusedField, equals: .content)
                    .frame(minHeight: 200)
            } header: {
                HStack {
                    Text("Content")
                    Spacer()
                    Button(viewModel.selectedPrompt == nil ? "Add Prompt" : "Change Prompt") {
                        showingPromptPicker = true
                    }
                }
            }
            
            Section {
                TagEditor(tags: $tags)
            } header: {
                Text("Tags")
            }
        }
        .navigationTitle("New Entry")
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
        .sheet(isPresented: $showingPromptPicker) {
            PromptPickerView(selectedPrompt: $viewModel.selectedPrompt)
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
                try await viewModel.createEntry(
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

struct MoodPicker: View {
    @Binding var selectedMood: JournalEntry.Mood
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(JournalEntry.Mood.allCases, id: \.self) { mood in
                    VStack {
                        Text(mood.emoji)
                            .font(.title)
                        Text(mood.rawValue)
                            .font(.caption)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(selectedMood == mood ? Color.blue.opacity(0.2) : Color.clear)
                    .cornerRadius(10)
                    .onTapGesture {
                        selectedMood = mood
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct PromptView: View {
    let prompt: JournalPrompt
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(prompt.text)
                .font(.headline)
            
            if !prompt.followUpQuestions.isEmpty {
                Text("Consider:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                ForEach(prompt.followUpQuestions, id: \.self) { question in
                    Text("• \(question)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct TagEditor: View {
    @Binding var tags: [String]
    @State private var newTag = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Tag Input
            HStack {
                TextField("Add tag", text: $newTag)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        addTag()
                    }
                
                Button(action: addTag) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            
            // Tag Cloud
            FlowLayout(spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    TagView(tag: tag) {
                        removeTag(tag)
                    }
                }
            }
        }
    }
    
    private func addTag() {
        let tag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        if !tag.isEmpty && !tags.contains(tag) {
            tags.append(tag)
            newTag = ""
        }
    }
    
    private func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
}

struct TagView: View {
    let tag: String
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(tag)
                .font(.subheadline)
            
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemGray6))
        .clipShape(Capsule())
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        return rows.reduce(CGSize.zero) { size, row in
            CGSize(
                width: max(size.width, row.width),
                height: size.height + row.height + (size.height > 0 ? spacing : 0)
            )
        }
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var origin = bounds.origin
        let rows = computeRows(proposal: proposal, subviews: subviews)
        
        for row in rows {
            origin.x = bounds.minX
            
            for item in row.items {
                let itemSize = item.sizeThatFits(.unspecified)
                item.place(at: origin, proposal: .unspecified)
                origin.x += itemSize.width + spacing
            }
            
            origin.y += row.height + spacing
        }
    }
    
    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var currentRow = Row()
        var x: CGFloat = 0
        
        for subview in subviews {
            let itemSize = subview.sizeThatFits(.unspecified)
            
            if x + itemSize.width > (proposal.width ?? .infinity) && !currentRow.items.isEmpty {
                rows.append(currentRow)
                currentRow = Row()
                x = 0
            }
            
            currentRow.items.append(subview)
            currentRow.width = x + itemSize.width
            currentRow.height = max(currentRow.height, itemSize.height)
            x += itemSize.width + spacing
        }
        
        if !currentRow.items.isEmpty {
            rows.append(currentRow)
        }
        
        return rows
    }
    
    struct Row {
        var items: [LayoutSubview] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }
}

struct PromptPickerView: View {
    @Binding var selectedPrompt: JournalPrompt?
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: JournalPrompt.Category?
    @StateObject private var viewModel = JournalViewModel()
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Button("Random Prompt") {
                        viewModel.selectRandomPrompt()
                        dismiss()
                    }
                }
                
                Section("Categories") {
                    ForEach(JournalPrompt.Category.allCases, id: \.self) { category in
                        Button {
                            viewModel.selectRandomPrompt(for: category)
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: category.systemImage)
                                    .foregroundColor(.blue)
                                Text(category.rawValue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Writing Prompts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        NewJournalEntryView()
    }
}
