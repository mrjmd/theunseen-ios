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
                // Also update UserDefaults for immediate UI update
                let currentBalance = UserDefaults.standard.integer(forKey: "animaBalance")
                UserDefaults.standard.set(currentBalance + connectionAnima, forKey: "animaBalance")
            }
        }
    }
    
    // Save reflection and scores for The Integration
    func saveReflection(sessionId: String, reflection: String, promptIndex: Int, 
                       presenceScore: Int, courageScore: Int, mirrorScore: Int) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let reflectionData: [String: Any] = [
            "userId": userId,
            "sessionId": sessionId,
            "reflection": reflection,
            "promptIndex": promptIndex,
            "presenceScore": presenceScore,
            "courageScore": courageScore,
            "mirrorScore": mirrorScore,
            "timestamp": FieldValue.serverTimestamp()
        ]
        
        // Save to sessions collection
        db.collection("sessions").document(sessionId)
            .collection("reflections").document(userId)
            .setData(reflectionData) { error in
                if let error = error {
                    print("❌ Error saving reflection: \(error)")
                } else {
                    print("✅ Reflection saved for session \(sessionId)")
                }
            }
    }
    
    // Calculate and award ANIMA based on resonance scores
    func calculateResonanceMultiplier(sessionId: String, completion: @escaping (Int) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else { 
            completion(0)
            return 
        }
        
        let sessionRef = db.collection("sessions").document(sessionId)
        
        // Get both users' reflections
        sessionRef.collection("reflections").getDocuments { snapshot, error in
            guard let documents = snapshot?.documents, documents.count == 2 else {
                print("⏳ Waiting for both users to submit reflections")
                completion(0)
                return
            }
            
            // Extract scores from both users
            var mirrorScores: [Int] = []
            var courageScores: [Int] = []
            var presenceScores: [Int] = []
            
            for doc in documents {
                let data = doc.data()
                if let mirror = data["mirrorScore"] as? Int {
                    mirrorScores.append(mirror)
                }
                if let courage = data["courageScore"] as? Int {
                    courageScores.append(courage)
                }
                if let presence = data["presenceScore"] as? Int {
                    presenceScores.append(presence)
                }
            }
            
            guard mirrorScores.count == 2, courageScores.count == 2 else {
                completion(0)
                return
            }
            
            // Calculate average courage score for shared bonus
            let averageCourageScore = (courageScores[0] + courageScores[1]) / 2
            
            // Calculate multiplier based on lower mirror score (shared resonance)
            let sharedMirrorScore = min(mirrorScores[0], mirrorScores[1])
            let multiplier: Double
            
            switch sharedMirrorScore {
            case 0...50:
                multiplier = 1.0
            case 51...80:
                multiplier = 1.5
            case 81...95:
                multiplier = 2.0
            case 96...100:
                multiplier = 3.0  // The jackpot!
            default:
                multiplier = 1.0
            }
            
            // Calculate final ANIMA (same for both users)
            let baseANIMA = 50
            let courageBonus = averageCourageScore  // Use average courage score
            let totalBeforeMultiplier = baseANIMA + courageBonus
            let finalANIMA = Int(Double(totalBeforeMultiplier) * multiplier)
            
            // Award the ANIMA
            let userRef = self.db.collection("users").document(userId)
            userRef.updateData([
                "animaPoints": FieldValue.increment(Int64(finalANIMA))
            ]) { error in
                if let error = error {
                    print("❌ Error awarding resonance ANIMA: \(error)")
                } else {
                    print("✨ Awarded \(finalANIMA) ANIMA (base: \(baseANIMA), courage: \(courageBonus), multiplier: \(multiplier)x)")
                }
            }
            
            completion(finalANIMA)
        }
    }
}
