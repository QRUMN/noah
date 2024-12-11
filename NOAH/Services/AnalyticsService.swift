import Foundation
import FirebaseAnalytics
import FirebaseFirestore

class AnalyticsService {
    static let shared = AnalyticsService()
    private let db = Firestore.firestore()
    
    private init() {}
    
    func trackResourceView(resourceId: String, resourceName: String) {
        // Firebase Analytics
        Analytics.logEvent("resource_viewed", parameters: [
            "resource_id": resourceId,
            "resource_name": resourceName
        ])
        
        // Store in Firestore for admin dashboard
        let analyticsRef = db.collection("analytics").document("resources")
        analyticsRef.updateData([
            "views.\(resourceId)": FieldValue.increment(Int64(1))
        ]) { error in
            if error != nil {
                // If document doesn't exist, create it
                analyticsRef.setData([
                    "views": [resourceId: 1],
                    "lastUpdated": FieldValue.serverTimestamp()
                ])
            }
        }
    }
    
    func trackResourceContact(resourceId: String, resourceName: String, contactType: String) {
        // Firebase Analytics
        Analytics.logEvent("resource_contacted", parameters: [
            "resource_id": resourceId,
            "resource_name": resourceName,
            "contact_type": contactType
        ])
        
        // Store in Firestore for admin dashboard
        let analyticsRef = db.collection("analytics").document("resources")
        analyticsRef.updateData([
            "contacts.\(resourceId)": FieldValue.increment(Int64(1))
        ]) { error in
            if error != nil {
                // If document doesn't exist, create it
                analyticsRef.setData([
                    "contacts": [resourceId: 1],
                    "lastUpdated": FieldValue.serverTimestamp()
                ])
            }
        }
    }
    
    func trackSearch(query: String, resultsCount: Int) {
        Analytics.logEvent("resource_search", parameters: [
            "search_query": query,
            "results_count": resultsCount
        ])
    }
}
