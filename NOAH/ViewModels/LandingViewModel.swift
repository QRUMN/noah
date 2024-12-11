import SwiftUI

class LandingViewModel: ObservableObject {
    @Published var isLoading = false
    
    func continueAsGuest() {
        // TODO: Implement guest user flow
        print("Continue as guest tapped")
    }
}
