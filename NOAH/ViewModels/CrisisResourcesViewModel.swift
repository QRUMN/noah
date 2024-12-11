import SwiftUI
import FirebaseFirestore
import CoreLocation

class CrisisResourcesViewModel: ObservableObject {
    @Published var resources: [CrisisResource] = []
    @Published var isLoading = false
    @Published var error: Error?
    private let db = Firestore.firestore()
    
    func fetchResources() {
        isLoading = true
        error = nil
        
        db.collection("crisisResources")
            .whereField("isActive", isEqualTo: true)
            .getDocuments { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = error {
                        self?.error = error
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        self?.error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No resources found"])
                        return
                    }
                    
                    self?.resources = documents.compactMap { document -> CrisisResource? in
                        let data = document.data()
                        
                        var coordinate: CLLocationCoordinate2D?
                        if let geoPoint = data["location"] as? GeoPoint {
                            coordinate = CLLocationCoordinate2D(
                                latitude: geoPoint.latitude,
                                longitude: geoPoint.longitude
                            )
                        }
                        
                        return CrisisResource(
                            id: document.documentID,
                            name: data["name"] as? String ?? "",
                            description: data["description"] as? String ?? "",
                            contactNumber: data["contactNumber"] as? String ?? "",
                            address: data["address"] as? String,
                            isAvailable24x7: data["isAvailable24x7"] as? Bool ?? false,
                            coordinate: coordinate
                        )
                    }
                    
                    if self?.resources.isEmpty == true {
                        self?.error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No active crisis resources found"])
                    }
                }
            }
    }
    
    func filteredResources(_ searchText: String) -> [CrisisResource] {
        if searchText.isEmpty {
            return resources
        }
        let filtered = resources.filter { resource in
            resource.name.localizedCaseInsensitiveContains(searchText) ||
            resource.description.localizedCaseInsensitiveContains(searchText)
        }
        AnalyticsService.shared.trackSearch(query: searchText, resultsCount: filtered.count)
        return filtered
    }
}
