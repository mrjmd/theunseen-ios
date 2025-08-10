import SwiftUI
import UserNotifications

struct ConvergenceView: View {
    @EnvironmentObject var p2pService: P2PConnectivityService
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var promptsService = PromptsService.shared
    @State private var timeRemaining: Int = Int(DeveloperSettings.shared.convergenceDuration)
    @State private var timer: Timer?
    @State private var showingArtifactCreation = false
    @State private var sharedArtifact = ""
    @State private var sessionComplete = false
    @State private var waitingForArtifact = false
    @State private var showingIntegration = false
    @State var sessionId: String = UUID().uuidString  // Passed from MeetupFlowView, updated when received
    @State private var shouldDismissConvergence = false
    @State private var integrationCooldownRemaining: Int = Int(DeveloperSettings.shared.integrationCooldown)
    @State private var cooldownTimer: Timer?
    @State private var integrationAvailable = false
    @State private var partnerFirebaseUID: String? = nil
    @State private var timerPulse = false
    
    var isInitiator: Bool {
        p2pService.myPeerID.displayName < (p2pService.connectedPeer?.displayName ?? "")
    }
    
    var formattedTime: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var formattedCooldownTime: String {
        let minutes = integrationCooldownRemaining / 60
        let seconds = integrationCooldownRemaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text(Mythology.Titles.convergence)
                        .font(DesignSystem.Typography.title())
                        .tracking(DesignSystem.Typography.trackingWider)
                    
                    Text(Mythology.Titles.meetup)
                        .font(DesignSystem.Typography.caption())
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .tracking(DesignSystem.Typography.trackingWide)
                }
                .padding()
            
            // Enhanced animated timer
            ZStack {
                // Outer glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                DesignSystem.Colors.accentPrimary.opacity(0.2),
                                .clear
                            ],
                            center: .center,
                            startRadius: 40,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .scaleEffect(timerPulse ? 1.1 : 1.0)
                    .opacity(timerPulse ? 0.3 : 0.1)
                    .animation(
                        .easeInOut(duration: 2)
                        .repeatForever(autoreverses: true),
                        value: timerPulse
                    )
                
                // Background track
                Circle()
                    .stroke(DesignSystem.Colors.textTertiary.opacity(0.2), lineWidth: 6)
                    .frame(width: 120, height: 120)
                
                // Progress ring
                Circle()
                    .trim(from: 0, to: Double(timeRemaining) / DeveloperSettings.shared.convergenceDuration)
                    .stroke(
                        DesignSystem.Colors.twilightGradient,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: timeRemaining)
                    .shadow(color: DesignSystem.Colors.accentPrimary.opacity(0.3), radius: 4)
                
                // Pulse indicator at progress end
                Circle()
                    .fill(DesignSystem.Colors.accentPrimary)
                    .frame(width: 12, height: 12)
                    .offset(y: -60)
                    .rotationEffect(.degrees(360 * (1 - Double(timeRemaining) / DeveloperSettings.shared.convergenceDuration) - 90))
                    .animation(.linear(duration: 1), value: timeRemaining)
                    .shadow(color: DesignSystem.Colors.accentPrimary, radius: 4)
                
