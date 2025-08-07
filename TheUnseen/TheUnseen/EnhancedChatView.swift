import SwiftUI

struct EnhancedChatView: View {
    @EnvironmentObject var p2pService: P2PConnectivityService
    @State private var messageText: String = ""
    @State private var displayedMessages: [ChatMessage] = []
    @State private var currentPrompt: String?
    @State private var promptShown = false
    
    // Level 1 Prompts - Simple vulnerability
    let level1Prompts = [
        "Share something you're grateful for today.",
        "What's one thing you wish people knew about you?",
        "Describe a moment when you felt truly alive.",
        "What's a fear you're ready to release?",
        "Share a dream you haven't told anyone.",
        "What mask do you wear most often?",
        "When do you feel most like yourself?",
        "What's a truth you've been avoiding?",
        "Share a moment of unexpected kindness.",
        "What would you do if you knew you couldn't fail?"
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Prompt display
            if let prompt = currentPrompt {
                VStack(spacing: 10) {
                    Text("Level 1 • The Path")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .tracking(1)
                    
                    Text(prompt)
                        .font(.system(size: 16, weight: .light))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .transition(.opacity)
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .animation(.easeIn, value: currentPrompt)
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
            
            // Input area
            HStack(spacing: 12) {
                TextField("Share your truth...", text: $messageText)
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
        .onAppear {
            showFirstPrompt()
        }
        .onReceive(p2pService.$currentPrompt) { prompt in
            // Update UI when prompt is received
            if let prompt = prompt {
                withAnimation {
                    self.currentPrompt = prompt
                }
                print("📱 UI updated with prompt: \(prompt)")
            }
        }
        .onReceive(p2pService.$messages) { newMessages in
            // Update displayed messages from service
            if let lastMessage = newMessages.last {
                if !displayedMessages.contains(where: { $0.id == lastMessage.id }) {
                    let displayMessage = ChatMessage(text: "Initiate: \(lastMessage.text)")
                    displayedMessages.append(displayMessage)
                    
                    // Show new prompt after a few exchanges
                    if displayedMessages.count % 5 == 0 {
                        showNextPrompt()
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
    }
    
    private func showFirstPrompt() {
        guard !promptShown else { return }
        promptShown = true
        
        // Check if we're the initiator (select and send prompt)
        let isInitiator = p2pService.myPeerID.displayName < (p2pService.connectedPeer?.displayName ?? "")
        
        // Wait for connection to stabilize
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if isInitiator {
                // Initiator selects and shares the prompt
                let selectedPrompt = self.level1Prompts.randomElement() ?? self.level1Prompts[0]
                
                // Set it locally
                withAnimation {
                    self.currentPrompt = selectedPrompt
                    self.p2pService.currentPrompt = selectedPrompt
                }
                
                // Send prompt to peer
                self.p2pService.sendSystemMessage("PROMPT:\(selectedPrompt)")
                print("📤 Initiator selected prompt: \(selectedPrompt)")
                
                // Retry sending after a delay to ensure delivery
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.p2pService.sendSystemMessage("PROMPT:\(selectedPrompt)")
                }
            }
        }
    }
    
    private func showNextPrompt() {
        // Check if we're the initiator
        let isInitiator = p2pService.myPeerID.displayName < (p2pService.connectedPeer?.displayName ?? "")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if isInitiator {
                // Only initiator selects new prompts
                let selectedPrompt = self.level1Prompts.randomElement() ?? self.level1Prompts[0]
                withAnimation {
                    self.currentPrompt = selectedPrompt
                }
                // Send prompt to peer
                self.p2pService.sendSystemMessage("PROMPT:\(selectedPrompt)")
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