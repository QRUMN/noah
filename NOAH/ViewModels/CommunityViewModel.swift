import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

@MainActor
class CommunityViewModel: ObservableObject {
    private let db = Firestore.firestore()
    private var cancellables = Set&lt;AnyCancellable&gt;()
    
    @Published var supportGroups: [SupportGroup] = []
    @Published var posts: [CommunityPost] = []
    @Published var comments: [Comment] = []
    @Published var currentMember: CommunityMember?
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    // MARK: - Group Management
    
    func fetchSupportGroups() async {
        isLoading = true
        do {
            let snapshot = try await db.collection("supportGroups").getDocuments()
            supportGroups = snapshot.documents.compactMap { document in
                try? document.data(as: SupportGroup.self)
            }
        } catch {
            errorMessage = "Failed to fetch support groups: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    func joinGroup(groupId: String) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        do {
            let member = CommunityMember(
                id: UUID().uuidString,
                userId: userId,
                groupId: groupId,
                joinDate: Date(),
                role: "member",
                reputation: 0,
                badges: [],
                isActive: true,
                postsCount: 0,
                commentsCount: 0,
                helpfulResponseCount: 0
            )
            
            try await db.collection("groupMembers").document(member.id).setData(from: member)
            currentMember = member
        } catch {
            errorMessage = "Failed to join group: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Post Management
    
    func createPost(groupId: String, type: PostType, title: String, content: String, isAnonymous: Bool) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        do {
            let post = CommunityPost(
                id: UUID().uuidString,
                groupId: groupId,
                authorId: userId,
                type: type,
                title: title,
                content: content,
                tags: [],
                createdAt: Date(),
                editedAt: nil,
                isAnonymous: isAnonymous,
                likeCount: 0,
                commentCount: 0,
                isReported: false,
                attachments: nil
            )
            
            try await db.collection("posts").document(post.id).setData(from: post)
            posts.append(post)
        } catch {
            errorMessage = "Failed to create post: \(error.localizedDescription)"
        }
    }
    
    func fetchPosts(groupId: String) async {
        isLoading = true
        do {
            let snapshot = try await db.collection("posts")
                .whereField("groupId", isEqualTo: groupId)
                .order(by: "createdAt", descending: true)
                .getDocuments()
            
            posts = snapshot.documents.compactMap { document in
                try? document.data(as: CommunityPost.self)
            }
        } catch {
            errorMessage = "Failed to fetch posts: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    // MARK: - Comment Management
    
    func addComment(postId: String, content: String, isAnonymous: Bool, parentCommentId: String? = nil) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        do {
            let comment = Comment(
                id: UUID().uuidString,
                postId: postId,
                authorId: userId,
                content: content,
                createdAt: Date(),
                editedAt: nil,
                isAnonymous: isAnonymous,
                likeCount: 0,
                isReported: false,
                parentCommentId: parentCommentId
            )
            
            try await db.collection("comments").document(comment.id).setData(from: comment)
            comments.append(comment)
            
            // Update post comment count
            if let postIndex = posts.firstIndex(where: { $0.id == postId }) {
                posts[postIndex].commentCount += 1
            }
        } catch {
            errorMessage = "Failed to add comment: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Moderation
    
    func reportContent(targetId: String, targetType: String, reason: String, description: String) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        do {
            let report = Report(
                id: UUID().uuidString,
                reporterId: userId,
                targetId: targetId,
                targetType: targetType,
                reason: reason,
                description: description,
                createdAt: Date(),
                status: "pending"
            )
            
            try await db.collection("reports").document(report.id).setData(from: report)
            
            // Mark content as reported
            if targetType == "post" {
                if let postIndex = posts.firstIndex(where: { $0.id == targetId }) {
                    posts[postIndex].isReported = true
                }
            } else if targetType == "comment" {
                if let commentIndex = comments.firstIndex(where: { $0.id == targetId }) {
                    comments[commentIndex].isReported = true
                }
            }
        } catch {
            errorMessage = "Failed to submit report: \(error.localizedDescription)"
        }
    }
    
    // MARK: - User Engagement
    
    func likeContent(contentId: String, contentType: String) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        do {
            let likeRef = db.collection("likes").document("\(contentId)_\(userId)")
            let likeExists = try await likeRef.getDocument().exists
            
            if !likeExists {
                try await likeRef.setData([
                    "userId": userId,
                    "contentId": contentId,
                    "contentType": contentType,
                    "createdAt": Date()
                ])
                
                // Update like count
                if contentType == "post" {
                    if let postIndex = posts.firstIndex(where: { $0.id == contentId }) {
                        posts[postIndex].likeCount += 1
                    }
                } else if contentType == "comment" {
                    if let commentIndex = comments.firstIndex(where: { $0.id == contentId }) {
                        comments[commentIndex].likeCount += 1
                    }
                }
            }
        } catch {
            errorMessage = "Failed to like content: \(error.localizedDescription)"
        }
    }
}
