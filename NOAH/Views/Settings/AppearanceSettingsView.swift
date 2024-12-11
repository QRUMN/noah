import SwiftUI

struct AppearanceSettingsView: View {
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Form {
            Section(header: Text("Theme")) {
                Picker("App Theme", selection: $themeManager.selectedTheme) {
                    ForEach(Theme.allCases, id: \.rawValue) { theme in
                        Text(theme.title)
                            .tag(theme)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            Section(header: Text("Preview"), footer: Text("Changes will apply immediately")) {
                VStack(spacing: 16) {
                    // Preview Card
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Preview")
                            .font(.headline)
                        
                        Text("This is how the app will look with the selected theme.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Image(systemName: "moon.stars.fill")
                                .foregroundColor(.blue)
                            Spacer()
                            Text("Dark Mode")
                                .foregroundColor(.primary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Button Preview
                    Button(action: {}) {
                        Text("Sample Button")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    // List Item Preview
                    HStack {
                        Image(systemName: "gear")
                            .foregroundColor(.blue)
                        Text("Sample Setting")
                        Spacer()
                        Text("Value")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }
}
