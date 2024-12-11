import SwiftUI

struct SafetyPlanBuilderView: View {
    @StateObject private var viewModel = CrisisSupportViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var warningSignal = ""
    @State private var copingStrategy = ""
    @State private var reasonToLive = ""
    @State private var safeEnvironmentStep = ""
    @State private var personalNotes = ""
    @State private var currentSection = 0
    
    private let sections = [
        "Warning Signals",
        "Coping Strategies",
        "Reasons to Live",
        "Support Network",
        "Making Environment Safe",
        "Personal Notes"
    ]
    
    var body: some View {
        NavigationView {
            VStack {
                // Progress Indicator
                ProgressView(value: Double(currentSection), total: Double(sections.count))
                    .padding()
                
                TabView(selection: $currentSection) {
                    // Warning Signals
                    SafetyPlanSection(
                        title: "What are your warning signals?",
                        description: "List thoughts, images, mood, situation, or behaviors that may indicate a crisis may be developing",
                        items: viewModel.safetyPlan?.warningSignals ?? [],
                        newItem: $warningSignal,
                        onAdd: {
                            if !warningSignal.isEmpty {
                                var plan = viewModel.safetyPlan ?? SafetyPlan(userId: "", lastUpdated: Date(), warningSignals: [], copingStrategies: [], reasonsToLive: [], supportContacts: [], professionalContacts: [], safeEnvironmentSteps: [])
                                plan.warningSignals.append(warningSignal)
                                Task {
                                    await viewModel.saveSafetyPlan(plan)
                                }
                                warningSignal = ""
                            }
                        }
                    )
                    .tag(0)
                    
                    // Coping Strategies
                    SafetyPlanSection(
                        title: "What helps you cope?",
                        description: "List activities you can do by yourself to take your mind off problems",
                        items: viewModel.safetyPlan?.copingStrategies ?? [],
                        newItem: $copingStrategy,
                        onAdd: {
                            if !copingStrategy.isEmpty {
                                var plan = viewModel.safetyPlan ?? SafetyPlan(userId: "", lastUpdated: Date(), warningSignals: [], copingStrategies: [], reasonsToLive: [], supportContacts: [], professionalContacts: [], safeEnvironmentSteps: [])
                                plan.copingStrategies.append(copingStrategy)
                                Task {
                                    await viewModel.saveSafetyPlan(plan)
                                }
                                copingStrategy = ""
                            }
                        }
                    )
                    .tag(1)
                    
                    // Reasons to Live
                    SafetyPlanSection(
                        title: "What are your reasons to live?",
                        description: "List what is most important to you and worth living for",
                        items: viewModel.safetyPlan?.reasonsToLive ?? [],
                        newItem: $reasonToLive,
                        onAdd: {
                            if !reasonToLive.isEmpty {
                                var plan = viewModel.safetyPlan ?? SafetyPlan(userId: "", lastUpdated: Date(), warningSignals: [], copingStrategies: [], reasonsToLive: [], supportContacts: [], professionalContacts: [], safeEnvironmentSteps: [])
                                plan.reasonsToLive.append(reasonToLive)
                                Task {
                                    await viewModel.saveSafetyPlan(plan)
                                }
                                reasonToLive = ""
                            }
                        }
                    )
                    .tag(2)
                    
                    // Support Network
                    SupportNetworkView(viewModel: viewModel)
                        .tag(3)
                    
                    // Making Environment Safe
                    SafetyPlanSection(
                        title: "How can you make your environment safe?",
                        description: "List specific steps to remove or limit access to lethal means",
                        items: viewModel.safetyPlan?.safeEnvironmentSteps ?? [],
                        newItem: $safeEnvironmentStep,
                        onAdd: {
                            if !safeEnvironmentStep.isEmpty {
                                var plan = viewModel.safetyPlan ?? SafetyPlan(userId: "", lastUpdated: Date(), warningSignals: [], copingStrategies: [], reasonsToLive: [], supportContacts: [], professionalContacts: [], safeEnvironmentSteps: [])
                                plan.safeEnvironmentSteps.append(safeEnvironmentStep)
                                Task {
                                    await viewModel.saveSafetyPlan(plan)
                                }
                                safeEnvironmentStep = ""
                            }
                        }
                    )
                    .tag(4)
                    
                    // Personal Notes
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Personal Notes")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Add any additional information that may help during a crisis")
                            .foregroundColor(.secondary)
                        
                        TextEditor(text: $personalNotes)
                            .frame(height: 200)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.secondary.opacity(0.2))
                            )
                            .onChange(of: personalNotes) { newValue in
                                var plan = viewModel.safetyPlan ?? SafetyPlan(userId: "", lastUpdated: Date(), warningSignals: [], copingStrategies: [], reasonsToLive: [], supportContacts: [], professionalContacts: [], safeEnvironmentSteps: [])
                                plan.personalNotes = newValue
                                Task {
                                    await viewModel.saveSafetyPlan(plan)
                                }
                            }
                    }
                    .padding()
                    .tag(5)
                }
                .tabViewStyle(.page)
                
                // Navigation Buttons
                HStack {
                    if currentSection > 0 {
                        Button("Previous") {
                            withAnimation {
                                currentSection -= 1
                            }
                        }
                    }
                    
                    Spacer()
                    
                    if currentSection < sections.count - 1 {
                        Button("Next") {
                            withAnimation {
                                currentSection += 1
                            }
                        }
                    } else {
                        Button("Finish") {
                            dismiss()
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Safety Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await viewModel.fetchSafetyPlan()
        }
    }
}

