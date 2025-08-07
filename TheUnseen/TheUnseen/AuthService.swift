import Foundation
import FirebaseAuth

// This service will manage the user's authentication state.
class AuthService: ObservableObject {
    
    // We will publish the user object. Any view or service can subscribe to this
    // to know when the user signs in or out.
    @Published var user: User?

    init() {
        // When the service is created, immediately try to sign in.
        Auth.auth().signInAnonymously { [weak self] (authResult, error) in
            if let error = error {
                print("Error signing in anonymously: \(error)")
                return
            }
            
            guard let user = authResult?.user else { return }
            print("✅ Anonymous user signed in with UID: \(user.uid)")
            
            // Update our published property. This will notify the rest of the app.
            self?.user = user
        }
    }
}
