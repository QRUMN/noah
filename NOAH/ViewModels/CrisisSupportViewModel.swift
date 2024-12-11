import SwiftUI
import CoreLocation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class CrisisSupportViewModel: NSObject, ObservableObject {
    @Published var safetyPlan: SafetyPlan?
    @Published var emergencyContacts: [EmergencyContact] = []
    @Published var crisisResources: [CrisisResource] = []
    @Published var nearbyServices: [EmergencyService] = []
    @Published var helplines: [Helpline] = []
    
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage: String?
    @Published var showingEmergencyCall = false
    
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var locationAuthorizationStatus: CLAuthorizationStatus = .notDetermined
    
    private let db = Firestore.firestore()
    private let locationManager = CLLocationManager()
    private let emergencyNumber = "911"
    
    override init() {
        super.init()
        locationManager.delegate = self
        setupLocationServices()
        loadInitialData()
    }
    
    // MARK: - Location Services
    
    private func setupLocationServices() {
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    // MARK: - Data Loading
    
    private func loadInitialData() {
        Task {
            await fetchSafetyPlan()
            await fetchEmergencyContacts()
            await fetchCrisisResources()
            await fetchHelplines()
        }
    }
    
    func refreshData() async {
        isLoading = true
        defer { isLoading = false }
        
        await loadInitialData()
        if let location = userLocation {
            await fetchNearbyServices(coordinates: location)
        }
    }
    
    // MARK: - Safety Plan
    
    func fetchSafetyPlan() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        do {
            let document = try await db.collection("safetyPlans")
                .whereField("userId", isEqualTo: userId)
                .getDocuments()
            
            if let data = document.documents.first?.data(),
               let plan = try? Firestore.Decoder().decode(SafetyPlan.self, from: data) {
                safetyPlan = plan
            }
        } catch {
            showError(message: "Failed to fetch safety plan")
        }
    }
    
    func saveSafetyPlan(_ plan: SafetyPlan) async {
        do {
            try await db.collection("safetyPlans")
                .document(plan.id)
                .setData(try Firestore.Encoder().encode(plan))
            safetyPlan = plan
        } catch {
            showError(message: "Failed to save safety plan")
        }
    }
    
    // MARK: - Emergency Contacts
    
    func fetchEmergencyContacts() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        do {
            let snapshot = try await db.collection("emergencyContacts")
                .whereField("userId", isEqualTo: userId)
                .getDocuments()
            
            emergencyContacts = snapshot.documents.compactMap { document in
                try? Firestore.Decoder().decode(EmergencyContact.self, from: document.data())
            }
        } catch {
            showError(message: "Failed to fetch emergency contacts")
        }
    }
    
    func saveEmergencyContact(_ contact: EmergencyContact) async {
        do {
            try await db.collection("emergencyContacts")
                .document(contact.id)
                .setData(try Firestore.Encoder().encode(contact))
            await fetchEmergencyContacts()
        } catch {
            showError(message: "Failed to save emergency contact")
        }
    }
    
    // MARK: - Crisis Resources
    
    func fetchCrisisResources() async {
        do {
            let snapshot = try await db.collection("crisisResources")
                .getDocuments()
            
            crisisResources = snapshot.documents.compactMap { document in
                try? Firestore.Decoder().decode(CrisisResource.self, from: document.data())
            }
        } catch {
            showError(message: "Failed to fetch crisis resources")
        }
    }
    
    // MARK: - Nearby Services
    
    func fetchNearbyServices(coordinates: CLLocationCoordinate2D) async {
        do {
            let snapshot = try await db.collection("emergencyServices")
                .getDocuments()
            
            let services: [EmergencyService] = snapshot.documents.compactMap { document in
                try? Firestore.Decoder().decode(EmergencyService.self, from: document.data())
            }
            
            // Calculate distances and sort by proximity
            nearbyServices = services.map { service in
                var updatedService = service
                updatedService.distance = calculateDistance(from: coordinates, to: service.coordinates)
                return updatedService
            }
            .sorted { $0.distance ?? 0 < $1.distance ?? 0 }
        } catch {
            showError(message: "Failed to fetch nearby services")
        }
    }
    
    // MARK: - Helplines
    
    func fetchHelplines() async {
        do {
            let snapshot = try await db.collection("helplines")
                .getDocuments()
            
            helplines = snapshot.documents.compactMap { document in
                try? Firestore.Decoder().decode(Helpline.self, from: document.data())
            }
        } catch {
            showError(message: "Failed to fetch helplines")
        }
    }
    
    // MARK: - Emergency Actions
    
    func callEmergencyServices() {
        guard let url = URL(string: "tel://\(emergencyNumber)") else { return }
        UIApplication.shared.open(url)
    }
    
    func callHelpline(_ helpline: Helpline) {
        guard let url = URL(string: "tel://\(helpline.phoneNumber)") else { return }
        UIApplication.shared.open(url)
    }
    
    func textHelpline(_ helpline: Helpline) {
        guard let smsNumber = helpline.smsNumber,
              let url = URL(string: "sms://\(smsNumber)") else { return }
        UIApplication.shared.open(url)
    }
    
    // MARK: - Helper Methods
    
    private func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> CLLocationDistance {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation)
    }
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}

// MARK: - Location Manager Delegate
extension CrisisSupportViewModel: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        locationAuthorizationStatus = manager.authorizationStatus
        
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first?.coordinate else { return }
        userLocation = location
        
        Task {
            await fetchNearbyServices(coordinates: location)
        }
        
        locationManager.stopUpdatingLocation()
    }
}
