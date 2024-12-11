import SwiftUI

struct TherapyToolsHomeView: View {
    @StateObject private var viewModel = TherapyToolsViewModel()
    @State private var selectedTool: TherapyToolType?
    @State private var showNewThoughtRecord = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // AI Insights Card
                    if let moodPattern = viewModel.currentMoodPattern {
                        MoodInsightsCard(moodPattern: moodPattern)
                    }
                    
                    // Tools Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(TherapyToolType.allCases, id: \.self) { tool in
                            TherapyToolCard(type: tool) {
                                selectedTool = tool
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Recent Activities
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Activities")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(viewModel.exercises.prefix(3)) { exercise in
                                    ExerciseCard(exercise: exercise)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Therapy Tools")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showNewThoughtRecord = true }) {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(item: $selectedTool) { tool in
                switch tool {
                case .cbt:
                    CBTExerciseView()
                case .mindfulness:
                    MindfulnessExerciseView()
                case .journalPrompts:
                    SmartJournalingView()
                case .moodAnalysis:
                    MoodAnalysisView()
                case .copingStrategies:
                    CopingStrategiesView()
                case .stressRelief:
                    StressReliefView()
                }
            }
            .sheet(isPresented: $showNewThoughtRecord) {
                NewThoughtRecordView()
            }
        }
        .task {
            await viewModel.fetchExercises()
            await viewModel.fetchThoughtRecords()
        }
    }
}

struct MoodInsightsCard: View {
    let moodPattern: MoodPattern
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI Insights")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Dominant Moods")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    ForEach(moodPattern.dominantMoods, id: \.self) { mood in
                        Text(mood)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
                
                Divider()
                
                Text("Suggestions")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                ForEach(moodPattern.suggestions, id: \.self) { suggestion in
                    Label(suggestion, systemImage: "lightbulb")
                        .font(.caption)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
}

struct TherapyToolCard: View {
    let type: TherapyToolType
    let action: () -> Void
    
    var icon: String {
        switch type {
        case .cbt: return "brain.head.profile"
        case .mindfulness: return "leaf"
        case .journalPrompts: return "text.book.closed"
        case .moodAnalysis: return "chart.bar"
        case .copingStrategies: return "heart.text.square"
        case .stressRelief: return "wind"
        }
    }
    
    var color: Color {
        switch type {
        case .cbt: return .blue
        case .mindfulness: return .green
        case .journalPrompts: return .purple
        case .moodAnalysis: return .orange
        case .copingStrategies: return .pink
        case .stressRelief: return .teal
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.largeTitle)
                    .foregroundColor(color)
                
                Text(type.rawValue)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 2)
        }
    }
}

struct ExerciseCard: View {
    let exercise: TherapyExercise
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(exercise.title)
                .font(.headline)
            
            Text(exercise.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            HStack {
                Label("\(exercise.duration)m", systemImage: "clock")
                Spacer()
                Text(exercise.difficulty)
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .frame(width: 200)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

#Preview {
    TherapyToolsHomeView()
}
