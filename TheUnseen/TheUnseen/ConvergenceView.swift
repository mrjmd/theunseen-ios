import SwiftUI

struct ConvergenceView: View {
    @EnvironmentObject var p2pService: P2PConnectivityService
    @StateObject private var promptsService = PromptsService.shared
    // TODO: DEVELOPMENT MODE - Change back to 300 seconds (5 minutes) for production!
    @State private var timeRemaining = 60 // 60 seconds for dev testing (should be 300)
    @State private var timer: Timer?
    @State private var showingArtifactCreation = false
    @State private var sharedArtifact = ""
    @State private var sessionComplete = false
    @State private var waitingForArtifact = false
    
    var isInitiator: Bool {
        p2pService.myPeerID.displayName < (p2pService.connectedPeer?.displayName ?? "")
    }
    
    var formattedTime: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text("The Convergence")
                    .font(.title2)
                    .fontWeight(.light)
                    .tracking(2)
                
                Text("In-Person Container")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .tracking(1)
            }
            .padding()
            
            // Timer
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: Double(timeRemaining) / 60.0)  // TODO: Change back to 300.0 for production!
                    .stroke(
                        LinearGradient(
                            colors: [.purple, .indigo],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: timeRemaining)
                
                VStack(spacing: 4) {
                    Text(formattedTime)
                        .font(.system(size: 28, weight: .light, design: .monospaced))
                    Text("remaining")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            .padding(.vertical, 20)
            
            // Convergence Prompt
            if let convergencePrompt = promptsService.currentPrompt?.convergencePrompt {
                VStack(spacing: 16) {
                    Text("Your Sacred Task")
                        .font(.caption)
                        .foregroundColor(.purple)
                        .tracking(1)
                    
                    Text(convergencePrompt)
                        .font(.system(size: 18, weight: .light))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(UIColor.secondarySystemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    LinearGradient(
                                        colors: [.purple.opacity(0.3), .indigo.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                )
                .padding(.horizontal)
            }
            
            Spacer()
            
            // Instructions
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "eye")
                        .foregroundColor(.purple)
                    Text("Maintain presence")
                        .font(.caption)
                }
                
                HStack(spacing: 8) {
                    Image(systemName: "heart")
                        .foregroundColor(.purple)
                    Text("Stay curious, not judgmental")
                        .font(.caption)
                }
                
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.purple)
                    Text("Notice what emerges")
                        .font(.caption)
                }
            }
            .padding()
            .background(Color(UIColor.tertiarySystemBackground))
            .cornerRadius(12)
            .padding()
            
            // Complete button (appears when timer ends)
            if timeRemaining <= 0 {
                if sessionComplete && !sharedArtifact.isEmpty {
                    // Session complete with artifact
                    VStack(spacing: 20) {
                        Image(systemName: "seal.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.purple)
                        
                        Text("Session Complete")
                            .font(.title3)
                            .fontWeight(.light)
                        
                        Text("Your Shared Artifact")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text(""\(sharedArtifact)"")
                            .font(.body)
                            .italic()
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(UIColor.secondarySystemBackground))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [.purple.opacity(0.5), .indigo.opacity(0.5)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1
                                            )
                                    )
                            )
                            .padding(.horizontal)
                        
                        Text("✨ ANIMA will be awarded after cooldown")
                            .font(.caption2)
                            .foregroundColor(.purple)
                    }
                    .padding()
                } else if isInitiator && !waitingForArtifact {
                    Button(action: {
                        showingArtifactCreation = true
                    }) {
                        HStack {
                            Image(systemName: "seal")
                            Text("Create Shared Artifact")
                            Image(systemName: "arrow.right")
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [.purple, .indigo],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(25)
                    }
                    .padding()
                } else if !isInitiator && !sessionComplete {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Waiting for shared artifact...")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("Your partner will create a quote or insight from your interaction")
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                } else if waitingForArtifact && isInitiator {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.green)
                        Text("Artifact created!")
                            .font(.headline)
                            .fontWeight(.light)
                        Text("Waiting for partner to receive...")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.light) // Keep Level 1 in light mode
        .onAppear {
            startTimer()
            promptsService.transitionToConvergence()
        }
        .onDisappear {
            timer?.invalidate()
            promptsService.resetToDigital()
        }
        .sheet(isPresented: $showingArtifactCreation) {
            ArtifactCreationView(sharedArtifact: $sharedArtifact, onComplete: {
                // Send artifact to peer
                p2pService.sendSystemMessage("ARTIFACT_CREATED:\(sharedArtifact)")
                waitingForArtifact = true
                sessionComplete = true
            })
        }
        .onReceive(p2pService.$messages) { messages in
            // Listen for artifact creation from peer
            if let lastMessage = messages.last {
                if lastMessage.text.contains("ARTIFACT_CREATED:") {
                    let artifact = lastMessage.text
                        .replacingOccurrences(of: "[SYSTEM]ARTIFACT_CREATED:", with: "")
                    DispatchQueue.main.async {
                        self.sharedArtifact = artifact
                        self.sessionComplete = true
                    }
                }
            }
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                timer?.invalidate()
                // Play a gentle completion sound or haptic
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
        }
    }
}

// Artifact Creation View
struct ArtifactCreationView: View {
    @Binding var sharedArtifact: String
    let onComplete: () -> Void
    @Environment(\.dismiss) var dismiss
    @State private var artifactText = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Create Your Shared Artifact")
                    .font(.title3)
                    .fontWeight(.light)
                    .padding(.top)
                
                Text("Together, choose a single quote or insight from your interaction to preserve. Discuss with your partner what captured the essence of your meeting.")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Text("💬 Talk together about what to write")
                    .font(.caption2)
                    .foregroundColor(.purple)
                    .padding(.top)
                
                TextField("Enter your shared wisdom...", text: $artifactText, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(3...6)
                    .padding()
                
                Spacer()
                
                Button(action: {
                    sharedArtifact = artifactText
                    onComplete()
                    dismiss()
                }) {
                    Text("Seal the Artifact")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.purple, .indigo],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                }
                .disabled(artifactText.isEmpty)
                .padding()
            }
            .navigationTitle("Shared Artifact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ConvergenceView()
            .environmentObject(P2PConnectivityService())
    }
}