import SwiftUI

struct MeditationListView: View {
    @StateObject private var viewModel = MeditationViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // Category Selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    CategoryButton(
                        title: "All",
                        systemImage: "circle.grid.cross.fill",
                        isSelected: viewModel.selectedCategory == nil
                    ) {
                        viewModel.selectCategory(nil)
                    }
                    
                    ForEach(MeditationSession.Category.allCases, id: \.self) { category in
                        CategoryButton(
                            title: category.rawValue,
                            systemImage: category.systemImage,
                            isSelected: viewModel.selectedCategory == category
                        ) {
                            viewModel.selectCategory(category)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
            
            // Sessions List
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.filteredSessions.isEmpty {
                EmptyStateView()
            } else {
                List(viewModel.filteredSessions) { session in
                    NavigationLink(destination: MeditationPlayerView(session: session)) {
                        SessionRow(session: session)
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    await viewModel.loadSessions()
                }
            }
        }
        .navigationTitle("Meditation")
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
}

struct CategoryButton: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.title2)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .frame(width: 80, height: 80)
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

struct SessionRow: View {
    let session: MeditationSession
    
    var body: some View {
        HStack(spacing: 16) {
            AsyncImage(url: session.imageURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color(.systemGray5)
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(session.title)
                    .font(.headline)
                
                Text(session.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.secondary)
                    Text(formatDuration(session.duration))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach(session.tags.prefix(2), id: \.self) { tag in
                        Text(tag)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.systemGray6))
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        return "\(minutes) min"
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "moon.stars")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("No Meditations Found")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Try selecting a different category\nor check back later for new sessions.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview {
    NavigationView {
        MeditationListView()
    }
}
