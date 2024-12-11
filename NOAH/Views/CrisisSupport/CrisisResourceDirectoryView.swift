import SwiftUI
import MapKit

struct CrisisResourceDirectoryView: View {
    @StateObject private var viewModel = CrisisSupportViewModel()
    @State private var selectedCategory: CrisisResource.ResourceCategory?
    @State private var searchText = ""
    @State private var showMap = false
    @State private var selectedResource: CrisisResource?
    
    private var filteredResources: [CrisisResource] {
        viewModel.crisisResources
            .filter { resource in
                if let category = selectedCategory {
                    return resource.category == category
                }
                return true
            }
            .filter { resource in
                if searchText.isEmpty {
                    return true
                }
                return resource.name.localizedCaseInsensitiveContains(searchText) ||
                       resource.description.localizedCaseInsensitiveContains(searchText)
            }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and Filter Bar
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search resources", text: $searchText)
                    }
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(
                                title: "All",
                                isSelected: selectedCategory == nil,
                                action: { selectedCategory = nil }
                            )
                            
                            ForEach(CrisisResource.ResourceCategory.allCases, id: \.self) { category in
                                FilterChip(
                                    title: category.rawValue,
                                    isSelected: selectedCategory == category,
                                    action: { selectedCategory = category }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding()
                .background(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 5, y: 2)
                
                // Resource List/Map Toggle
                Picker("View", selection: $showMap) {
                    Text("List").tag(false)
                    Text("Map").tag(true)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                if showMap {
                    // Map View
                    ResourceMapView(
                        resources: filteredResources,
                        userLocation: viewModel.userLocation,
                        selectedResource: $selectedResource
                    )
                    .edgesIgnoringSafeArea(.bottom)
                    .sheet(item: $selectedResource) { resource in
                        ResourceDetailView(resource: resource)
                    }
                } else {
                    // List View
                    List {
                        ForEach(filteredResources) { resource in
                            NavigationLink(destination: ResourceDetailView(resource: resource)) {
                                ResourceRow(resource: resource)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Crisis Resources")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            await viewModel.refreshData()
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
    }
}

struct ResourceRow: View {
    let resource: CrisisResource
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(resource.name)
                .font(.headline)
            
            Text(resource.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            if resource.isVerified {
                Label("Verified", systemImage: "checkmark.seal.fill")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            
            HStack {
                if let phone = resource.phoneNumber {
                    Button(action: {
                        guard let url = URL(string: "tel://\(phone)") else { return }
                        UIApplication.shared.open(url)
                    }) {
                        Label(phone, systemImage: "phone.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                Spacer()
                
                Text(resource.availabilityHours)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

struct ResourceMapView: View {
    let resources: [CrisisResource]
    let userLocation: CLLocationCoordinate2D?
    @Binding var selectedResource: CrisisResource?
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    var body: some View {
        Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: resources) { resource in
            MapAnnotation(coordinate: resource.coordinates ?? CLLocationCoordinate2D()) {
                Button(action: { selectedResource = resource }) {
                    VStack {
                        Image(systemName: "cross.circle.fill")
                            .font(.title)
                            .foregroundColor(.red)
                        Text(resource.name)
                            .font(.caption)
                            .foregroundColor(.primary)
                            .padding(4)
                            .background(Color.white)
                            .cornerRadius(4)
                            .shadow(radius: 2)
                    }
                }
            }
        }
        .onAppear {
            if let location = userLocation {
                region = MKCoordinateRegion(
                    center: location,
                    span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                )
            }
        }
    }
}

struct ResourceDetailView: View {
    let resource: CrisisResource
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(resource.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if resource.isVerified {
                        Label("Verified Resource", systemImage: "checkmark.seal.fill")
                            .foregroundColor(.green)
                    }
                    
                    Text(resource.category.rawValue)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                // Description
                Text(resource.description)
                    .font(.body)
                
                // Contact Options
                VStack(spacing: 12) {
                    if let phone = resource.phoneNumber {
                        Button(action: {
                            guard let url = URL(string: "tel://\(phone)") else { return }
                            UIApplication.shared.open(url)
                        }) {
                            HStack {
                                Image(systemName: "phone.fill")
                                Text("Call \(phone)")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                    }
                    
                    if let website = resource.website {
                        Button(action: {
                            guard let url = URL(string: website) else { return }
                            UIApplication.shared.open(url)
                        }) {
                            HStack {
                                Image(systemName: "globe")
                                Text("Visit Website")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                        }
                    }
                }
                
                // Additional Information
                Group {
                    InfoRow(title: "Hours", value: resource.availabilityHours)
                    
                    if !resource.languages.isEmpty {
                        InfoRow(title: "Languages", value: resource.languages.joined(separator: ", "))
                    }
                    
                    if !resource.services.isEmpty {
                        InfoRow(title: "Services", value: resource.services.joined(separator: ", "))
                    }
                    
                    if let address = resource.address {
                        InfoRow(title: "Address", value: address)
                        
                        if let coordinates = resource.coordinates {
                            Button(action: {
                                let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinates))
                                mapItem.name = resource.name
                                mapItem.openInMaps(launchOptions: nil)
                            }) {
                                HStack {
                                    Image(systemName: "map")
                                    Text("Open in Maps")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray6))
                                .foregroundColor(.primary)
                                .cornerRadius(12)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            Text(value)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - ResourceCategory Extension
extension CrisisResource.ResourceCategory: CaseIterable {
    static var allCases: [CrisisResource.ResourceCategory] = [
        .emergency,
        .mentalHealth,
        .addiction,
        .suicide,
        .domesticViolence,
        .lgbtq,
        .veterans,
        .youth
    ]
}
