import SwiftUI
import FirebaseAuth

struct MoodTrackingView: View {
    @StateObject private var viewModel = MoodTrackingViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Mood Selection
                    VStack(alignment: .leading) {
                        Text("How are you feeling?")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 80))
                        ], spacing: 15) {
                            ForEach(MoodEntry.Mood.allCases, id: \.self) { mood in
                                MoodButton(
                                    mood: mood,
                                    isSelected: viewModel.selectedMood == mood,
                                    action: { viewModel.selectedMood = mood }
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Intensity Slider
                    VStack(alignment: .leading) {
                        Text("How intense is this feeling?")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        HStack {
                            Text("Mild")
                                .foregroundColor(.secondary)
                            Slider(value: $viewModel.intensity, in: 1...5, step: 1)
                            Text("Strong")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Activities
                    VStack(alignment: .leading) {
                        Text("What have you been doing?")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 100))
                        ], spacing: 12) {
                            ForEach(MoodEntry.Activity.allCases, id: \.self) { activity in
                                ActivityButton(
                                    activity: activity,
                                    isSelected: viewModel.selectedActivities.contains(activity),
                                    action: { viewModel.toggleActivity(activity) }
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Notes
                    VStack(alignment: .leading) {
                        Text("Any additional notes?")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        TextEditor(text: $viewModel.notes)
                            .frame(height: 100)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    
                    // Tags
                    VStack(alignment: .leading) {
                        Text("Tags")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        TextField("Add tags (comma separated)", text: $viewModel.tagInput)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onSubmit {
                                viewModel.addTags()
                            }
                        
                        FlowLayout(spacing: 8) {
                            ForEach(viewModel.tags, id: \.self) { tag in
                                TagView(tag: tag) {
                                    viewModel.removeTag(tag)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Track Your Mood")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            if await viewModel.saveMoodEntry() {
                                dismiss()
                            }
                        }
                    }
                    .disabled(!viewModel.isValid)
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred")
            }
        }
    }
}

struct MoodButton: View {
    let mood: MoodEntry.Mood
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Text(mood.icon)
                    .font(.system(size: 32))
                Text(mood.rawValue)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color(mood.color).opacity(0.3) : Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ActivityButton: View {
    let activity: MoodEntry.Activity
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: activity.icon)
                    .font(.system(size: 24))
                Text(activity.rawValue)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color.blue.opacity(0.2) : Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TagView: View {
    let tag: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(tag)
                .font(.caption)
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemGray5))
        .cornerRadius(12)
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: result.frames[index].origin, proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var frames: [CGRect] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let viewSize = subview.sizeThatFits(.unspecified)
                
                if currentX + viewSize.width > maxWidth {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                frames.append(CGRect(x: currentX, y: currentY, width: viewSize.width, height: viewSize.height))
                lineHeight = max(lineHeight, viewSize.height)
                currentX += viewSize.width + spacing
                
                size.width = max(size.width, currentX)
            }
            
            size.height = currentY + lineHeight
        }
    }
}
