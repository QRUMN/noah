import SwiftUI
import FirebaseFirestore

struct AdminPortalView: View {
    @StateObject private var viewModel = AdminPortalViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack {
                // Admin sections
                Picker("View", selection: $selectedTab) {
                    Text("Resources").tag(0)
                    Text("Providers").tag(1)
                    Text("Analytics").tag(2)
                    Text("Users").tag(3)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                TabView(selection: $selectedTab) {
                    // Crisis Resources Management
                    ResourceManagementView(viewModel: viewModel)
                        .tag(0)
                    
                    // Provider Verification
                    ProviderVerificationView(viewModel: viewModel)
                        .tag(1)
                    
                    // Usage Analytics
                    AnalyticsView(viewModel: viewModel)
                        .tag(2)
                    
                    // User Management
                    UserManagementView(viewModel: viewModel)
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("Admin Portal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: viewModel.refreshData) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
    }
}

// MARK: - Resource Management View
struct ResourceManagementView: View {
    @ObservedObject var viewModel: AdminPortalViewModel
    @State private var showAddResource = false
    @State private var searchText = ""
    
    var filteredResources: [CrisisResource] {
        if searchText.isEmpty {
            return viewModel.resources
        }
        return viewModel.resources.filter { resource in
            resource.name.localizedCaseInsensitiveContains(searchText) ||
            resource.description.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search resources", text: $searchText)
            }
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .padding()
            
            List {
                ForEach(filteredResources) { resource in
                    ResourceRow(resource: resource) {
                        viewModel.editResource(resource)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            viewModel.deleteResource(resource)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            
            Button(action: { showAddResource = true }) {
                Label("Add Resource", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding()
        }
        .sheet(isPresented: $showAddResource) {
            ResourceFormView(viewModel: viewModel)
        }
    }
}

// MARK: - Provider Verification View
struct ProviderVerificationView: View {
    @ObservedObject var viewModel: AdminPortalViewModel
    
    var body: some View {
        List {
            ForEach(viewModel.pendingProviders) { provider in
                ProviderVerificationRow(provider: provider) {
                    viewModel.verifyProvider(provider)
                } onReject: {
                    viewModel.rejectProvider(provider)
                }
            }
        }
    }
}

// MARK: - Analytics View
struct AnalyticsView: View {
    @ObservedObject var viewModel: AdminPortalViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Usage Statistics
                StatisticsCard(title: "Usage Statistics", items: [
                    ("Active Users", "\(viewModel.analytics.activeUsers)"),
                    ("Emergency Calls", "\(viewModel.analytics.emergencyCalls)"),
                    ("Resources Accessed", "\(viewModel.analytics.resourcesAccessed)")
                ])
                
                // Resource Usage
                Chart(data: viewModel.analytics.resourceUsage)
                    .frame(height: 200)
                    .padding()
                
                // Response Times
                StatisticsCard(title: "Average Response Times", items: [
                    ("Emergency Services", "\(viewModel.analytics.avgEmergencyResponseTime)s"),
                    ("Crisis Line", "\(viewModel.analytics.avgCrisisLineResponseTime)s")
                ])
                
                // User Feedback
                FeedbackList(feedback: viewModel.analytics.recentFeedback)
            }
            .padding()
        }
    }
}

// MARK: - User Management View
struct UserManagementView: View {
    @ObservedObject var viewModel: AdminPortalViewModel
    @State private var searchText = ""
    
    var filteredUsers: [UserProfile] {
        if searchText.isEmpty {
            return viewModel.users
        }
        return viewModel.users.filter { user in
            user.name.localizedCaseInsensitiveContains(searchText) ||
            user.email.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search users", text: $searchText)
            }
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .padding()
            
            List {
                ForEach(filteredUsers) { user in
                    UserRow(user: user) {
                        viewModel.viewUserDetails(user)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            viewModel.suspendUser(user)
                        } label: {
                            Label("Suspend", systemImage: "exclamationmark.triangle")
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views
struct ResourceRow: View {
    let resource: CrisisResource
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(resource.name)
                        .font(.headline)
                    Spacer()
                    if resource.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.green)
                    }
                }
                
                Text(resource.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Label(resource.category.rawValue, systemImage: "tag")
                        .font(.caption)
                    Spacer()
                    Text(resource.availabilityHours)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ProviderVerificationRow: View {
    let provider: SupportProvider
    let onVerify: () -> Void
    let onReject: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(provider.name)
                .font(.headline)
            
            Text(provider.credentials)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Button(action: onVerify) {
                    Label("Verify", systemImage: "checkmark.circle")
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                Button(action: onReject) {
                    Label("Reject", systemImage: "xmark.circle")
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct StatisticsCard: View {
    let title: String
    let items: [(String, String)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            
            ForEach(items, id: \.0) { item in
                HStack {
                    Text(item.0)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(item.1)
                        .font(.headline)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct Chart: View {
    let data: [(String, Double)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Resource Usage")
                .font(.headline)
            
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(data, id: \.0) { item in
                    VStack {
                        Text("\(Int(item.1))")
                            .font(.caption)
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: 30, height: item.1)
                        Text(item.0)
                            .font(.caption)
                            .rotationEffect(.degrees(-45))
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct FeedbackList: View {
    let feedback: [(String, String, Date)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Feedback")
                .font(.headline)
            
            ForEach(feedback, id: \.2) { item in
                VStack(alignment: .leading, spacing: 8) {
                    Text(item.0)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(item.1)
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Text(item.2, style: .date)
                        .font(.caption)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
    }
}

struct UserRow: View {
    let user: UserProfile
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                Text(user.name)
                    .font(.headline)
                
                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Label("\(user.lastActive)", systemImage: "clock")
                        .font(.caption)
                    Spacer()
                    if user.isSuspended {
                        Label("Suspended", systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
