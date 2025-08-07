import Foundation
import FirebaseAuth

// This service will manage the user's authentication state.
class AuthService: ObservableObject {
    
    // We will publish the user object. Any view or service can subscribe to this
    // to know when the user signs in or out.
    @Published var user: User?
    @Published var isAuthenticating = false
    
    private let biometricService = BiometricAuthService()
    
    init() {
        // Don't auto-sign in anymore - wait for biometric auth
        checkExistingAuth()
    }
    
    // Check if user is already signed in
    private func checkExistingAuth() {
        if let currentUser = Auth.auth().currentUser {
            print("ℹ️ User already signed in: \(currentUser.uid)")
            self.user = currentUser
        }
    }
    
    // Sign in with biometric authentication
    func signInWithBiometrics(completion: @escaping (Bool, String?) -> Void) {
        isAuthenticating = true
        
        // First, authenticate with biometrics
        biometricService.authenticateWithBiometrics { [weak self] biometricSuccess, biometricError in
            guard let self = self else { return }
            
            if biometricSuccess {
                // Check if we have a stored UID
                if let storedUID = self.biometricService.retrieveUIDFromKeychain() {
                    // Try to use existing anonymous account
                    self.signInWithStoredUID(storedUID, completion: completion)
                } else {
                    // Create new anonymous account
                    self.createNewAnonymousUser(completion: completion)
                }
            } else {
                self.isAuthenticating = false
                completion(false, biometricError)
            }
        }
    }
    
    // Sign in with stored UID (returning user)
    private func signInWithStoredUID(_ uid: String, completion: @escaping (Bool, String?) -> Void) {
        // For anonymous users, we can't directly sign in with UID
        // Check if already signed in with this UID
        if let currentUser = Auth.auth().currentUser, currentUser.uid == uid {
            self.user = currentUser
            self.isAuthenticating = false
            print("✅ Already signed in with stored UID: \(uid)")
            completion(true, nil)
        } else {
            // Need to create new anonymous session (UID will be different)
            // This is a limitation of Firebase anonymous auth
            createNewAnonymousUser(completion: completion)
        }
    }
    
    // Create new anonymous user
    private func createNewAnonymousUser(completion: @escaping (Bool, String?) -> Void) {
        Auth.auth().signInAnonymously { [weak self] (authResult, error) in
            guard let self = self else { return }
            
            self.isAuthenticating = false
            
            if let error = error {
                print("❌ Error signing in anonymously: \(error)")
                completion(false, error.localizedDescription)
                return
            }
            
            guard let user = authResult?.user else {
                completion(false, "Failed to create user")
                return
            }
            
            print("✅ New anonymous user created with UID: \(user.uid)")
            
            // Store the UID in keychain for future sessions
            self.biometricService.storeUIDInKeychain(user.uid)
            
            // Update our published property
            self.user = user
            completion(true, nil)
        }
    }
    
    // Sign out
    func signOut() {
        do {
            try Auth.auth().signOut()
            self.user = nil
            // Don't clear keychain on signout - keep for next session
            print("✅ User signed out")
        } catch {
            print("❌ Error signing out: \(error)")
        }
    }
}
