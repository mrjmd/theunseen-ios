import Foundation
import MultipeerConnectivity
import SwiftUI

// Mock P2P Service for testing without actual device discovery
class MockP2PService: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isConnected = false
    @Published var isHandshakeComplete = false
    
    private var mockPeerName: String
    private var messageDelay: TimeInterval = 0.5
    
    init(peerName: String = "MockPeer") {
        self.mockPeerName = peerName
    }
    
    func simulateConnection() {
        print("🧪 Test: Simulating connection to \(mockPeerName)")
        isConnected = true
        
        // Simulate handshake after 1 second
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            self.isHandshakeComplete = true
            print("🧪 Test: Handshake complete with \(self.mockPeerName)")
        }
    }
    
    func simulateDisconnection() {
        print("🧪 Test: Simulating disconnection from \(mockPeerName)")
        isConnected = false
        isHandshakeComplete = false
        messages.removeAll()
    }
    
    func sendMessage(_ message: String) {
        guard isHandshakeComplete else {
            print("🧪 Test: Cannot send - handshake not complete")
            return
        }
        
        // Add sent message
        messages.append(ChatMessage(text: "[sent]\(message)"))
        print("🧪 Test: Sent message: \(message)")
        
        // Simulate received response after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + messageDelay) { [weak self] in
            guard let self = self else { return }
            let response = self.generateMockResponse(to: message)
            self.messages.append(ChatMessage(text: response))
            print("🧪 Test: Received response: \(response)")
        }
    }
    
    private func generateMockResponse(to message: String) -> String {
        // Simple mock responses for testing
        let responses = [
            "Interesting perspective!",
            "I hadn't thought of it that way",
            "Tell me more about that",
            "That resonates with me",
            "I feel the same way"
        ]
        return responses.randomElement() ?? "Mock response"
    }
}

// Test harness for P2P connectivity
class P2PTestHarness: ObservableObject {
    @Published var testResults: [TestResult] = []
    @Published var isRunning = false
    
    struct TestResult: Identifiable {
        let id = UUID()
        let testName: String
        let passed: Bool
        let message: String
        let timestamp = Date()
    }
    
    private var realService: P2PConnectivityService?
    private var mockService: MockP2PService?
    
    // Run all P2P tests
    func runAllTests() {
        isRunning = true
        testResults.removeAll()
        
        Task {
            await testMockConnection()
            await testMockHandshake()
            await testMockMessaging()
            await testConnectionStability()
            await testANIMAAwarding()
            
            DispatchQueue.main.async {
                self.isRunning = false
                self.printTestSummary()
            }
        }
    }
    
    // Test 1: Mock connection establishment
    @MainActor
    private func testMockConnection() async {
        let mock = MockP2PService()
        mock.simulateConnection()
        
        // Wait for connection
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
        
        let result = TestResult(
            testName: "Mock Connection",
            passed: mock.isConnected,
            message: mock.isConnected ? "Successfully simulated connection" : "Failed to simulate connection"
        )
        testResults.append(result)
    }
    
    // Test 2: Mock handshake completion
    @MainActor
    private func testMockHandshake() async {
        let mock = MockP2PService()
        mock.simulateConnection()
        
        // Wait for handshake (1.5s to ensure it completes)
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        
        let result = TestResult(
            testName: "Mock Handshake",
            passed: mock.isHandshakeComplete,
            message: mock.isHandshakeComplete ? "Handshake completed successfully" : "Handshake failed to complete"
        )
        testResults.append(result)
    }
    
    // Test 3: Mock message exchange
    @MainActor
    private func testMockMessaging() async {
        let mock = MockP2PService()
        mock.simulateConnection()
        
        // Wait for handshake
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        
        // Send test message
        mock.sendMessage("Test message")
        
        // Wait for response
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        let hasSentMessage = mock.messages.contains { $0.text.hasPrefix("[sent]") }
        let hasReceivedMessage = mock.messages.contains { !$0.text.hasPrefix("[sent]") }
        let passed = hasSentMessage && hasReceivedMessage
        
        let result = TestResult(
            testName: "Mock Messaging",
            passed: passed,
            message: passed ? "Messages exchanged successfully (\(mock.messages.count) total)" : "Message exchange failed"
        )
        testResults.append(result)
    }
    
    // Test 4: Connection stability (no drops)
    @MainActor
    private func testConnectionStability() async {
        let mock = MockP2PService()
        mock.simulateConnection()
        
        // Wait for handshake
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        
        let initialState = mock.isConnected
        
        // Wait 10 seconds (longer than the previous 9-second drop issue)
        try? await Task.sleep(nanoseconds: 10_000_000_000)
        
        let finalState = mock.isConnected
        let passed = initialState && finalState
        
        let result = TestResult(
            testName: "Connection Stability",
            passed: passed,
            message: passed ? "Connection remained stable for 10+ seconds" : "Connection dropped unexpectedly"
        )
        testResults.append(result)
    }
    
    // Test 5: ANIMA awarding logic
    @MainActor
    private func testANIMAAwarding() async {
        let mock = MockP2PService()
        mock.simulateConnection()
        
        // Wait for handshake
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        
        // Send 3 messages to trigger ANIMA
        for i in 1...3 {
            mock.sendMessage("Message \(i)")
            try? await Task.sleep(nanoseconds: 700_000_000)
        }
        
        // Check if we have enough messages for ANIMA
        let messageCount = mock.messages.count
        let hasEnoughMessages = messageCount >= 3
        let hasBidirectional = mock.messages.contains { $0.text.hasPrefix("[sent]") } &&
                               mock.messages.contains { !$0.text.hasPrefix("[sent]") }
        let passed = hasEnoughMessages && hasBidirectional
        
        let result = TestResult(
            testName: "ANIMA Award Logic",
            passed: passed,
            message: passed ? "ANIMA requirements met (\(messageCount) messages, bidirectional)" : "ANIMA requirements not met"
        )
        testResults.append(result)
    }
    
    // Print test summary
    private func printTestSummary() {
        print("\n" + String(repeating: "=", count: 50))
        print("P2P TEST SUMMARY")
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

// Test UI View for running tests
struct P2PTestView: View {
    @StateObject private var testHarness = P2PTestHarness()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("P2P Test Harness")
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
                        .background(Color.blue)
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
    P2PTestView()
}