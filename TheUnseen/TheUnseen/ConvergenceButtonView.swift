import SwiftUI

struct ConvergenceButtonView: View {
    @EnvironmentObject var p2pService: P2PConnectivityService
    @Binding var showingAlert: Bool
    @Binding var convergenceInitiated: Bool
    
    @State private var receivedConvergenceRequest = false
    @State private var requestFromPeer: String = ""
    @State private var countdownTimer: Timer?
    @State private var timeRemaining = 30
    @State private var navigateToMeetup = false
    
    var body: some View {
        Group {
            if convergenceInitiated {
                HStack(spacing: 6) {
                    Image(systemName: "location.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.purple)
                    Text("Convergence Proposed")
                        .font(.system(size: 11, weight: .medium))
                    ProgressView()
                        .scaleEffect(0.6)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.purple.opacity(0.1))
                .cornerRadius(15)
            } else {
                Button(action: {
                    proposeConvergence()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "figure.2.circle")
                            .font(.system(size: 12))
                        Text("Propose Convergence")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(
                        LinearGradient(
                            colors: [Color.purple, Color.indigo],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(15)
                }
            }
        }
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
                Text("✨ Your partner is ready to meet in person.\n\nThis sacred moment requires both souls to agree.\n\n⏱️ \(timeRemaining) seconds to decide")
                    .font(.system(size: 15))
            } else {
                Text("The moment has passed. The digital container continues, awaiting the next opportunity.")
            }
        }
        .onReceive(p2pService.$messages) { messages in
            // Listen for Convergence system messages
            if let lastMessage = messages.last {
                if lastMessage.text.contains("CONVERGENCE_REQUEST") {
                    handleConvergenceRequest(from: p2pService.connectedPeer?.displayName ?? "Initiate")
                } else if lastMessage.text.contains("CONVERGENCE_ACCEPTED") {
                    handleConvergenceAccepted()
                } else if lastMessage.text.contains("CONVERGENCE_DECLINED") {
                    handleConvergenceDeclined()
                }
            }
        }
        .navigationDestination(isPresented: $navigateToMeetup) {
            MeetupFlowView()
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
        requestFromPeer = "Your partner"  // Use friendly name instead of ID
        timeRemaining = 30
        showingAlert = true
        
        // Start countdown timer that updates the alert
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            timeRemaining -= 1
            if timeRemaining <= 0 {
                timer.invalidate()
                showingAlert = false
                receivedConvergenceRequest = false
                // Auto-decline on timeout
                declineConvergence()
            } else if timeRemaining % 5 == 0 {
                // Force alert to refresh every 5 seconds to show countdown
                showingAlert = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showingAlert = true
                }
            }
        }
    }
    
    private func acceptConvergence() {
        countdownTimer?.invalidate()
        p2pService.sendSystemMessage("CONVERGENCE_ACCEPTED")
        // Navigate to meetup flow
        print("✅ Convergence accepted! Moving to meetup flow...")
        
        // Sensory feedback for acceptance
        HapticManager.shared.success()
        SoundManager.shared.play(.convergenceBegin, volume: 0.5)
        
        // Navigate with smooth transition
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            navigateToMeetup = true
        }
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
        
        // Add smooth transition with haptic
        HapticManager.shared.mediumImpact()
        SoundManager.shared.play(.convergenceBegin, volume: 0.5)
        
        // Navigate to meetup flow with animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            navigateToMeetup = true
        }
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