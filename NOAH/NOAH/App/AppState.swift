import Foundation

@MainActor
class AppState: ObservableObject {
    @Published var isInitializing: Bool = true
    @Published var logs: [LogEntry] = []
    
    struct LogEntry: Identifiable {
        let id = UUID()
        let timestamp: Date
        let message: String
        let type: LogType
        
        enum LogType {
            case info
            case error
        }
    }
    
    func logMessage(_ message: String) {
        let entry = LogEntry(timestamp: Date(), message: message, type: .info)
        logs.append(entry)
        print("📱 NOAH: \(message)")
    }
    
    func logError(_ message: String) {
        let entry = LogEntry(timestamp: Date(), message: message, type: .error)
        logs.append(entry)
        print("❌ NOAH Error: \(message)")
    }
}
