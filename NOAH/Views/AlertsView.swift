import SwiftUI

struct AlertsView: View {
    @StateObject private var viewModel = AlertsViewModel()
    
    var body: some View {
        NavigationView {
            List {
                if viewModel.alerts.isEmpty {
                    ContentUnavailableView(
                        "No Weather Alerts",
                        systemImage: "sun.max",
                        description: Text("You'll be notified when severe weather is expected in your area.")
                    )
                } else {
                    ForEach(viewModel.alerts) { alert in
                        AlertCell(alert: alert)
                    }
                }
            }
            .navigationTitle("Weather Alerts")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: viewModel.refreshAlerts) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .refreshable {
                await viewModel.refreshAlerts()
            }
        }
    }
}

struct AlertCell: View {
    let alert: WeatherAlert
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: alert.type.iconName)
                    .foregroundColor(alert.type.color)
                    .font(.system(size: 24))
                
                VStack(alignment: .leading) {
                    Text(alert.title)
                        .font(.headline)
                    Text(alert.location)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(alert.severity.rawValue)
                    .font(.caption)
                    .padding(6)
                    .background(alert.severity.color.opacity(0.2))
                    .foregroundColor(alert.severity.color)
                    .cornerRadius(8)
            }
            
            Text(alert.description)
                .font(.subheadline)
                .lineLimit(3)
            
            HStack {
                Label(alert.timeRange, systemImage: "clock")
                Spacer()
                Button("View Details") {
                    // TODO: Show alert details
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

class AlertsViewModel: ObservableObject {
    @Published var alerts: [WeatherAlert] = []
    @Published var isLoading = false
    
    func refreshAlerts() async {
        // TODO: Implement actual weather alerts fetch
        // This is sample data
        alerts = [
            WeatherAlert(
                id: UUID(),
                type: .thunderstorm,
                title: "Severe Thunderstorm Warning",
                description: "Strong thunderstorms are expected with potential for heavy rainfall, strong winds, and possible hail.",
                location: "San Francisco Bay Area",
                severity: .severe,
                timeRange: "Today, 2 PM - 8 PM"
            ),
            WeatherAlert(
                id: UUID(),
                type: .flood,
                title: "Flash Flood Watch",
                description: "Heavy rainfall may lead to flash flooding in low-lying areas and urban areas with poor drainage.",
                location: "Santa Clara County",
                severity: .moderate,
                timeRange: "Today, 4 PM - Tomorrow, 4 AM"
            )
        ]
    }
}

struct WeatherAlert: Identifiable {
    let id: UUID
    let type: AlertType
    let title: String
    let description: String
    let location: String
    let severity: AlertSeverity
    let timeRange: String
}

enum AlertType {
    case thunderstorm
    case flood
    case tornado
    case hurricane
    case winterStorm
    case heatWave
    
    var iconName: String {
        switch self {
        case .thunderstorm: return "cloud.bolt.fill"
        case .flood: return "water.waves"
        case .tornado: return "tornado"
        case .hurricane: return "hurricane"
        case .winterStorm: return "snow"
        case .heatWave: return "thermometer.sun.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .thunderstorm: return .yellow
        case .flood: return .blue
        case .tornado: return .red
        case .hurricane: return .purple
        case .winterStorm: return .cyan
        case .heatWave: return .orange
        }
    }
}

enum AlertSeverity: String {
    case minor = "Minor"
    case moderate = "Moderate"
    case severe = "Severe"
    case extreme = "Extreme"
    
    var color: Color {
        switch self {
        case .minor: return .green
        case .moderate: return .yellow
        case .severe: return .orange
        case .extreme: return .red
        }
    }
}

struct AlertsView_Previews: PreviewProvider {
    static var previews: some View {
        AlertsView()
    }
}
