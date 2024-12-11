import SwiftUI

struct TherapeuticToolsView: View {
    private let tools = [
        TherapeuticTool(
            title: "4-7-8 Breathing",
            description: "A breathing technique that promotes relaxation",
            systemImage: "lungs.fill",
            color: .blue,
            destination: AnyView(BreathingExerciseView())
        ),
        TherapeuticTool(
            title: "Guided Meditation",
            description: "Coming soon - Mindfulness meditation sessions",
            systemImage: "brain.head.profile",
            color: .purple,
            destination: AnyView(ComingSoonView())
        ),
        TherapeuticTool(
            title: "Journaling",
            description: "Coming soon - Express your thoughts and feelings",
            systemImage: "book.fill",
            color: .orange,
            destination: AnyView(ComingSoonView())
        )
    ]
    
    var body: some View {
        List(tools) { tool in
            NavigationLink(destination: tool.destination) {
                HStack(spacing: 16) {
                    Image(systemName: tool.systemImage)
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(tool.color)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(tool.title)
                            .font(.headline)
                        
                        Text(tool.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("Therapeutic Tools")
        .listStyle(.insetGrouped)
    }
}

struct TherapeuticTool: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let systemImage: String
    let color: Color
    let destination: AnyView
}

struct ComingSoonView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "hourglass")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Coming Soon")
                .font(.title)
                .fontWeight(.bold)
            
            Text("We're working hard to bring you this feature.\nStay tuned!")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .padding()
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        TherapeuticToolsView()
    }
}
