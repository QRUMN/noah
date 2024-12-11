import SwiftUI

struct BreathingExerciseView: View {
    @StateObject private var viewModel = BreathingExerciseViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Exercise Title and Progress
                    VStack(spacing: 10) {
                        Text(viewModel.currentPhase.rawValue)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text(viewModel.instruction)
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Breathing Circle Animation
                    ZStack {
                        // Outer circle
                        Circle()
                            .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                            .frame(width: geometry.size.width * 0.7,
                                   height: geometry.size.width * 0.7)
                        
                        // Animated circle
                        Circle()
                            .scale(viewModel.animationScale)
                            .foregroundColor(.blue.opacity(0.2))
                            .frame(width: geometry.size.width * 0.7,
                                   height: geometry.size.width * 0.7)
                        
                        // Progress circle
                        Circle()
                            .trim(from: 0, to: viewModel.progress)
                            .stroke(Color.blue, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .frame(width: geometry.size.width * 0.7,
                                   height: geometry.size.width * 0.7)
                            .rotationEffect(.degrees(-90))
                    }
                    
                    // Timer Display
                    Text(viewModel.timeRemaining)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    
                    // Control Buttons
                    HStack(spacing: 40) {
                        Button(action: viewModel.toggleExercise) {
                            Image(systemName: viewModel.isActive ? "pause.fill" : "play.fill")
                                .font(.title)
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.blue)
                                .clipShape(Circle())
                        }
                        
                        Button(action: viewModel.resetExercise) {
                            Image(systemName: "arrow.clockwise")
                                .font(.title)
                                .foregroundColor(.blue)
                                .frame(width: 60, height: 60)
                                .background(Color.blue.opacity(0.2))
                                .clipShape(Circle())
                        }
                    }
                    
                    // Exercise Stats
                    if viewModel.showStats {
                        VStack(spacing: 8) {
                            Text("Session Stats")
                                .font(.headline)
                            
                            HStack(spacing: 30) {
                                StatView(title: "Cycles", value: "\(viewModel.completedCycles)")
                                StatView(title: "Duration", value: viewModel.formattedTotalTime)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("4-7-8 Breathing")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    viewModel.saveExercise()
                    dismiss()
                }) {
                    Text("Done")
                }
            }
        }
        .onDisappear {
            viewModel.cleanup()
        }
    }
}

struct StatView: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
        }
    }
}

#Preview {
    NavigationView {
        BreathingExerciseView()
    }
}
