import SwiftUI

struct ConvergenceButtonView: View {
    @EnvironmentObject var p2pService: P2PConnectivityService
    @Binding var showingAlert: Bool
    @Binding var convergenceInitiated: Bool
    
    @State private var receivedConvergenceRequest = false
    @State private var requestFromPeer: String = ""
    @State private var countdownTimer: Timer?
    @State private var timeRemaining = 30
    
    var body: some View {
        VStack(spacing: 12) {
            // Success indicator
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Meaningful Interaction Achieved")
                    .font(.caption)
                    .fontWeight(.medium)
                Image(systemName: "sparkles")
                    .foregroundColor(.yellow)
            }
            
            // Convergence button or status
            if convergenceInitiated {
                HStack {
                    Image(systemName: "location.circle.fill")
                        .foregroundColor(.purple)
                    Text("Convergence Proposed")
                        .font(.caption)
                        .fontWeight(.medium)
                    ProgressView()
                        .scaleEffect(0.8)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.purple.opacity(0.1))
                .cornerRadius(20)
            } else {
                Button(action: {
                    proposeConvergence()
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "figure.2.circle")
                            .font(.system(size: 18))
                        Text("Propose the Convergence")
                            .font(.system(size: 15, weight: .medium))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [Color.purple, Color.indigo],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(25)
                    .shadow(color: Color.purple.opacity(0.3), radius: 8, x: 0, y: 4)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
        .alert("The Convergence", isPresented: $showingAlert) {
            if receivedConvergenceRequest {
                // Received request from peer
                Button("Accept", role: .none) {
                    acceptConvergence()
                }
                Button("Decline", role: .cancel) {
                    declineConvergence()
                }
            } else {
                // Our request was declined or timed out
                Button("OK", role: .cancel) {
                    convergenceInitiated = false
                }
            }
        } message: {
            if receivedConvergenceRequest {
                Text("\(requestFromPeer) is attempting The Convergence.\n\nDo you accept?\n\nTime remaining: \(timeRemaining) seconds")
            } else {
                Text("The Convergence was declined or timed out. The digital container continues.")
            }
        }
        .onReceive(p2pService.$messages) { messages in
            // Listen for Convergence system messages
            if let lastMessage = messages.last {
                if lastMessage.text.contains("[CONVERGENCE_REQUEST]") {
                    handleConvergenceRequest(from: p2pService.connectedPeer?.displayName ?? "Initiate")
                } else if lastMessage.text.contains("[CONVERGENCE_ACCEPTED]") {
                    handleConvergenceAccepted()
                } else if lastMessage.text.contains("[CONVERGENCE_DECLINED]") {
                    handleConvergenceDeclined()
                }
            }
        }
    }
    
    private func proposeConvergence() {
        convergenceInitiated = true
        p2pService.sendSystemMessage("CONVERGENCE_REQUEST")
        
        // Start a 30-second timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
            if convergenceInitiated && !receivedConvergenceRequest {
                // Timeout - show declined alert
                showingAlert = true
            }
        }
    }
    
    private func handleConvergenceRequest(from peer: String) {
        receivedConvergenceRequest = true
        requestFromPeer = peer
        timeRemaining = 30
        showingAlert = true
        
        // Start countdown timer
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            timeRemaining -= 1
            if timeRemaining <= 0 {
                timer.invalidate()
                showingAlert = false
                receivedConvergenceRequest = false
                // Auto-decline on timeout
                declineConvergence()
            }
        }
    }
    
    private func acceptConvergence() {
        countdownTimer?.invalidate()
        p2pService.sendSystemMessage("CONVERGENCE_ACCEPTED")
        // Navigate to meetup flow (to be implemented)
        print("✅ Convergence accepted! Moving to meetup flow...")
    }
    
    private func declineConvergence() {
        countdownTimer?.invalidate()
        receivedConvergenceRequest = false
        p2pService.sendSystemMessage("CONVERGENCE_DECLINED")
    }
    
    private func handleConvergenceAccepted() {
        // The other user accepted our request
        convergenceInitiated = false
        print("✅ Convergence accepted by peer! Moving to meetup flow...")
        // Navigate to meetup flow (to be implemented)
    }
    
    private func handleConvergenceDeclined() {
        // The other user declined our request
        convergenceInitiated = false
        showingAlert = true
    }
}

#Preview {
    ConvergenceButtonView(
        showingAlert: .constant(false),
        convergenceInitiated: .constant(false)
    )
    .environmentObject(P2PConnectivityService())
}