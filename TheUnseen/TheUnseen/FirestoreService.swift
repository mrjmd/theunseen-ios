import Foundation
import FirebaseFirestore
import FirebaseAuth
import FirebaseCrashlytics
import FirebasePerformance

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
    
    // Add current user to session participants (for migration of old sessions)
    func addSelfToSession(sessionId: String, userId: String, artifact: String? = nil) {
        let sessionRef = db.collection("sessions").document(sessionId)
        
        // For migration: Try to read first, if that fails try to create
        sessionRef.getDocument { document, error in
            if let error = error {
                // Can't read - might not exist or no permissions
                // Try to create it with ourselves
                let sessionData: [String: Any] = [
                    "sessionId": sessionId,
                    "participants": [userId],
                    "artifact": artifact ?? "",
                    "createdAt": FieldValue.serverTimestamp(),
                    "status": "active"
                ]
                
                sessionRef.setData(sessionData, merge: false) { error in
                    if let error = error {
                        print("❌ Error creating session: \(error)")
                        // If creation fails, try to update by adding ourselves
                        sessionRef.updateData([
                            "participants": FieldValue.arrayUnion([userId])
                        ]) { updateError in
                            if let updateError = updateError {
                                print("❌ Error adding self to session: \(updateError)")
                            } else {
                                print("✅ Added self to existing session: \(sessionId)")
                            }
                        }
                    } else {
                        print("✅ Created session with self as participant: \(sessionId)")
                    }
                }
            } else if let document = document, document.exists {
                // Session exists and we can read it
                if let existingParticipants = document.data()?["participants"] as? [String] {
                    if !existingParticipants.contains(userId) {
                        // Add ourselves to existing participants
                        sessionRef.updateData([
                            "participants": FieldValue.arrayUnion([userId])
                        ]) { error in
                            if let error = error {
                                print("❌ Error adding self to session: \(error)")
                            } else {
                                print("✅ Added self to session participants: \(sessionId)")
                            }
                        }
                    } else {
                        print("✅ Already in session participants: \(sessionId)")
                    }
                } else {
                    // No participants field - add it with just us
                    sessionRef.updateData([
                        "participants": [userId]
                    ]) { error in
                        if let error = error {
                            print("❌ Error setting participants: \(error)")
                        } else {
                            print("✅ Set session participants with self: \(sessionId)")
                        }
                    }
                }
                
                // Update artifact if provided and missing
                if let artifact = artifact, !artifact.isEmpty,
                   (document.data()?["artifact"] as? String ?? "").isEmpty {
                    sessionRef.updateData(["artifact": artifact]) { _ in }
                }
            } else {
                // Document doesn't exist - create it
                let sessionData: [String: Any] = [
                    "sessionId": sessionId,
                    "participants": [userId],
                    "artifact": artifact ?? "",
                    "createdAt": FieldValue.serverTimestamp(),
                    "status": "active"
                ]
                
                sessionRef.setData(sessionData) { error in
                    if let error = error {
                        print("❌ Error creating session: \(error)")
                    } else {
                        print("✅ Created session with self as participant: \(sessionId)")
                    }
                }
            }
        }
    }
    
    // Create a session document with participant IDs for security
    func createSession(sessionId: String, participantIds: [String], artifact: String? = nil) {
        let sessionRef = db.collection("sessions").document(sessionId)
        
        // First check if session exists
        sessionRef.getDocument { document, error in
            if let document = document, document.exists {
                // Session exists - update participants if needed
                var updates: [String: Any] = [:]
                
                // Check if participants field exists and has all required UIDs
                if let existingParticipants = document.data()?["participants"] as? [String] {
                    let missingParticipants = participantIds.filter { !existingParticipants.contains($0) }
                    if !missingParticipants.isEmpty {
                        // Merge participants
                        let mergedParticipants = Array(Set(existingParticipants + participantIds))
                        updates["participants"] = mergedParticipants
                        print("🔄 Updating session participants: \(mergedParticipants)")
                    }
                } else {
                    // No participants field - add it
                    updates["participants"] = participantIds
                    print("🔄 Adding participants to existing session: \(participantIds)")
                }
                
                // Update artifact if provided and not already set
                if let artifact = artifact, !artifact.isEmpty,
                   (document.data()?["artifact"] as? String ?? "").isEmpty {
                    updates["artifact"] = artifact
                }
                
                // Apply updates if needed
                if !updates.isEmpty {
                    sessionRef.updateData(updates) { error in
                        if let error = error {
                            print("❌ Error updating session: \(error)")
                        } else {
                            print("✅ Session updated: \(sessionId)")
                        }
                    }
                } else {
                    print("✅ Session already exists with correct participants: \(sessionId)")
                }
            } else {
                // Session doesn't exist - create it
                let sessionData: [String: Any] = [
                    "sessionId": sessionId,
                    "participants": participantIds,
                    "artifact": artifact ?? "",
                    "createdAt": FieldValue.serverTimestamp(),
                    "status": "active"
                ]
                
                sessionRef.setData(sessionData) { error in
                    if let error = error {
                        print("❌ Error creating session: \(error)")
                    } else {
                        print("✅ Session created: \(sessionId) with participants: \(participantIds)")
                    }
                }
            }
        }
    }
    
    // MARK: - Block/Report Safety Features
    
    func blockUser(_ blockedUID: String, reason: String? = nil, context: String? = nil, sessionId: String? = nil) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Add to user's blocked list
        db.collection("users").document(userId).updateData([
            "blockedUsers": FieldValue.arrayUnion([blockedUID])
        ]) { error in
            if let error = error {
                print("❌ Error blocking user: \(error)")
            } else {
                print("✅ User blocked: \(blockedUID)")
            }
        }
        
        // If there's a reason, create a report
        if let reason = reason {
            createReport(
                reporterUID: userId,
                reportedUID: blockedUID,
                reason: reason,
                context: context,
                sessionId: sessionId
            )
        }
    }
    
    private func createReport(reporterUID: String, reportedUID: String, reason: String, context: String?, sessionId: String?) {
        let reportData: [String: Any] = [
            "reporterUID": reporterUID,
            "reportedUID": reportedUID,
            "reason": reason,
            "context": context ?? "",
            "sessionId": sessionId ?? "",
            "timestamp": FieldValue.serverTimestamp(),
            "status": "pending" // For Shadow Council review
        ]
        
        db.collection("reports").addDocument(data: reportData) { error in
            if let error = error {
                print("❌ Error creating report: \(error)")
            } else {
                print("✅ Report submitted for review")
            }
        }
    }
    
    func getBlockedUsers(completion: @escaping ([String]) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion([])
            return
        }
        
        db.collection("users").document(userId).getDocument { document, error in
            if let document = document, document.exists,
               let blockedUsers = document.data()?["blockedUsers"] as? [String] {
                completion(blockedUsers)
            } else {
                completion([])
            }
        }
    }
    
    // Save reflection and scores for The Integration
    func saveReflection(sessionId: String, reflection: String, promptIndex: Int, 
                       presenceScore: Int, courageScore: Int, mirrorScore: Int, partnerId: String? = nil) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Start performance trace
        let trace = Performance.startTrace(name: "save_reflection")
        
        // First ensure user is in session participants (for migration)
        let sessionRef = db.collection("sessions").document(sessionId)
        sessionRef.getDocument { document, error in
            if let document = document, !document.exists {
                // Create session if it doesn't exist
                var participants = [userId]
                if let partnerId = partnerId {
                    participants.append(partnerId)
                }
                self.createSession(sessionId: sessionId, participantIds: participants)
            } else if let document = document, document.exists {
                // Add ourselves to participants if not already there
                if let existingParticipants = document.data()?["participants"] as? [String],
                   !existingParticipants.contains(userId) {
                    sessionRef.updateData([
                        "participants": FieldValue.arrayUnion([userId])
                    ]) { _ in }
                }
            }
        }
        
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
                trace?.stop()
                if let error = error {
                    print("❌ Error saving reflection: \(error)")
                    Crashlytics.crashlytics().record(error: error)
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
        
        // Start performance trace
        let trace = Performance.startTrace(name: "anima_calculation")
        
        let sessionRef = db.collection("sessions").document(sessionId)
        
        // Get both users' reflections
        sessionRef.collection("reflections").getDocuments { snapshot, error in
            guard let documents = snapshot?.documents, documents.count == 2 else {
                print("⏳ Waiting for both users to submit reflections")
                trace?.stop()
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
                trace?.stop()
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
            
            trace?.stop()
            completion(finalANIMA)
        }
    }
}
