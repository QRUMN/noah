import SwiftUI

enum Theme: Int, CaseIterable {
    case system
    case light
    case dark
    
    var title: String {
        switch self {
        case .system:
            return "System"
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @AppStorage("selectedTheme") private var selectedThemeRawValue: Int = 0
    
    var selectedTheme: Theme {
        get {
            Theme(rawValue: selectedThemeRawValue) ?? .system
        }
        set {
            selectedThemeRawValue = newValue.rawValue
        }
    }
    
    private init() {}
}
