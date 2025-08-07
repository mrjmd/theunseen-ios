import Foundation
import FirebaseAuth
import FirebaseFirestore

// Test harness for Firebase interactions
class FirebaseTestHarness: ObservableObject {
    @Published var testResults: [TestResult] = []
    @Published var isRunning = false
    
    struct TestResult: Identifiable {
        let id = UUID()
        let testName: String
        let passed: Bool
        let message: String
        let timestamp = Date()
    }
    
    private let authService = AuthService()
    private let firestoreService = FirestoreService()
    private var testUID: String?
    
    // Run all Firebase tests
    func runAllTests() {
        isRunning = true
        testResults.removeAll()
        
        Task {
            await testAnonymousAuth()
            await testUserDocumentCreation()
            await testANIMAUpdate()
            await testSessionLogging()
            await cleanupTestData()
            
            DispatchQueue.main.async {
                self.isRunning = false
                self.printTestSummary()
            }
        }
    }
    
    // Test 1: Anonymous authentication
    @MainActor
    private func testAnonymousAuth() async {
        // AuthService signs in automatically on init, so we just need to wait
        // If already signed in, use existing user, otherwise create new AuthService
        
        if let existingUser = Auth.auth().currentUser {
            // Already signed in
            let passed = existingUser.isAnonymous
            testUID = existingUser.uid
            
            let result = TestResult(
                testName: "Anonymous Authentication",
                passed: passed,
                message: passed ? "Already authenticated with UID: \(existingUser.uid)" : "User exists but not anonymous"
            )
            testResults.append(result)
        } else {
            // Need to sign in - create new AuthService which auto-signs in
            let _ = AuthService()
            
            // Wait for auth to complete
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            
            let user = Auth.auth().currentUser
            let passed = user != nil && user?.isAnonymous == true
            
            if passed {
                testUID = user?.uid
            }
            
            let result = TestResult(
                testName: "Anonymous Authentication",
                passed: passed,
                message: passed ? "Successfully authenticated with UID: \(user?.uid ?? "unknown")" : "Authentication failed"
            )
            testResults.append(result)
        }
    }
    
    // Test 2: User document creation
    @MainActor
    private func testUserDocumentCreation() async {
        guard let uid = testUID else {
            let result = TestResult(
                testName: "User Document Creation",
                passed: false,
                message: "No test UID available"
            )
            testResults.append(result)
            return
        }
        
        // Create user document
        firestoreService.createUserIfNeeded(uid: uid)
        
        // Wait for Firestore operation
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        
        // Verify document exists
        let db = Firestore.firestore()
        do {
            let document = try await db.collection("users").document(uid).getDocument()
            let passed = document.exists
            
            let result = TestResult(
                testName: "User Document Creation",
                passed: passed,
                message: passed ? "User document created successfully" : "Failed to create user document"
            )
            testResults.append(result)
        } catch {
            let result = TestResult(
                testName: "User Document Creation",
                passed: false,
                message: "Error: \(error.localizedDescription)"
            )
            testResults.append(result)
        }
    }
    
    // Test 3: ANIMA points update
    @MainActor
    private func testANIMAUpdate() async {
        guard let uid = testUID else {
            let result = TestResult(
                testName: "ANIMA Update",
                passed: false,
                message: "No test UID available"
            )
            testResults.append(result)
            return
        }
        
        let db = Firestore.firestore()
        
        do {
            // Get initial ANIMA value
            let beforeDoc = try await db.collection("users").document(uid).getDocument()
            let beforePoints = beforeDoc.data()?["animaPoints"] as? Int ?? 0
            
            // Award ANIMA
            firestoreService.awardAnimaForConnection()
            
            // Wait for update
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            
            // Get updated ANIMA value
            let afterDoc = try await db.collection("users").document(uid).getDocument()
            let afterPoints = afterDoc.data()?["animaPoints"] as? Int ?? 0
            
            let passed = afterPoints > beforePoints
            let difference = afterPoints - beforePoints
            
            let result = TestResult(
                testName: "ANIMA Update",
                passed: passed,
                message: passed ? "ANIMA increased by \(difference) points" : "ANIMA update failed"
            )
            testResults.append(result)
        } catch {
            let result = TestResult(
                testName: "ANIMA Update",
                passed: false,
                message: "Error: \(error.localizedDescription)"
            )
            testResults.append(result)
        }
    }
    
