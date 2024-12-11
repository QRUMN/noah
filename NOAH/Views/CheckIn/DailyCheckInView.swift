import SwiftUI

struct DailyCheckInView: View {
    @StateObject private var viewModel = DailyCheckInViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Welcome Message
                    VStack(alignment: .leading, spacing: 8) {
                        Text(viewModel.timeBasedGreeting)
                            .font(.title)
                            .fontWeight(.bold)
                        Text("Let's check in on how you're doing")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    // Questions
                    ForEach(Array(CheckIn.Question.allCases.enumerated()), id: \.element) { index, question in
                        QuestionView(
                            question: question,
                            response: viewModel.responses[question] ?? 3,
                            onChange: { value in
                                viewModel.responses[question] = value
                            }
                        )
                        
                        if index < CheckIn.Question.allCases.count - 1 {
                            Divider()
                                .padding(.horizontal)
                        }
                    }
                    
                    // Notes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Additional Notes")
                            .font(.headline)
                        
                        TextEditor(text: $viewModel.notes)
                            .frame(height: 100)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    
                    // Submit Button
                    Button(action: {
                        Task {
                            if await viewModel.submitCheckIn() {
                                dismiss()
                            }
                        }
                    }) {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Complete Check-in")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal)
                    .disabled(viewModel.isLoading)
                }
                .padding(.vertical)
            }
            .navigationTitle("Daily Check-in")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
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

struct QuestionView: View {
    let question: CheckIn.Question
    let response: Int
    let onChange: (Int) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(question.description)
                .font(.headline)
            
            VStack(spacing: 8) {
                HStack {
                    Text(question.lowDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(question.highDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 16) {
                    ForEach(1...5, id: \.self) { value in
                        Button(action: {
                            onChange(value)
                        }) {
                            Circle()
                                .fill(value <= response ? Color.blue : Color(.systemGray5))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Text("\(value)")
                                        .foregroundColor(value <= response ? .white : .primary)
                                )
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

#Preview {
    DailyCheckInView()
}