struct SafetyPlanSection: View {
    let title: String
    let description: String
    let items: [String]
    @Binding var newItem: String
    let onAdd: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(description)
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                ForEach(items, id: \.self) { item in
                    HStack {
                        Text("•")
                        Text(item)
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
            
            HStack {
                TextField("Add new item", text: $newItem)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: onAdd) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

struct SupportNetworkView: View {
    @ObservedObject var viewModel: CrisisSupportViewModel
    @State private var showingContactForm = false
    @State private var contactType: ContactType = .personal
    
    enum ContactType {
        case personal
        case professional
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Support Network")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Add people you can reach out to during a crisis")
                .foregroundColor(.secondary)
            
            List {
                Section(header: Text("Personal Contacts")) {
                    ForEach(viewModel.safetyPlan?.supportContacts ?? []) { contact in
                        ContactRow(contact: contact)
                    }
                    
                    Button(action: {
                        contactType = .personal
                        showingContactForm = true
                    }) {
                        Label("Add Personal Contact", systemImage: "plus.circle")
                    }
                }
                
                Section(header: Text("Professional Contacts")) {
                    ForEach(viewModel.safetyPlan?.professionalContacts ?? []) { contact in
                        ContactRow(contact: contact)
                    }
                    
                    Button(action: {
                        contactType = .professional
                        showingContactForm = true
                    }) {
                        Label("Add Professional Contact", systemImage: "plus.circle")
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
        }
        .sheet(isPresented: $showingContactForm) {
            ContactFormView(viewModel: viewModel, contactType: contactType)
        }
    }
}

struct ContactRow: View {
    let contact: EmergencyContact
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(contact.name)
                .font(.headline)
            Text(contact.relationship)
                .font(.subheadline)
                .foregroundColor(.secondary)
            if contact.isAvailable24Hours {
                Text("Available 24/7")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            Button(action: {
                guard let url = URL(string: "tel://\(contact.phoneNumber)") else { return }
                UIApplication.shared.open(url)
            }) {
                Label(contact.phoneNumber, systemImage: "phone.fill")
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ContactFormView: View {
    @ObservedObject var viewModel: CrisisSupportViewModel
    @Environment(\.dismiss) private var dismiss
    
    let contactType: SupportNetworkView.ContactType
    
    @State private var name = ""
    @State private var relationship = ""
    @State private var phoneNumber = ""
    @State private var isAvailable24Hours = false
    @State private var alternatePhoneNumber = ""
    @State private var email = ""
    @State private var address = ""
    @State private var notes = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Contact Information")) {
                    TextField("Name", text: $name)
                    TextField("Relationship", text: $relationship)
                    TextField("Phone Number", text: $phoneNumber)
                        .keyboardType(.phonePad)
                    Toggle("Available 24/7", isOn: $isAvailable24Hours)
                }
                
                Section(header: Text("Additional Information")) {
                    TextField("Alternate Phone", text: $alternatePhoneNumber)
                        .keyboardType(.phonePad)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                    TextField("Address", text: $address)
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
            }
            .navigationTitle(contactType == .personal ? "Add Personal Contact" : "Add Professional Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let contact = EmergencyContact(
                            name: name,
                            relationship: relationship,
                            phoneNumber: phoneNumber,
                            isAvailable24Hours: isAvailable24Hours,
                            alternatePhoneNumber: alternatePhoneNumber.isEmpty ? nil : alternatePhoneNumber,
                            email: email.isEmpty ? nil : email,
                            address: address.isEmpty ? nil : address,
                            notes: notes.isEmpty ? nil : notes
                        )
                        
                        var plan = viewModel.safetyPlan ?? SafetyPlan(
                            userId: "", lastUpdated: Date(),
                            warningSignals: [], copingStrategies: [],
                            reasonsToLive: [], supportContacts: [],
                            professionalContacts: [], safeEnvironmentSteps: []
                        )
                        
                        if contactType == .personal {
                            plan.supportContacts.append(contact)
                        } else {
                            plan.professionalContacts.append(contact)
                        }
                        
                        Task {
                            await viewModel.saveSafetyPlan(plan)
                        }
                        
                        dismiss()
                    }
                    .disabled(name.isEmpty || phoneNumber.isEmpty)
                }
            }
        }
    }
}
