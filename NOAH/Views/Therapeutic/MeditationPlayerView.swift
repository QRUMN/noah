import SwiftUI

struct MeditationPlayerView: View {
    let session: MeditationSession
    @StateObject private var viewModel = MeditationViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                AsyncImage(url: session.imageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .blur(radius: 20)
                } placeholder: {
                    Color(.systemGray6)
                }
                .overlay(Color.black.opacity(0.3))
                .ignoresSafeArea()
                
                // Content
                VStack(spacing: 30) {
                    Spacer()
                    
                    // Session Image
                    AsyncImage(url: session.imageURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color(.systemGray5)
                    }
                    .frame(width: geometry.size.width * 0.7, height: geometry.size.width * 0.7)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(radius: 10)
                    
                    // Session Info
                    VStack(spacing: 8) {
                        Text(session.title)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text(session.description)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    // Progress Bar
                    VStack(spacing: 8) {
                        Slider(value: .init(
                            get: { viewModel.currentTime },
                            set: { viewModel.seek(to: $0) }
                        ), in: 0...session.duration)
                        .accentColor(.white)
                        
                        HStack {
                            Text(formatTime(viewModel.currentTime))
                            Spacer()
                            Text(formatTime(session.duration))
                        }
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.horizontal)
                    
                    // Controls
                    HStack(spacing: 40) {
                        Button {
                            viewModel.seek(to: max(0, viewModel.currentTime - 15))
                        } label: {
                            Image(systemName: "gobackward.15")
                                .font(.title)
                                .foregroundColor(.white)
                        }
                        
                        Button {
                            if viewModel.isPlaying {
                                viewModel.togglePlayPause()
                            } else {
                                viewModel.startSession(session)
                            }
                        } label: {
                            Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 64))
                                .foregroundColor(.white)
                        }
                        
                        Button {
                            viewModel.seek(to: min(session.duration, viewModel.currentTime + 15))
                        } label: {
                            Image(systemName: "goforward.15")
                                .font(.title)
                                .foregroundColor(.white)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    viewModel.stopAudio()
                    dismiss()
                } label: {
                    Text("Done")
                        .foregroundColor(.white)
                }
            }
        }
        .onDisappear {
            viewModel.stopAudio()
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    NavigationView {
        MeditationPlayerView(session: MeditationSession.preview)
    }
}