                // Timer text
                VStack(spacing: 4) {
                    Text(formattedTime)
                        .font(DesignSystem.Typography.technical(28))
                        .foregroundColor(timeRemaining <= 30 ? DesignSystem.Colors.warning : DesignSystem.Colors.textPrimary)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.3), value: timeRemaining)
                    
                    Text("remaining")
                        .font(DesignSystem.Typography.caption(DesignSystem.Typography.captionSmall))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }
            .padding(.vertical, 20)
            .onAppear {
                timerPulse = true
            }
            
            // Convergence Prompt with mythology voice
            if let prompt = promptsService.currentPrompt {
                VStack(spacing: 16) {
                    Text("Your Sacred Task")
                        .font(DesignSystem.Typography.caption())
                        .foregroundColor(DesignSystem.Colors.accentPrimary)
                        .tracking(DesignSystem.Typography.trackingWide)
                    
                    // Voice prefix
                    Text(prompt.voicePrefix)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.purple)
                        .italic()
                    
                    // Convergence prompt text
                    Text(prompt.convergencePrompt)
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
                        
                        Text(Mythology.Status.convergenceActive)
                            .font(.title3)
                            .fontWeight(.light)
                        
                        Text("Your Shared Artifact")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text("\"\(sharedArtifact)\"")
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
                        
                        if integrationAvailable {
                            Text("✨ " + Mythology.Status.integrationReady)
                                .font(.caption2)
                                .foregroundColor(.green)
                                .transition(.opacity.combined(with: .scale))
                            
                            Button(action: {
                                showingIntegration = true
                            }) {
                                HStack {
                                    Image(systemName: "flame")
                                    Text("Begin " + Mythology.Titles.integration)
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
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        } else {
                            // Cooldown timer
                            VStack(spacing: 8) {
                                HStack(spacing: 4) {
                                    Image(systemName: "timer")
                                        .font(.caption)
                                    Text("Integration unlocks in \(formattedCooldownTime)")
                                        .font(.caption)
                                }
                                .foregroundColor(.gray)
                                
                                Text("Bid your partner farewell!")
                                    .font(.caption2)
                                    .foregroundColor(.gray.opacity(0.8))
                                    .italic()
                            }
                        }
                        
                        // Always show Return to Path button
                        Button(action: {
                            disconnectAndReturn()
                        }) {
                            Text("Return to " + Mythology.Titles.thePath)
                                .foregroundColor(.purple)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.purple, lineWidth: 1)
                                )
                        }
                        .padding(.top, 10)
                        .padding(.bottom, 20)  // Extra padding for small screens
                    }
                    .padding()
                } else if isInitiator && !waitingForArtifact {
                    Button(action: {
                        showingArtifactCreation = true
                    }) {
                        HStack {
                            Image(systemName: "seal")
                            Text(Mythology.Placeholders.artifact)
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
                        Text(Mythology.Status.waitingForResponse)
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
        }
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.light) // Keep Level 1 in light mode
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(Mythology.Actions.exitPath) {
                    // Disconnect and return to main view
                    disconnectAndReturn()
                }
            }
        }
        .onAppear {
            startTimer()
            promptsService.transitionToConvergence()
            exchangeFirebaseUIDs()
        }
        .onDisappear {
            timer?.invalidate()
            promptsService.resetToDigital()
        }
        .sheet(isPresented: $showingArtifactCreation) {
            ArtifactCreationView(sharedArtifact: $sharedArtifact, onComplete: {
                // Send artifact to peer with session ID
                p2pService.sendSystemMessage("ARTIFACT_CREATED:\(sharedArtifact)|SESSION:\(sessionId)")
                waitingForArtifact = true
                sessionComplete = true
                
                // Ensure session exists in Firestore with artifact
                createSessionInFirestore()
                
                startIntegrationCooldown()
            })
        }
        .fullScreenCover(isPresented: $showingIntegration, onDismiss: {
            // When Integration is dismissed, also dismiss Convergence
            if shouldDismissConvergence {
                dismiss()
            }
        }) {
            IntegrationView(sessionId: sessionId)
                .environmentObject(p2pService)
                .onDisappear {
                    // Mark that we should dismiss the entire Convergence flow
                    shouldDismissConvergence = true
                }
        }
        .onReceive(p2pService.$messages) { messages in
            // Listen for messages from peer
            if let lastMessage = messages.last {
                // Handle Firebase UID exchange
                if lastMessage.text.contains("FIREBASE_UID:") {
                    let uid = lastMessage.text
                        .replacingOccurrences(of: "[SYSTEM]FIREBASE_UID:", with: "")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    DispatchQueue.main.async {
                        self.partnerFirebaseUID = uid
                        print("📱 Received partner's Firebase UID: \(uid)")
                        // Now create session with both UIDs
                        self.createSessionInFirestore()
                    }
                }
                // Handle artifact creation
                if lastMessage.text.contains("ARTIFACT_CREATED:") {
                    let fullMessage = lastMessage.text
                        .replacingOccurrences(of: "[SYSTEM]ARTIFACT_CREATED:", with: "")
                    
                    // Extract artifact and session ID
                    if let artifactRange = fullMessage.range(of: "|SESSION:") {
                        let artifact = String(fullMessage[..<artifactRange.lowerBound])
                        let sessionPart = String(fullMessage[artifactRange.upperBound...])
                        
                        DispatchQueue.main.async {
                            self.sharedArtifact = artifact
                            if !sessionPart.isEmpty {
                                self.sessionId = sessionPart
                            }
                            self.sessionComplete = true
                            self.startIntegrationCooldown()
                        }
                    } else {
                        // Fallback for old format
                        DispatchQueue.main.async {
                            self.sharedArtifact = fullMessage
                            self.sessionComplete = true
                            self.startIntegrationCooldown()
                        }
                    }
                }
            }
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
                
                // Heartbeat haptics and warning when < 10 seconds
                if timeRemaining == 10 {
                    SoundManager.shared.startHeartbeat(volume: 0.3)
                    SoundManager.shared.playCountdownWarning()
                }
                
                // Pulse haptic for final countdown
                if timeRemaining <= 10 && timeRemaining > 0 {
                    HapticManager.shared.lightImpact()
                }
                
                // Extra strong warning at 5 seconds
                if timeRemaining == 5 {
                    HapticManager.shared.warning()
                }
            } else {
                timer?.invalidate()
                
                // Stop heartbeat and play completion
                SoundManager.shared.stopHeartbeat()
                HapticManager.shared.error()
                SoundManager.shared.play(.convergenceComplete)
            }
        }
    }
    
    private func startIntegrationCooldown() {
        print("🔥 Starting Integration cooldown: \(integrationCooldownRemaining)s")
        cooldownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if integrationCooldownRemaining > 0 {
                integrationCooldownRemaining -= 1
                if integrationCooldownRemaining % 10 == 0 {
                    print("🔥 Integration cooldown: \(integrationCooldownRemaining)s remaining")
                }
            } else {
                cooldownTimer?.invalidate()
                print("🔥 Integration is now available!")
                withAnimation(.spring()) {
                    integrationAvailable = true
                }
                
                // Save pending integration for later access
                savePendingIntegration()
                
                // Send local notification
                sendIntegrationReadyNotification()
                // Play haptic feedback
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
        }
    }
    
    private func sendIntegrationReadyNotification() {
        print("📱 Sending Integration ready notification")
        let content = UNMutableNotificationContent()
        content.title = "The Integration Awaits"
        content.body = "Your reflection space is ready. Complete The Integration to receive your ANIMA."
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "integration-ready-\(sessionId)",
            content: content,
            trigger: nil  // Deliver immediately
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to send notification: \(error)")
            } else {
                print("✅ Integration notification sent successfully")
            }
        }
    }
    
    private func savePendingIntegration() {
        // Ensure session exists with both participants before saving pending Integration
        createSessionInFirestore()
        
        // Create pending integration data with timestamp as TimeInterval
        let pendingIntegration = [
            "sessionId": sessionId,
            "artifact": sharedArtifact,
            "timestamp": Date().timeIntervalSince1970,  // Convert Date to TimeInterval for JSON
            "partnerName": p2pService.connectedPeer?.displayName as Any,
            "peerId": p2pService.connectedPeer?.displayName as Any,  // Store peer ID for cooldown management
            "partnerFirebaseUID": partnerFirebaseUID as Any  // Store Firebase UID for Integration
        ] as [String : Any]
        
        // Convert to JSON and save to UserDefaults
        if let jsonData = try? JSONSerialization.data(withJSONObject: pendingIntegration) {
            UserDefaults.standard.set(jsonData, forKey: "pendingIntegration")
            print("💾 Saved pending Integration for session: \(sessionId)")
            print("💾 Artifact: \(sharedArtifact)")
            
            // Schedule reminder notification for 20 hours later (4 hours before expiration)
            scheduleIntegrationReminder()
        } else {
            print("❌ Failed to save pending Integration - JSON serialization failed")
        }
    }
    
    private func scheduleIntegrationReminder() {
        let content = UNMutableNotificationContent()
        content.title = "Integration Expiring Soon"
        content.body = "Your Integration expires in 4 hours. Both players must complete it to receive ANIMA."
        content.sound = .default
        
        // Schedule for 20 hours from now (4 hours before 24h expiration)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 72000, repeats: false) // 20 hours
        
        let request = UNNotificationRequest(
            identifier: "integration-reminder-\(sessionId)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule reminder: \(error)")
            } else {
                print("⏰ Scheduled Integration reminder for 20 hours from now")
            }
        }
    }
    
    private func exchangeFirebaseUIDs() {
        // Send our Firebase UID to partner
        guard let userId = authService.user?.uid else { return }
        p2pService.sendSystemMessage("FIREBASE_UID:\(userId)")
        print("📤 Sent Firebase UID to partner: \(userId)")
    }
    
    private func createSessionInFirestore() {
        // Create session document with both participant IDs for security
        guard let userId = authService.user?.uid else { return }
        
        var participantIds = [userId]
        if let partnerUID = partnerFirebaseUID {
            participantIds.append(partnerUID)
        } else {
            print("⚠️ Warning: Creating session without partner UID - will need to update later")
        }
        
        print("🔐 Creating secure session with participants: \(participantIds)")
        print("📝 Session ID: \(sessionId)")
        let firestoreService = FirestoreService()
        firestoreService.createSession(sessionId: sessionId, participantIds: participantIds, artifact: sharedArtifact.isEmpty ? nil : sharedArtifact)
    }
    
    private func disconnectAndReturn() {
        // Store the peer ID to block re-matching for 1 hour
        if let peerId = p2pService.connectedPeer?.displayName {
            UserDefaults.standard.set(Date(), forKey: "lastSession_\(peerId)")
        }
        
        // Disconnect from peer
        p2pService.session.disconnect()
        
        // Dismiss the entire flow
        dismiss()
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
        ConvergenceView(sessionId: "preview-session-123")
            .environmentObject(P2PConnectivityService())
    }
}