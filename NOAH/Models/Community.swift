import Foundation
import FirebaseFirestore

enum GroupPrivacy: String, Codable {
    case `public` = "Public"
    case `private` = "Private"
    case anonymous = "Anonymous"
}

enum PostType: String, Codable {
    case discussion = "Discussion"
    case success = "Success Story"
    case question = "Question"
    case resource = "Resource"
    case support = "Support"
}

struct SupportGroup: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let category: String
    let privacy: GroupPrivacy
    let rules: [String]
    let moderatorIds: [String]
    let memberCount: Int
    let createdAt: Date
    let imageURL: String?
    let tags: [String]
    var isModerated: Bool
    
    // Computed property for group status
    var status: String {
        isModerated ? "Moderated" : "Community-Led"
    }
}

struct CommunityPost: Identifiable, Codable {
    let id: String
    let groupId: String
    let authorId: String
    let type: PostType
    let title: String
    let content: String
    let tags: [String]
    let createdAt: Date
    let editedAt: Date?
    let isAnonymous: Bool
    var likeCount: Int
    var commentCount: Int
    var isReported: Bool
    let attachments: [String]? // URLs to attached media
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
}

struct Comment: Identifiable, Codable {
    let id: String
    let postId: String
    let authorId: String
    let content: String
    let createdAt: Date
    let editedAt: Date?
    let isAnonymous: Bool
    var likeCount: Int
    var isReported: Bool
    let parentCommentId: String?
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
}

struct CommunityMember: Identifiable, Codable {
    let id: String
    let userId: String
    let groupId: String
    let joinDate: Date
    var role: String // "member", "moderator", "admin"
    var reputation: Int
    var badges: [String]
    var isActive: Bool
    
    // Engagement metrics
    var postsCount: Int
    var commentsCount: Int
    var helpfulResponseCount: Int
}

struct Report: Identifiable, Codable {
    let id: String
    let reporterId: String
    let targetId: String // ID of post or comment
    let targetType: String // "post" or "comment"
    let reason: String
    let description: String
    let createdAt: Date
    var status: String // "pending", "reviewed", "resolved"
    var moderatorNotes: String?
    var resolution: String?
}

struct CommunityGuideline: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let category: String
    let examples: [String]
    let consequences: [String]
    let lastUpdated: Date
}
