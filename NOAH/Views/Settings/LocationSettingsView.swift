import SwiftUI
import CoreLocation

struct LocationSettingsView: View {
    @StateObject private var viewModel = LocationSettingsViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            Section {
                HStack {
                    Image(systemName: "location.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                    
                    VStack(alignment: .leading) {
                        Text(viewModel.currentLocation ?? "Location not available")
                            .font(.headline)
                        Text("Current Location")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }
            
            Section {
                Toggle("Use Current Location", isOn: $viewModel.useCurrentLocation)
                    .onChange(of: viewModel.useCurrentLocation) { newValue in
                        if newValue {
                            viewModel.requestLocationPermission()
                        }
                    }
                
                if !viewModel.useCurrentLocation {
                    NavigationLink("Set Custom Location") {
                        CustomLocationView(viewModel: viewModel)
                    }
                }
            } header: {
                Text("Location Services")
            } footer: {
                Text("Enable location services to get accurate weather information for your current location.")
            }
            
            Section("Saved Locations") {
                ForEach(viewModel.savedLocations) { location in
                    LocationRow(location: location) {
                        viewModel.removeLocation(location)
                    }
                }
                .onDelete(perform: viewModel.deleteSavedLocation)
                
                Button(action: { viewModel.showAddLocation = true }) {
                    Label("Add Location", systemImage: "plus.circle.fill")
                }
            }
            
            Section("Location Permissions") {
                Button(action: viewModel.openSettings) {
                    HStack {
                        Text("Location Permission Status")
                        Spacer()
                        Text(viewModel.locationPermissionStatus)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Location Settings")
        .sheet(isPresented: $viewModel.showAddLocation) {
            AddLocationView(viewModel: viewModel)
        }
        .alert("Location Services Disabled", isPresented: $viewModel.showLocationAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Settings") {
                viewModel.openSettings()
            }
        } message: {
            Text("Please enable location services in Settings to use this feature.")
        }
    }
}

struct LocationRow: View {
    let location: SavedLocation
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(location.name)
                    .font(.headline)
                Text("\(location.latitude), \(location.longitude)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
    }
}

struct CustomLocationView: View {
    @ObservedObject var viewModel: LocationSettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    var body: some View {
        List {
            Section {
                TextField("Search location...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
            }
            
            if !viewModel.searchResults.isEmpty {
                Section("Results") {
                    ForEach(viewModel.searchResults) { result in
                        Button(action: {
                            viewModel.selectLocation(result)
                            dismiss()
                        }) {
                            VStack(alignment: .leading) {
                                Text(result.name)
                                    .font(.headline)
                                Text(result.address)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Set Location")
        .onChange(of: searchText) { newValue in
            viewModel.searchLocation(query: newValue)
        }
    }
}

struct AddLocationView: View {
    @ObservedObject var viewModel: LocationSettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    TextField("Search location...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                }
                
                if !viewModel.searchResults.isEmpty {
                    Section("Results") {
                        ForEach(viewModel.searchResults) { result in
                            Button(action: {
                                viewModel.addLocation(result)
                                dismiss()
                            }) {
                                VStack(alignment: .leading) {
                                    Text(result.name)
                                        .font(.headline)
                                    Text(result.address)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Location")
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
            .onChange(of: searchText) { newValue in
                viewModel.searchLocation(query: newValue)
            }
        }
    }
}

class LocationSettingsViewModel: ObservableObject {
    @Published var useCurrentLocation = true
    @Published var currentLocation: String?
    @Published var savedLocations: [SavedLocation] = []
    @Published var searchResults: [LocationSearchResult] = []
    @Published var showAddLocation = false
    @Published var showLocationAlert = false
    @Published var locationPermissionStatus = "Unknown"
    
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    init() {
        setupLocationManager()
        loadSavedLocations()
        updateLocationPermissionStatus()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    func updateLocationPermissionStatus() {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationPermissionStatus = "Allowed"
        case .denied:
            locationPermissionStatus = "Denied"
        case .restricted:
            locationPermissionStatus = "Restricted"
        case .notDetermined:
            locationPermissionStatus = "Not Determined"
        @unknown default:
            locationPermissionStatus = "Unknown"
        }
    }
    
    func searchLocation(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        geocoder.geocodeAddressString(query) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                if let placemarks = placemarks {
                    self?.searchResults = placemarks.compactMap { placemark in
                        guard let name = placemark.name,
                              let location = placemark.location else { return nil }
                        
                        var address = [String]()
                        if let locality = placemark.locality {
                            address.append(locality)
                        }
                        if let administrativeArea = placemark.administrativeArea {
                            address.append(administrativeArea)
                        }
                        if let country = placemark.country {
                            address.append(country)
                        }
                        
                        return LocationSearchResult(
                            id: UUID(),
                            name: name,
                            address: address.joined(separator: ", "),
                            coordinate: location.coordinate
                        )
                    }
                } else {
                    self?.searchResults = []
                }
            }
        }
    }
    
    func addLocation(_ result: LocationSearchResult) {
        let newLocation = SavedLocation(
            id: UUID(),
            name: result.name,
            latitude: result.coordinate.latitude,
            longitude: result.coordinate.longitude
        )
        savedLocations.append(newLocation)
        saveSavedLocations()
    }
    
    func removeLocation(_ location: SavedLocation) {
        savedLocations.removeAll { $0.id == location.id }
        saveSavedLocations()
    }
    
    func deleteSavedLocation(at offsets: IndexSet) {
        savedLocations.remove(atOffsets: offsets)
        saveSavedLocations()
    }
    
    private func loadSavedLocations() {
        // TODO: Implement loading from UserDefaults or Core Data
        savedLocations = []
    }
    
    private func saveSavedLocations() {
        // TODO: Implement saving to UserDefaults or Core Data
    }
    
    func selectLocation(_ result: LocationSearchResult) {
        useCurrentLocation = false
        currentLocation = result.name
        // TODO: Update app's current location
    }
}

extension LocationSettingsViewModel: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        updateLocationPermissionStatus()
        
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        case .denied, .restricted:
            showLocationAlert = true
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            if let placemark = placemarks?.first {
                DispatchQueue.main.async {
                    self?.currentLocation = [
                        placemark.locality,
                        placemark.administrativeArea,
                        placemark.country
                    ].compactMap { $0 }.joined(separator: ", ")
                }
            }
        }
    }
}

struct SavedLocation: Identifiable, Codable {
    let id: UUID
    let name: String
    let latitude: Double
    let longitude: Double
}

struct LocationSearchResult: Identifiable {
    let id: UUID
    let name: String
    let address: String
    let coordinate: CLLocationCoordinate2D
}

struct LocationSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            LocationSettingsView()
        }
    }
}
