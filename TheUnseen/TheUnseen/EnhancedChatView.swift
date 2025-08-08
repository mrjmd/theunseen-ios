import SwiftUI

struct EnhancedChatView: View {
    @EnvironmentObject var p2pService: P2PConnectivityService
    @StateObject private var promptsService = PromptsService.shared
    @State private var messageText: String = ""
    @State private var displayedMessages: [ChatMessage] = []
    @State private var promptShown = false
    @State private var showingConvergenceAlert = false
    @State private var convergenceInitiated = false
    @State private var hasRespondedToCurrentPrompt = false
    @State private var peerHasRespondedToCurrentPrompt = false
    @State private var showDeveloperMenu = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Combined field status and act progression
            if p2pService.isHandshakeComplete {
                VStack(spacing: 6) {
                    // Compact status bar with acts and field
                    CompactStatusBar(
                        currentAct: promptsService.currentAct,
                        isMeaningful: p2pService.isMeaningfulInteraction
                    )
                    
                    // Convergence button on its own line when meaningful interaction achieved
                    if p2pService.isMeaningfulInteraction {
                        ConvergenceButtonView(
                            showingAlert: $showingConvergenceAlert,
                            convergenceInitiated: $convergenceInitiated
                        )
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // Prompt display - condensed
            if let prompt = promptsService.currentPrompt {
                VStack(spacing: 6) {
                    Text(prompt.voicePrefix)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.purple)
                        .italic()
                    
                    Text(promptsService.currentPhase == .digital ? prompt.digitalPrompt : prompt.convergencePrompt)
                        .font(.system(size: 14, weight: .light))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(UIColor.secondarySystemBackground).opacity(0.8))
                )
                .padding(.horizontal, 12)
                .animation(.easeIn, value: promptsService.currentPrompt?.id)
            }
            
            // Messages list
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(displayedMessages) { msg in
                            MessageBubble(message: msg)
                                .id(msg.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: displayedMessages.count) { _, _ in
                    // Scroll to bottom when new message arrives
                    if let lastMessage = displayedMessages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Input area with sacred language
            HStack(spacing: 12) {
                TextField("Speak what is true...", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        sendMessage()
                    }
                
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(messageText.isEmpty ? .gray : .black)
                }
                .disabled(messageText.isEmpty || !p2pService.isHandshakeComplete)
            }
            .padding()
            .background(Color(UIColor.systemBackground))
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("The Container")
        .preferredColorScheme(.light) // Force light mode for Level 1
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if DeveloperSettings.shared.isDeveloperModeEnabled {
                    Button(action: {
                        showDeveloperMenu = true
                    }) {
                        Image(systemName: "wrench.and.screwdriver.fill")
                            .foregroundColor(.purple.opacity(0.6))
                            .font(.caption)
                    }
                }
            }
        }
        .sheet(isPresented: $showDeveloperMenu) {
            DeveloperMenuView()
        }
        .onAppear {
            showFirstPrompt()
        }
        .onReceive(p2pService.$isHandshakeComplete) { isComplete in
            if isComplete && !promptShown {
                // Try again if handshake completes after view appears
                showFirstPrompt()
            }
        }
        .onReceive(promptsService.$currentPrompt) { prompt in
            // Update UI when prompt changes
            if let prompt = prompt {
                // New prompt displayed
            }
        }
        .onReceive(promptsService.$currentAct) { act in
            // Act change: \(act)
            // Reset response flags when act changes
            hasRespondedToCurrentPrompt = false
            peerHasRespondedToCurrentPrompt = false
        }
        .onReceive(p2pService.$messages) { newMessages in
            // Update displayed messages from service
            if let lastMessage = newMessages.last {
                // Skip system messages (they start with [SYSTEM])
                if !lastMessage.text.hasPrefix("[SYSTEM]") && !displayedMessages.contains(where: { $0.id == lastMessage.id }) {
                    let displayMessage = ChatMessage(text: "Initiate: \(lastMessage.text)")
                    displayedMessages.append(displayMessage)
                    
                    // Mark that peer has responded to this prompt (only once per act)
                    if !peerHasRespondedToCurrentPrompt {
                        peerHasRespondedToCurrentPrompt = true
                        
                        // Check if we should progress
                        checkForActProgression()
                    }
                }
            }
        }
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        
        // Add to local display
        let sentMessage = ChatMessage(text: "You: \(messageText)")
        displayedMessages.append(sentMessage)
        
