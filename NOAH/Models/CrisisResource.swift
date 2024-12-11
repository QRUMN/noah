import SwiftUI
import CoreLocation

struct CrisisResource: Identifiable {
    let id: String
    let name: String
    let description: String
    let contactNumber: String
    let address: String?
    let isAvailable24x7: Bool
    let coordinate: CLLocationCoordinate2D?
}

extension CrisisResource: Hashable {
    static func == (lhs: CrisisResource, rhs: CrisisResource) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
