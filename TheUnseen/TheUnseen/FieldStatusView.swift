import SwiftUI

struct FieldStatusView: View {
    @EnvironmentObject var p2pService: P2PConnectivityService
    let currentAct: Int
    let isMeaningful: Bool
    @Binding var showingAlert: Bool
    @Binding var convergenceInitiated: Bool
    
    private let acts = [
        (1, "Opening"),
        (2, "Turn"),
        (3, "Deepening")
    ]
    
    var body: some View {
        VStack(spacing: 8) {
            // Act progression dots
            HStack(spacing: 16) {
                ForEach(acts, id: \.0) { act, name in
                    VStack(spacing: 3) {
                        Circle()
                            .fill(currentAct >= act ? Color.purple : Color.gray.opacity(0.3))
                            .frame(width: 6, height: 6)
                        
                        Text(name)
                            .font(.system(size: 9))
                            .foregroundColor(currentAct == act ? .purple : .gray)
                    }
                }
                
                Spacer()
                
                // Field status text
                if isMeaningful {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.green)
                        Text("Field Stabilized")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.green)
                    }
                } else {
                    Text("Field Strengthening...")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
            }
            
            // Convergence button (only after meaningful interaction)
            if isMeaningful {
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
                        showingAlert = true
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
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .alert("The Convergence", isPresented: $showingAlert) {
            Button("Cancel", role: .cancel) { }
            Button("We're Both Ready") {
                initiateConvergence()
            }
        } message: {
            Text("Invite your partner to meet in person for a 5-minute sacred container.\n\nWhen you're both together and ready, one of you should tap 'We're Both Ready' to begin.")
        }
    }
    
    private func initiateConvergence() {
        proposeConvergence()
    }
    
    private func proposeConvergence() {
        convergenceInitiated = true
        p2pService.sendSystemMessage("CONVERGENCE_REQUEST")
        
        // Start a 30-second timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
            if self.convergenceInitiated {
                // Timeout - no response
                self.convergenceInitiated = false
            }
        }
    }
}

#Preview {
    FieldStatusView(
        currentAct: 2,
        isMeaningful: false,
        showingAlert: .constant(false),
        convergenceInitiated: .constant(false)
    )
    .environmentObject(P2PConnectivityService())
}