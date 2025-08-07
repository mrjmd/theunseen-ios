import Foundation
import LocalAuthentication
import FirebaseAuth

class BiometricAuthService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var biometricType: LABiometryType = .none
    @Published var authenticationError: String?
    
    private let context = LAContext()
    private let keychainKey = "TheUnseen.AnonymousUID"
    
    init() {
        checkBiometricAvailability()
    }
    
    // Check what type of biometric is available
    private func checkBiometricAvailability() {
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            biometricType = context.biometryType
        } else {
            biometricType = .none
            if let error = error {
                print("Biometric authentication not available: \(error.localizedDescription)")
            }
        }
    }
    
    // Authenticate with biometrics
    func authenticateWithBiometrics(completion: @escaping (Bool, String?) -> Void) {
        let reason = "Authenticate to enter The Unseen and access your Initiate profile"
        
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    self?.isAuthenticated = true
                    self?.authenticationError = nil
                    print("✅ Biometric authentication successful")
                    completion(true, nil)
                } else {
                    self?.isAuthenticated = false
                    let errorMessage = error?.localizedDescription ?? "Unknown error"
                    self?.authenticationError = errorMessage
                    print("❌ Biometric authentication failed: \(errorMessage)")
                    completion(false, errorMessage)
                }
            }
        }
    }
    
    // Get biometric icon name for UI
    var biometricIconName: String {
        switch biometricType {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        default:
            return "lock.fill"
        }
    }
    
    // Get biometric type name for UI
    var biometricTypeName: String {
        switch biometricType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        default:
            return "Passcode"
        }
    }
    
    // Store anonymous UID in keychain after successful biometric auth
    func storeUIDInKeychain(_ uid: String) {
        let data = uid.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainKey,
            kSecValueData as String: data
        ]
        
        // Delete any existing item
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        if status == errSecSuccess {
            print("✅ UID stored securely in keychain")
        } else {
            print("❌ Failed to store UID in keychain: \(status)")
        }
    }
    
    // Retrieve anonymous UID from keychain
    func retrieveUIDFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainKey,
            kSecReturnData as String: true
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess,
           let data = dataTypeRef as? Data,
           let uid = String(data: data, encoding: .utf8) {
            print("✅ UID retrieved from keychain")
            return uid
        } else {
            print("ℹ️ No stored UID in keychain")
            return nil
        }
    }
    
    // Clear stored credentials (for logout/reset)
    func clearStoredCredentials() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainKey
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        if status == errSecSuccess {
            print("✅ Credentials cleared from keychain")
        }
        
        isAuthenticated = false
    }
}