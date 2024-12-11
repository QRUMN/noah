import SwiftUI

struct CommunityHomeView: View {
    @StateObject private var viewModel = CommunityViewModel()
    @State private var selectedTab = 0
    @State private var showNewGroupSheet = false
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack {
                // Custom segmented control
                Picker("View", selection: $selectedTab) {
                    Text("Groups").tag(0)
                    Text("My Groups").tag(1)
                    Text("Discover").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Search bar
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                
                // Main content
                ScrollView {
                    LazyVStack(spacing: 16) {
                        switch selectedTab {
                        case 0:
                            ForEach(filteredGroups) { group in
                                NavigationLink(destination: GroupDetailView(group: group)) {
                                    GroupCard(group: group)
                                }
                            }
                        case 1:
                            MyGroupsView()
                        case 2:
                            DiscoverView()
                        default:
                            EmptyView()
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Community")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showNewGroupSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showNewGroupSheet) {
                NewGroupView()
            }
        }
        .task {
            await viewModel.fetchSupportGroups()
        }
    }
    
    private var filteredGroups: [SupportGroup] {
        if searchText.isEmpty {
            return viewModel.supportGroups
        }
        return viewModel.supportGroups.filter { group in
            group.name.localizedCaseInsensitiveContains(searchText) ||
            group.description.localizedCaseInsensitiveContains(searchText) ||
            group.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
}

struct GroupCard: View {
    let group: SupportGroup
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let imageURL = group.imageURL {
                    AsyncImage(url: URL(string: imageURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.gray.opacity(0.3)
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 60, height: 60)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(group.name)
                        .font(.headline)
                    Text(group.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            HStack {
                Label("\(group.memberCount)", systemImage: "person.2")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(group.status)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(group.isModerated ? Color.green.opacity(0.2) : Color.blue.opacity(0.2))
                    .cornerRadius(4)
            }
            
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
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search groups...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

#Preview {
    CommunityHomeView()
}
