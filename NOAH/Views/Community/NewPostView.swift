import SwiftUI

struct NewPostView: View {
    let groupId: String
    @StateObject private var viewModel = CommunityViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var content = ""
    @State private var selectedType: PostType = .discussion
    @State private var isAnonymous = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Post Type")) {
                    Picker("Type", selection: $selectedType) {
                        ForEach(PostType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Content")) {
                    TextField("Title", text: $title)
                    TextEditor(text: $content)
                        .frame(minHeight: 100)
                }
                
                Section {
                    Toggle("Post Anonymously", isOn: $isAnonymous)
                }
                
                Section(footer: Text("Your post will be visible to all group members")) {
                    Button(action: submitPost) {
                        Text("Post")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                            .padding()
                            .background(isValid ? Color.accentColor : Color.gray)
                            .cornerRadius(8)
                    }
                    .disabled(!isValid)
                }
            }
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private var isValid: Bool {
        !title.isEmpty && !content.isEmpty
    }
    
    private func submitPost() {
        Task {
            do {
                await viewModel.createPost(
                    groupId: groupId,
                    type: selectedType,
                    title: title,
                    content: content,
                    isAnonymous: isAnonymous
                )
                dismiss()
            } catch {
                alertMessage = error.localizedDescription
                showingAlert = true
            }
        }
    }
}

#Preview {
    NewPostView(groupId: "test-group")
}