        // Send via P2P
        p2pService.sendMessage(messageText)
        messageText = ""
        
        // Mark that we've responded to this prompt (only once per act)
        if !hasRespondedToCurrentPrompt {
            hasRespondedToCurrentPrompt = true
            
            // Check if we should progress to next act
            checkForActProgression()
        }
        
        // After first message, verify journey sync
        if p2pService.sentMessageCount == 1 {
            verifyJourneySync()
        }
    }
    
    private func checkForActProgression() {
        // Only the initiator controls act progression
        let isInitiator = p2pService.myPeerID.displayName < (p2pService.connectedPeer?.displayName ?? "")
        guard isInitiator else { return }
        
        print("🎭 Act \(promptsService.currentAct) - Me responded: \(hasRespondedToCurrentPrompt), Peer responded: \(peerHasRespondedToCurrentPrompt)")
        
        // Progress when both players have responded to the current prompt
        if hasRespondedToCurrentPrompt && peerHasRespondedToCurrentPrompt && promptsService.currentAct < 3 {
            print("🎭 Both players responded to Act \(promptsService.currentAct), progressing to next act")
            
            // Progress to next act
            promptsService.progressToNextAct(using: p2pService)
            
            // Reset response flags for the new act
            hasRespondedToCurrentPrompt = false
            peerHasRespondedToCurrentPrompt = false
        }
    }
    
    private func showFirstPrompt() {
        guard !promptShown else { return }
        promptShown = true
        
        // Check if we're the initiator (select and send prompt)
        let isInitiator = p2pService.myPeerID.displayName < (p2pService.connectedPeer?.displayName ?? "")
        
        // Wait for connection to stabilize and handshake to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            // Make sure we're still connected
            guard self.p2pService.isHandshakeComplete else {
                print("❌ Cannot send journey - handshake not complete")
                self.promptShown = false  // Reset to try again
                return
            }
            
            if isInitiator {
                // Initiator starts a new 3-act journey
                self.promptsService.startNewJourney(for: 1, using: self.p2pService)
                print("🎭 Initiator started new journey")
                
                // Send multiple times to ensure delivery
                for delay in [0.5, 2.0, 4.0] {
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        if let journey = self.promptsService.currentJourney,
                           self.p2pService.isHandshakeComplete {
                            self.p2pService.sendSystemMessage("JOURNEY_ID:\(journey.id)")
                            // Sending journey ID
                        }
                    }
                }
            } else {
                // Responder waits for journey
                print("👀 Responder waiting for journey ID...")
                
                // Request journey if not received after 5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    if self.promptsService.currentJourney == nil && self.p2pService.isHandshakeComplete {
                        print("⚠️ No journey received, requesting from initiator...")
                        self.p2pService.sendSystemMessage("REQUEST_JOURNEY")
                    }
                }
            }
        }
    }
    
    private func verifyJourneySync() {
        let isInitiator = p2pService.myPeerID.displayName < (p2pService.connectedPeer?.displayName ?? "")
        
        if isInitiator {
            // Initiator resends journey ID after first message to ensure sync
            if let journey = promptsService.currentJourney {
                print("🔄 Verifying journey sync after first message")
                p2pService.sendSystemMessage("JOURNEY_ID:\(journey.id)")
            }
        } else {
            // Responder checks if they have a journey
            if promptsService.currentJourney == nil {
                print("⚠️ Still no journey after first message, requesting...")
                p2pService.sendSystemMessage("REQUEST_JOURNEY")
            }
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    
    var isOwnMessage: Bool {
        message.text.hasPrefix("You:")
    }
    
    var body: some View {
        HStack {
            if isOwnMessage { Spacer() }
            
            VStack(alignment: isOwnMessage ? .trailing : .leading, spacing: 4) {
                Text(message.text.replacingOccurrences(of: "You: ", with: "")
                                 .replacingOccurrences(of: "Initiate: ", with: ""))
                    .font(.system(size: 15))
                    .foregroundColor(isOwnMessage ? .white : .primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(isOwnMessage ? Color.black : Color(UIColor.secondarySystemFill))
                    )
                
                Text(isOwnMessage ? "You" : "Initiate")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: 280, alignment: isOwnMessage ? .trailing : .leading)
            
            if !isOwnMessage { Spacer() }
        }
    }
}

#Preview {
    NavigationStack {
        EnhancedChatView()
            .environmentObject(P2PConnectivityService())
    }
}