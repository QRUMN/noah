import SwiftUI

struct MainTabView: View {
    @StateObject private var authService = FirebaseAuthService.shared
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(0)
            
            TherapyToolsHomeView()
                .tabItem {
                    Label("Tools", systemImage: "hammer")
                }
                .tag(1)
            
            MoodInsightsView()
                .tabItem {
                    Label("Insights", systemImage: "chart.bar")
                }
                .tag(2)
            
            CommunityHomeView()
                .tabItem {
                    Label("Community", systemImage: "person.3")
                }
                .tag(3)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(4)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(5)
        }
        .accentColor(.blue)
    }
}

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Quick Actions
                    QuickActionsGrid()
                        .padding(.horizontal)
                    
                    // Today's Mood
                    TodaysMoodCard(viewModel: viewModel)
                        .padding(.horizontal)
                    
                    // Recent Activities
                    RecentActivitiesView(viewModel: viewModel)
                        .padding(.vertical)
                    
                    // Upcoming Sessions
                    UpcomingSessionsView(viewModel: viewModel)
                        .padding(.horizontal)
                    
                    // Wellness Tips
                    WellnessTipsView(viewModel: viewModel)
                        .padding()
                }
                .padding(.top)
            }
            .navigationTitle("Welcome")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { viewModel.showCheckIn = true }) {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showCheckIn) {
                CheckInView()
            }
            .sheet(isPresented: $viewModel.showCrisisResources) {
                CrisisResourcesView()
            }
        }
    }
}

// MARK: - Home Components

struct QuickActionsGrid: View {
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            QuickActionButton(title: "Track Mood", icon: "chart.mood", color: .blue) {
                // Action
            }
            QuickActionButton(title: "Journal", icon: "text.book.closed", color: .purple) {
                // Action
            }
            QuickActionButton(title: "Meditate", icon: "leaf", color: .green) {
                // Action
            }
            QuickActionButton(title: "Get Help", icon: "hand.raised", color: .red) {
                // Action
            }
            QuickActionButton(title: "Crisis Help", icon: "cross.circle", color: .red) {
                // Navigate to Crisis Resources
                HomeViewModel().showCrisisResources = true
            }
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

struct TodaysMoodCard: View {
    @ObservedObject var viewModel: HomeViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Mood")
                .font(.headline)
            
            if let mood = viewModel.todaysMood {
                HStack {
                    Text(mood.icon)
                        .font(.system(size: 32))
                    VStack(alignment: .leading) {
                        Text(mood.rawValue)
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text("Tracked at \(mood.timestamp, formatter: timeFormatter)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                Button(action: { viewModel.showCheckIn = true }) {
                    Text("Track your first mood of the day")
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}

struct RecentActivitiesView: View {
    @ObservedObject var viewModel: HomeViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activities")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.recentActivities) { activity in
                        ActivityCard(activity: activity)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct ActivityCard: View {
    let activity: Activity
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: activity.icon)
                .font(.system(size: 24))
                .foregroundColor(.blue)
            
            Text(activity.title)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text(activity.timestamp, style: .relative)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .frame(width: 120)
    }
}

struct UpcomingSessionsView: View {
    @ObservedObject var viewModel: HomeViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Upcoming Sessions")
                .font(.headline)
            
            if viewModel.upcomingSessions.isEmpty {
                Text("No upcoming sessions")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(viewModel.upcomingSessions) { session in
                    SessionRow(session: session)
                }
            }
        }
    }
}

struct SessionRow: View {
    let session: TherapySession
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(session.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(session.timestamp, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {}) {
                Text("Join")
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct WellnessTipsView: View {
    @ObservedObject var viewModel: HomeViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily Wellness Tips")
                .font(.headline)
            
            ForEach(viewModel.wellnessTips, id: \.self) { tip in
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                    Text(tip)
                        .font(.subheadline)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
    }
}

// MARK: - Removed Components

//struct WeatherCard: View {
//    let viewModel: CurrentWeatherViewModel
//    
//    var body: some View {
//        VStack(spacing: 16) {
//            HStack {
//                VStack(alignment: .leading) {
//                    Text(viewModel.location)
//                        .font(.title2)
//                        .fontWeight(.semibold)
//                    Text(viewModel.date)
//                        .font(.subheadline)
//                        .foregroundColor(.secondary)
//                }
//                Spacer()
//                Text(viewModel.temperature)
//                    .font(.system(size: 44, weight: .bold))
//            }
//            
//            HStack {
//                WeatherConditionIcon(condition: viewModel.condition)
//                    .frame(width: 30, height: 30)
//                Text(viewModel.condition)
//                    .font(.headline)
//                Spacer()
//                Text("Feels like \(viewModel.feelsLike)")
//                    .font(.subheadline)
//                    .foregroundColor(.secondary)
//            }
//        }
//        .padding()
//        .background(Color(.systemBackground))
//        .cornerRadius(15)
//        .shadow(radius: 5)
//    }
//}

//struct HourlyForecastView: View {
//    let forecast: [HourlyForecastItem]
//    
//    var body: some View {
//        VStack(alignment: .leading) {
//            Text("Hourly Forecast")
//                .font(.headline)
//                .padding(.horizontal)
//            
//            ScrollView(.horizontal, showsIndicators: false) {
//                HStack(spacing: 20) {
//                    ForEach(forecast) { item in
//                        VStack(spacing: 8) {
//                            Text(item.time)
//                                .font(.caption)
//                                .foregroundColor(.secondary)
//                            
//                            WeatherConditionIcon(condition: item.condition)
//                                .frame(width: 24, height: 24)
//                            
//                            Text(item.temperature)
//                                .font(.system(size: 16, weight: .medium))
//                        }
//                    }
//                }
//                .padding()
//            }
//        }
//        .background(Color(.systemBackground))
//        .cornerRadius(15)
//        .shadow(radius: 5)
//    }
//}

//struct WeatherConditionIcon: View {
//    let condition: String
//    
//    var systemName: String {
//        switch condition.lowercased() {
//        case let c where c.contains("clear"): return "sun.max.fill"
//        case let c where c.contains("cloud"): return "cloud.fill"
//        case let c where c.contains("rain"): return "cloud.rain.fill"
//        case let c where c.contains("snow"): return "cloud.snow.fill"
//        case let c where c.contains("thunder"): return "cloud.bolt.fill"
//        default: return "cloud.fill"
//        }
//    }
//    
//    var body: some View {
//        Image(systemName: systemName)
//            .foregroundColor(.blue)
//    }
//}

// Preview
//struct MainTabView_Previews: PreviewProvider {
//    static var previews: some View {
//        MainTabView()
//    }
//}
