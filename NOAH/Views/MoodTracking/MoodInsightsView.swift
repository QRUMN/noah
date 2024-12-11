import SwiftUI
import Charts

struct MoodInsightsView: View {
    @StateObject private var viewModel = MoodTrackingViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Mood Summary Card
                if let summary = viewModel.moodSummary {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Your Mood Summary")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Average Mood")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text(String(format: "%.1f", summary.averageMoodScore))
                                    .font(.title)
                                    .fontWeight(.bold)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("Most Common")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text(summary.dominantEmotions.first?.key ?? "N/A")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                
                // Weekly Mood Chart
                VStack(alignment: .leading, spacing: 16) {
                    Text("Weekly Mood Trends")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if !viewModel.weeklyMoodEntries.isEmpty {
                        Chart(viewModel.weeklyMoodEntries) { entry in
                            LineMark(
                                x: .value("Date", entry.timestamp),
                                y: .value("Mood", entry.moodScore)
                            )
                            .foregroundStyle(Color.blue)
                            
                            PointMark(
                                x: .value("Date", entry.timestamp),
                                y: .value("Mood", entry.moodScore)
                            )
                            .foregroundStyle(Color.blue)
                        }
                        .frame(height: 200)
                    } else {
                        Text("No mood data available")
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                
                // Insights and Patterns
                if let summary = viewModel.moodSummary {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Insights")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        ForEach(summary.insightMessages, id: \.self) { insight in
                            HStack(spacing: 12) {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundColor(.yellow)
                                Text(insight)
                                    .font(.subheadline)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Journal Prompts
                VStack(alignment: .leading, spacing: 16) {
                    Text("Suggested Journal Prompts")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    ForEach(viewModel.suggestedPrompts, id: \.self) { prompt in
                        NavigationLink(destination: JournalEntryView(prompt: prompt)) {
                            HStack {
                                Text(prompt)
                                    .font(.subheadline)
                                    .multilineTextAlignment(.leading)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle("Mood Insights")
        .task {
            await viewModel.fetchMoodAnalytics()
            viewModel.generateJournalPrompts()
        }
    }
}

struct JournalEntryView: View {
    @StateObject private var viewModel = MoodTrackingViewModel()
    @Environment(\.dismiss) private var dismiss
    let prompt: String
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text(prompt)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("How are you feeling before writing?")
                        .font(.headline)
                    
                    HStack {
                        ForEach(1...5, id: \.self) { score in
                            Button(action: { viewModel.moodBeforeJournaling = score }) {
                                Circle()
                                    .fill(viewModel.moodBeforeJournaling == score ? Color.blue : Color(.systemGray4))
                                    .frame(width: 40, height: 40)
                                    .overlay(Text("\(score)").foregroundColor(.white))
                            }
                        }
                    }
                }
                .padding()
                
                TextEditor(text: $viewModel.journalContent)
                    .frame(height: 200)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("How are you feeling after writing?")
                        .font(.headline)
                    
                    HStack {
                        ForEach(1...5, id: \.self) { score in
                            Button(action: { viewModel.moodAfterJournaling = score }) {
                                Circle()
                                    .fill(viewModel.moodAfterJournaling == score ? Color.blue : Color(.systemGray4))
                                    .frame(width: 40, height: 40)
                                    .overlay(Text("\(score)").foregroundColor(.white))
                            }
                        }
                    }
                }
                .padding()
            }
            .padding()
        }
        .navigationTitle("Journal Entry")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    Task {
                        if await viewModel.saveJournalEntry() {
                            dismiss()
                        }
                    }
                }
                .disabled(viewModel.journalContent.isEmpty)
            }
        }
        .onAppear {
            viewModel.selectedPrompt = prompt
        }
    }
}