    // Test 4: Session logging (placeholder for Cloud Functions)
    @MainActor
    private func testSessionLogging() async {
        guard let uid = testUID else {
            let result = TestResult(
                testName: "Session Logging",
                passed: false,
                message: "No test UID available"
            )
            testResults.append(result)
            return
        }
        
        // For now, just test that we can write a session document
        let db = Firestore.firestore()
        let sessionId = UUID().uuidString
        
        let sessionData: [String: Any] = [
            "userA_Id": uid,
            "userB_Id": "mock_peer_id",
            "userA_Resonance": 8.5,
            "userB_Resonance": 9.0,
            "status": "test",
            "createdAt": Timestamp(date: Date())
        ]
        
        do {
            try await db.collection("sessions").document(sessionId).setData(sessionData)
            
            // Verify it was created
            let document = try await db.collection("sessions").document(sessionId).getDocument()
            let passed = document.exists
            
            // Clean up test session
            if passed {
                try await db.collection("sessions").document(sessionId).delete()
            }
            
            let result = TestResult(
                testName: "Session Logging",
                passed: passed,
                message: passed ? "Session document created and cleaned up" : "Failed to create session document"
            )
            testResults.append(result)
        } catch {
            let result = TestResult(
                testName: "Session Logging",
                passed: false,
                message: "Error: \(error.localizedDescription)"
            )
            testResults.append(result)
        }
    }
    
    // Cleanup test data
    @MainActor
    private func cleanupTestData() async {
        guard let uid = testUID else { return }
        
        let db = Firestore.firestore()
        
        do {
            // Delete test user document
            try await db.collection("users").document(uid).delete()
            
            // Sign out
            try Auth.auth().signOut()
            
            let result = TestResult(
                testName: "Cleanup",
                passed: true,
                message: "Test data cleaned up successfully"
            )
            testResults.append(result)
        } catch {
            let result = TestResult(
                testName: "Cleanup",
                passed: false,
                message: "Cleanup error: \(error.localizedDescription)"
            )
            testResults.append(result)
        }
    }
    
    // Print test summary
    private func printTestSummary() {
        print("\n" + String(repeating: "=", count: 50))
        print("FIREBASE TEST SUMMARY")
        print(String(repeating: "=", count: 50))
        
        let passed = testResults.filter { $0.passed }.count
        let total = testResults.count
        let percentage = total > 0 ? (Double(passed) / Double(total)) * 100 : 0
        
        for result in testResults {
            let icon = result.passed ? "✅" : "❌"
            print("\(icon) \(result.testName): \(result.message)")
        }
        
        print(String(repeating: "-", count: 50))
        print("Results: \(passed)/\(total) passed (\(String(format: "%.1f", percentage))%)")
        print(String(repeating: "=", count: 50) + "\n")
    }
}

// Test UI View for Firebase tests
import SwiftUI

struct FirebaseTestView: View {
    @StateObject private var testHarness = FirebaseTestHarness()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Firebase Test Harness")
                .font(.largeTitle)
                .padding()
            
            if testHarness.isRunning {
                ProgressView("Running tests...")
                    .progressViewStyle(CircularProgressViewStyle())
            } else {
                Button(action: {
                    testHarness.runAllTests()
                }) {
                    Text("Run All Tests")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(10)
                }
            }
            
            List(testHarness.testResults) { result in
                HStack {
                    Image(systemName: result.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(result.passed ? .green : .red)
                    
                    VStack(alignment: .leading) {
                        Text(result.testName)
                            .font(.headline)
                        Text(result.message)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    FirebaseTestView()
}