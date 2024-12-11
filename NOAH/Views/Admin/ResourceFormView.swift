import SwiftUI
import MapKit

struct ResourceFormView: View {
    @ObservedObject var viewModel: AdminPortalViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var description = ""
    @State private var category: CrisisResource.ResourceCategory = .emergency
    @State private var phoneNumber = ""
    @State private var website = ""
    @State private var address = ""
    @State private var availabilityHours = ""
    @State private var languages: Set<String> = []
    @State private var services: Set<String> = []
    @State private var isVerified = false
    @State private var coordinates: CLLocationCoordinate2D?
    
    @State private var showingLocationPicker = false
    @State private var searchQuery = ""
    @State private var searchResults: [MKMapItem] = []
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Basic Information")) {
                    TextField("Name", text: $name)
                    TextEditor(text: $description)
                        .frame(height: 100)
                    
                    Picker("Category", selection: $category) {
                        ForEach(CrisisResource.ResourceCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                }
                
                Section(header: Text("Contact Information")) {
                    TextField("Phone Number", text: $phoneNumber)
                        .keyboardType(.phonePad)
                    TextField("Website", text: $website)
                        .keyboardType(.URL)
                    TextField("Address", text: $address)
                    Button(action: { showingLocationPicker = true }) {
                        HStack {
                            Text("Set Location")
                            Spacer()
                            if coordinates != nil {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
                
                Section(header: Text("Availability")) {
                    TextField("Hours of Operation", text: $availabilityHours)
                }
                
                Section(header: Text("Languages & Services")) {
                    NavigationLink("Languages (\(languages.count))") {
                        LanguageSelectionView(selectedLanguages: $languages)
                    }
                    
                    NavigationLink("Services (\(services.count))") {
                        ServiceSelectionView(selectedServices: $services)
                    }
                }
                
                Section {
                    Toggle("Verified Resource", isOn: $isVerified)
                }
            }
            .navigationTitle("Add Resource")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveResource()
                    }
                    .disabled(name.isEmpty || description.isEmpty)
                }
            }
            .sheet(isPresented: $showingLocationPicker) {
                LocationPickerView(coordinates: $coordinates, address: $address)
            }
        }
    }
    
    private func saveResource() {
        let resource = CrisisResource(
            id: nil,
            name: name,
            description: description,
            category: category,
            phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber,
            website: website.isEmpty ? nil : website,
            address: address.isEmpty ? nil : address,
            coordinates: coordinates,
            availabilityHours: availabilityHours,
            languages: Array(languages),
            services: Array(services),
            isVerified: isVerified
        )
        
        viewModel.addResource(resource)
        dismiss()
    }
}

struct LanguageSelectionView: View {
    @Binding var selectedLanguages: Set<String>
    @Environment(\.dismiss) private var dismiss
    
    let availableLanguages = [
        "English", "Spanish", "French", "Mandarin", "Arabic",
        "Hindi", "Bengali", "Portuguese", "Russian", "Japanese",
        "German", "Korean", "Vietnamese", "Italian", "Turkish"
    ]
    
    var body: some View {
        List {
            ForEach(availableLanguages, id: \.self) { language in
                Button(action: {
                    if selectedLanguages.contains(language) {
                        selectedLanguages.remove(language)
                    } else {
                        selectedLanguages.insert(language)
                    }
                }) {
                    HStack {
                        Text(language)
                        Spacer()
                        if selectedLanguages.contains(language) {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        .navigationTitle("Languages")
    }
}

struct ServiceSelectionView: View {
    @Binding var selectedServices: Set<String>
    @Environment(\.dismiss) private var dismiss
    
    let availableServices = [
        "24/7 Crisis Support",
        "Counseling",
        "Emergency Housing",
        "Medical Services",
        "Legal Aid",
        "Transportation",
        "Food Assistance",
        "Mental Health Assessment",
        "Substance Abuse Treatment",
        "Support Groups",
        "Case Management",
        "Youth Services",
        "LGBTQ+ Support",
        "Veteran Services",
        "Domestic Violence Support"
    ]
    
    var body: some View {
        List {
            ForEach(availableServices, id: \.self) { service in
                Button(action: {
                    if selectedServices.contains(service) {
                        selectedServices.remove(service)
                    } else {
                        selectedServices.insert(service)
                    }
                }) {
                    HStack {
                        Text(service)
                        Spacer()
                        if selectedServices.contains(service) {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        .navigationTitle("Services")
    }
}

struct LocationPickerView: View {
    @Binding var coordinates: CLLocationCoordinate2D?
    @Binding var address: String
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search location", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding()
                
                // Map
                Map(coordinateRegion: $region,
                    annotationItems: searchResults.map { LocationAnnotation(mapItem: $0) }) { annotation in
                    MapMarker(coordinate: annotation.coordinate)
                }
                
                // Search results
                List(searchResults, id: \.self) { item in
                    Button(action: {
                        selectLocation(item)
                    }) {
                        VStack(alignment: .leading) {
                            Text(item.name ?? "")
                                .font(.headline)
                            if let address = item.placemark.title {
                                Text(address)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onChange(of: searchText) { newValue in
                searchLocation()
            }
        }
    }
    
    private func searchLocation() {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.region = region
        
        MKLocalSearch(request: request).start { response, error in
            guard let response = response else { return }
            searchResults = response.mapItems
        }
    }
    
    private func selectLocation(_ item: MKMapItem) {
        coordinates = item.placemark.coordinate
        address = item.placemark.title ?? ""
        region.center = item.placemark.coordinate
        dismiss()
    }
}

struct LocationAnnotation: Identifiable {
    let id = UUID()
    let mapItem: MKMapItem
    
    var coordinate: CLLocationCoordinate2D {
        mapItem.placemark.coordinate
    }
}
