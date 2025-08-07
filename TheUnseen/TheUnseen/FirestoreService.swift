import Foundation
import FirebaseFirestore
import FirebaseAuth

// Converted to an ObservableObject to fit the new architecture.
class FirestoreService: ObservableObject {
    
    private lazy var db = Firestore.firestore()

    func createUserIfNeeded(uid: String) {
        let userRef = db.collection("users").document(uid)
        
        userRef.getDocument { (document, error) in
            if let document = document, document.exists {
                print("User document already exists for UID: \(uid)")
            } else {
                print("Creating new user document for UID: \(uid)")
                let initialData: [String: Any] = [
                    "uid": uid,
                    "level": 1,
                    "animaPoints": 100,
                    "createdAt": Timestamp(date: Date())
                ]
                
                userRef.setData(initialData) { err in
                    if let err = err {
                        print("Error writing user document: \(err)")
                    } else {
                        print("✅ User document successfully written!")
                    }
                }
            }
        }
    }
    
    func awardAnimaForConnection() {
        guard let user = Auth.auth().currentUser else {
            print("Error: Cannot award ANIMA, no user is signed in.")
            return
        }
        
        let userRef = db.collection("users").document(user.uid)
        let connectionAnima = 10
        
        userRef.updateData([
            "animaPoints": FieldValue.increment(Int64(connectionAnima))
        ]) { err in
            if let err = err {
                print("Error updating ANIMA points: \(err)")
            } else {
                print(" awarded \(connectionAnima) ANIMA for connection.")
            }
        }
    }
}
