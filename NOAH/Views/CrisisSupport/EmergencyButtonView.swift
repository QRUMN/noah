import SwiftUI

struct EmergencyButtonView: View {
    @StateObject private var viewModel = CrisisSupportViewModel()
    @State private var showingEmergencyOptions = false
    @State private var showingConfirmation = false
    @State private var selectedHelpline: Helpline?
    
    var body: some View {
        VStack {
            Button(action: { showingEmergencyOptions = true }) {
                HStack {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.title2)
                    Text("Get Help Now")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.red)
                .cornerRadius(25)
                .shadow(radius: 5)
            }
        }
        .sheet(isPresented: $showingEmergencyOptions) {
            NavigationView {
                List {
                    Section {
                        Button(action: {
                            showingEmergencyOptions = false
                            showingConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "phone.circle.fill")
                                    .foregroundColor(.red)
                                Text("Call Emergency Services (911)")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    Section(header: Text("Crisis Helplines")) {
                        ForEach(viewModel.helplines) { helpline in
                            VStack(alignment: .leading) {
                                Text(helpline.name)
                                    .font(.headline)
                                Text(helpline.description)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    Button(action: {
                                        selectedHelpline = helpline
                                        showingConfirmation = true
                                    }) {
                                        HStack {
                                            Image(systemName: "phone.fill")
                                            Text("Call")
                                        }
                                        .foregroundColor(.blue)
                                        .padding(.vertical, 5)
                                    }
                                    
                                    if helpline.smsNumber != nil {
                                        Divider()
                                        Button(action: {
                                            viewModel.textHelpline(helpline)
                                        }) {
                                            HStack {
                                                Image(systemName: "message.fill")
                                                Text("Text")
                                            }
                                            .foregroundColor(.blue)
                                            .padding(.vertical, 5)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 5)
                        }
                    }
                    
                    if !viewModel.nearbyServices.isEmpty {
                        Section(header: Text("Nearby Services")) {
                            ForEach(viewModel.nearbyServices) { service in
                                VStack(alignment: .leading) {
                                    Text(service.name)
                                        .font(.headline)
                                    if let distance = service.distance {
                                        Text(String(format: "%.1f miles away", distance / 1609.34))
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    Button(action: {
                                        guard let url = URL(string: "tel://\(service.phoneNumber)") else { return }
                                        UIApplication.shared.open(url)
                                    }) {
                                        HStack {
                                            Image(systemName: "phone.fill")
                                            Text("Call")
                                        }
                                        .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Emergency Help")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Cancel") {
                            showingEmergencyOptions = false
                        }
                    }
                }
            }
        }
        .alert("Confirm Emergency Call", isPresented: $showingConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Call Now", role: .destructive) {
                if let helpline = selectedHelpline {
                    viewModel.callHelpline(helpline)
                } else {
                    viewModel.callEmergencyServices()
                }
            }
        } message: {
            if let helpline = selectedHelpline {
                Text("Are you sure you want to call \(helpline.name)?")
            } else {
                Text("Are you sure you want to call emergency services (911)?")
            }
        }
        .task {
            await viewModel.refreshData()
        }
    }
}
