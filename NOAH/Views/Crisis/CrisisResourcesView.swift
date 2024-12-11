import SwiftUI
import MapKit

struct CrisisResourcesView: View {
    @StateObject private var viewModel = CrisisResourcesViewModel()
    @State private var searchText = ""
    @State private var selectedResource: CrisisResource?
    @State private var showingMap = false
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    LoadingView(message: "Loading resources...")
                } else if let error = viewModel.error {
                    ErrorView(message: error.localizedDescription) {
                        viewModel.fetchResources()
                    }
                } else {
                    List {
                        SearchBar(text: $searchText)
                            .listRowInsets(EdgeInsets())
                        
                        ForEach(viewModel.filteredResources(searchText)) { resource in
                            CrisisResourceCard(resource: resource)
                                .onTapGesture {
                                    selectedResource = resource
                                    AnalyticsService.shared.trackResourceView(
                                        resourceId: resource.id,
                                        resourceName: resource.name
                                    )
                                }
                        }
                    }
                }
            }
            .navigationTitle("Crisis Resources")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingMap.toggle() }) {
                        Image(systemName: "map")
                    }
                }
            }
            .sheet(isPresented: $showingMap) {
                ResourceMapView(resources: viewModel.resources)
            }
            .sheet(item: $selectedResource) { resource in
                ResourceDetailView(resource: resource)
            }
        }
        .onAppear {
            viewModel.fetchResources()
        }
    }
}

struct CrisisResourceCard: View {
    let resource: CrisisResource
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(resource.name)
                .font(.headline)
            
            if !resource.description.isEmpty {
                Text(resource.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Image(systemName: "phone.fill")
                Text(resource.contactNumber)
                
                Spacer()
                
                if resource.isAvailable24x7 {
                    Label("24/7", systemImage: "clock.fill")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            .foregroundColor(.blue)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct ResourceDetailView: View {
    let resource: CrisisResource
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    Text(resource.name)
                        .font(.title)
                        .bold()
                    
                    // Description
                    Text(resource.description)
                        .font(.body)
                    
                    // Contact Information
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Contact", systemImage: "phone.fill")
                            .font(.headline)
                        
                        Button(action: { 
                            guard let url = URL(string: "tel:\(resource.contactNumber)") else { return }
                            UIApplication.shared.open(url)
                            AnalyticsService.shared.trackResourceContact(
                                resourceId: resource.id,
                                resourceName: resource.name,
                                contactType: "phone"
                            )
                        }) {
                            Text(resource.contactNumber)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.top)
                    
                    // Address
                    if let address = resource.address {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Location", systemImage: "location.fill")
                                .font(.headline)
                            
                            Text(address)
                            
                            // Small Map Preview
                            if let coordinate = resource.coordinate {
                                Map(coordinateRegion: .constant(MKCoordinateRegion(
                                    center: coordinate,
                                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                )), annotationItems: [resource]) { resource in
                                    MapMarker(coordinate: resource.coordinate!)
                                }
                                .frame(height: 200)
                                .cornerRadius(12)
                            }
                        }
                        .padding(.top)
                    }
                    
                    // Additional Information
                    if resource.isAvailable24x7 {
                        HStack {
                            Image(systemName: "clock.fill")
                            Text("Available 24/7")
                        }
                        .foregroundColor(.green)
                        .padding(.top)
                    }
                }
                .padding()
            }
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct ResourceMapView: View {
    let resources: [CrisisResource]
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    var body: some View {
        NavigationView {
            Map(coordinateRegion: $region,
                annotationItems: resources.filter { $0.coordinate != nil }) { resource in
                MapAnnotation(coordinate: resource.coordinate!) {
                    VStack {
                        Image(systemName: "cross.circle.fill")
                            .foregroundColor(.red)
                            .font(.title)
                        
                        Text(resource.name)
                            .font(.caption)
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(4)
                    }
                }
            }
            .navigationTitle("Nearby Resources")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
