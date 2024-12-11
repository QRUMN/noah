import SwiftUI

struct CBTExerciseView: View {
    @StateObject private var viewModel = TherapyToolsViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep = 0
    @State private var thoughtRecord = ThoughtRecord(
        id: UUID().uuidString,
        date: Date(),
        situation: "",
        automaticThoughts: "",
        emotions: [],
        emotionIntensities: [],
        evidenceFor: "",
        evidenceAgainst: "",
        balancedThought: "",
        newEmotionIntensities: []
    )
    @State private var selectedEmotion = ""
    @State private var emotionIntensity: Double = 5
    @State private var showingCompletion = false
    
    let emotions = ["Anxious", "Sad", "Angry", "Frustrated", "Guilty", "Ashamed", "Hopeless", "Worried"]
    
    var body: some View {
        NavigationView {
            VStack {
                // Progress Indicator
                ProgressView(value: Double(currentStep), total: 5)
                    .padding()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Step Content
                        switch currentStep {
                        case 0:
                            situationStep
                        case 1:
                            thoughtsStep
                        case 2:
                            emotionsStep
                        case 3:
                            evidenceStep
                        case 4:
                            balancedThoughtStep
                        default:
                            EmptyView()
                        }
                    }
                    .padding()
                }
                
                // Navigation Buttons
                HStack {
                    if currentStep > 0 {
                        Button("Previous") {
                            withAnimation {
                                currentStep -= 1
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Button(currentStep == 4 ? "Complete" : "Next") {
                        withAnimation {
                            if currentStep < 4 {
                                currentStep += 1
                            } else {
                                completeExercise()
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
            .navigationTitle("Thought Record")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingCompletion) {
                completionView
            }
        }
    }
    
    private var situationStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Step 1: Describe the Situation")
                .font(.headline)
            
            Text("What happened? When and where did it occur? Who was involved?")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            TextEditor(text: $thoughtRecord.situation)
                .frame(height: 150)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.2))
                )
        }
    }
    
    private var thoughtsStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Step 2: Automatic Thoughts")
                .font(.headline)
            
            Text("What went through your mind? What thoughts or images came up?")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            TextEditor(text: $thoughtRecord.automaticThoughts)
                .frame(height: 150)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.2))
                )
        }
    }
    
    private var emotionsStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Step 3: Emotions & Intensity")
                .font(.headline)
            
            Text("What emotions did you feel? Rate their intensity (0-10)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Picker("Emotion", selection: $selectedEmotion) {
                    ForEach(emotions, id: \.self) { emotion in
                        Text(emotion).tag(emotion)
                    }
                }
                
                Button(action: addEmotion) {
                    Image(systemName: "plus.circle.fill")
                }
            }
            
            Slider(value: $emotionIntensity, in: 0...10, step: 1)
            
            ForEach(Array(zip(thoughtRecord.emotions.indices, thoughtRecord.emotions)), id: \.0) { index, emotion in
                HStack {
                    Text(emotion)
                    Spacer()
                    Text("Intensity: \(thoughtRecord.emotionIntensities[index])")
                    Button(action: { removeEmotion(at: index) }) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.red)
                    }
                }
            }
        }
    }
    
    private var evidenceStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Step 4: Examine the Evidence")
                .font(.headline)
            
            Group {
                Text("Evidence For")
                    .font(.subheadline)
                TextEditor(text: $thoughtRecord.evidenceFor)
                    .frame(height: 100)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.2))
                    )
                
                Text("Evidence Against")
                    .font(.subheadline)
                TextEditor(text: $thoughtRecord.evidenceAgainst)
                    .frame(height: 100)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.2))
                    )
            }
        }
    }
    
    private var balancedThoughtStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Step 5: Balanced Thought")
                .font(.headline)
            
            Text("Based on the evidence, what's a more balanced view?")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            TextEditor(text: $thoughtRecord.balancedThought)
                .frame(height: 150)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.2))
                )
            
            Text("Rate your emotions now (0-10)")
                .font(.subheadline)
            
            ForEach(Array(zip(thoughtRecord.emotions.indices, thoughtRecord.emotions)), id: \.0) { index, emotion in
                HStack {
                    Text(emotion)
                    Slider(value: .init(
                        get: { Double(thoughtRecord.newEmotionIntensities[index]) },
                        set: { thoughtRecord.newEmotionIntensities[index] = Int($0) }
                    ), in: 0...10, step: 1)
                    Text("\(thoughtRecord.newEmotionIntensities[index])")
                }
            }
        }
    }
    
    private var completionView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("Great job!")
                .font(.title)
            
            Text("You've completed the thought record. Your emotional intensity decreased by \(thoughtRecord.emotionalChange) points!")
                .multilineTextAlignment(.center)
            
            if let strategy = viewModel.suggestedCopingStrategy {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Suggested Coping Strategy")
                        .font(.headline)
                    
                    Text(strategy.title)
                        .font(.subheadline)
                    
                    Text(strategy.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
            }
            
            Button("Done") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .padding(.top)
        }
        .padding()
    }
    
    private func addEmotion() {
        guard !selectedEmotion.isEmpty else { return }
        thoughtRecord.emotions.append(selectedEmotion)
        thoughtRecord.emotionIntensities.append(Int(emotionIntensity))
        thoughtRecord.newEmotionIntensities.append(Int(emotionIntensity))
        selectedEmotion = ""
        emotionIntensity = 5
    }
    
    private func removeEmotion(at index: Int) {
        thoughtRecord.emotions.remove(at: index)
        thoughtRecord.emotionIntensities.remove(at: index)
        thoughtRecord.newEmotionIntensities.remove(at: index)
    }
    
    private func completeExercise() {
        Task {
            await viewModel.saveThoughtRecord(thoughtRecord)
            viewModel.generateCopingStrategy(situation: thoughtRecord.situation, mood: thoughtRecord.emotions.first ?? "")
            showingCompletion = true
        }
    }
}

#Preview {
    CBTExerciseView()
}
