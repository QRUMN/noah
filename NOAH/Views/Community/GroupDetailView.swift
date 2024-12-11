import SwiftUI

struct GroupDetailView: View {
    let group: SupportGroup
    @StateObject private var viewModel = CommunityViewModel()
    @State private var showNewPostSheet = false
    @State private var selectedPostType: PostType = .discussion
    @State private var showingReportSheet = false
    @State private var selectedPost: CommunityPost?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Group Header
                GroupHeaderView(group: group)
                
                // Post Type Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(PostType.allCases, id: \.self) { type in
                            PostTypeButton(type: type, selectedType: $selectedPostType)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Posts List
                LazyVStack(spacing: 16) {
                    ForEach(filteredPosts) { post in
                        PostCard(post: post) {
                            selectedPost = post
                            showingReportSheet = true
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle(group.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showNewPostSheet = true }) {
                    Image(systemName: "square.and.pencil")
                }
            }
        }
        .sheet(isPresented: $showNewPostSheet) {
            NewPostView(groupId: group.id)
        }
        .sheet(isPresented: $showingReportSheet) {
            if let post = selectedPost {
                ReportView(contentId: post.id, contentType: "post")
            }
        }
        .task {
            await viewModel.fetchPosts(groupId: group.id)
        }
    }
    
    private var filteredPosts: [CommunityPost] {
        viewModel.posts.filter { $0.type == selectedPostType }
    }
}

struct GroupHeaderView: View {
    let group: SupportGroup
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Group Image
            if let imageURL = group.imageURL {
                AsyncImage(url: URL(string: imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // Group Info
            VStack(alignment: .leading, spacing: 8) {
                Text(group.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                
                // Stats
                HStack(spacing: 16) {
                    Label("\(group.memberCount) members", systemImage: "person.2")
                    Label(group.status, systemImage: "checkmark.shield")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                
                // Tags
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(group.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                }
                
                // Rules
                if !group.rules.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Group Rules")
                            .font(.headline)
                        
                        ForEach(group.rules, id: \.self) { rule in
                            Label(rule, systemImage: "checkmark")
                                .font(.subheadline)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .padding()
        }
    }
}

struct PostTypeButton: View {
    let type: PostType
    @Binding var selectedType: PostType
    
    var body: some View {
        Button(action: { selectedType = type }) {
            Text(type.rawValue)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(type == selectedType ? Color.accentColor : Color.gray.opacity(0.2))
                .foregroundColor(type == selectedType ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct PostCard: View {
    let post: CommunityPost
    let onReport: () -> Void
    @StateObject private var viewModel = CommunityViewModel()
    @State private var showComments = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Author Info
            HStack {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
                
                VStack(alignment: .leading) {
                    Text(post.isAnonymous ? "Anonymous" : "User")
                        .font(.headline)
                    Text(post.formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Menu {
                    Button(role: .destructive, action: onReport) {
                        Label("Report", systemImage: "exclamationmark.triangle")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.secondary)
                }
            }
            
            // Post Content
            Text(post.title)
                .font(.headline)
            Text(post.content)
                .font(.body)
            
            // Engagement Buttons
            HStack {
                Button(action: { Task { await viewModel.likeContent(contentId: post.id, contentType: "post") }}) {
                    Label("\(post.likeCount)", systemImage: "heart")
                }
                
                Spacer()
                
                Button(action: { showComments.toggle() }) {
                    Label("\(post.commentCount) Comments", systemImage: "bubble.left")
                }
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            
            if showComments {
                Divider()
                CommentsSection(postId: post.id)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct CommentsSection: View {
    let postId: String
    @StateObject private var viewModel = CommunityViewModel()
    @State private var newComment = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(viewModel.comments.filter { $0.postId == postId }) { comment in
                CommentRow(comment: comment)
            }
            
            // Add Comment
            HStack {
                TextField("Add a comment...", text: $newComment)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: {
                    Task {
                        await viewModel.addComment(postId: postId, content: newComment, isAnonymous: false)
                        newComment = ""
                    }
                }) {
                    Text("Post")
                }
                .disabled(newComment.isEmpty)
            }
        }
    }
}

struct CommentRow: View {
    let comment: Comment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(comment.isAnonymous ? "Anonymous" : "User")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(comment.formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(comment.content)
                .font(.body)
            
            HStack {
                Label("\(comment.likeCount)", systemImage: "heart")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    NavigationView {
        GroupDetailView(group: SupportGroup(
            id: "1",
            name: "Anxiety Support",
            description: "A safe space to discuss anxiety and share coping strategies",
            category: "Mental Health",
            privacy: .public,
            rules: ["Be respectful", "No hate speech"],
            moderatorIds: [],
            memberCount: 150,
            createdAt: Date(),
            imageURL: nil,
            tags: ["Anxiety", "Support", "Mental Health"],
            isModerated: true
        ))
    }
}
