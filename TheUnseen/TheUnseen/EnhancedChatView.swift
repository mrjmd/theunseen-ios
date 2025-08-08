import SwiftUI

struct EnhancedChatView: View {
    @EnvironmentObject var p2pService: P2PConnectivityService
    @StateObject private var promptsService = PromptsService.shared
    @State private var messageText: String = ""
    @State private var displayedMessages: [ChatMessage] = []
    @State private var promptShown = false
    @State private var showingConvergenceAlert = false
    @State private var convergenceInitiated = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Meaningful interaction progress OR Convergence button
            if p2pService.isHandshakeComplete {
                if p2pService.isMeaningfulInteraction {
                    // Show Convergence button after meaningful interaction
                    ConvergenceButtonView(
                        showingAlert: $showingConvergenceAlert,
                        convergenceInitiated: $convergenceInitiated
                    )
                    .padding(.vertical, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                } else {
                    // Show progress tracker
                    MeaningfulInteractionView()
                        .padding(.vertical, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            
            // Prompt display
            if let promptText = promptsService.getCurrentPromptText() {
                VStack(spacing: 10) {
                    Text("Level 1 • The Path")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .tracking(1)
                    
                    Text(promptText)
                        .font(.system(size: 16, weight: .light))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .transition(.opacity)
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
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
        .onReceive(promptsService.$currentPrompt) { prompt in
            // Update UI when prompt changes
            if prompt != nil {
                print("📱 UI updated with new prompt")
            }
        }
        .onReceive(p2pService.$messages) { newMessages in
            // Update displayed messages from service
            if let lastMessage = newMessages.last {
                if !displayedMessages.contains(where: { $0.id == lastMessage.id }) {
                    let displayMessage = ChatMessage(text: "Initiate: \(lastMessage.text)")
                    displayedMessages.append(displayMessage)
                    
                    // Don't automatically show new prompts - Level 1 has one prompt per session
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
                // Initiator selects and shares the prompt using the new service
                self.promptsService.selectAndSharePrompt(for: 1, using: self.p2pService)
                print("📤 Initiator selected and shared prompt")
                
                // Retry sending after a delay to ensure delivery
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    if let prompt = self.promptsService.currentPrompt {
                        self.p2pService.sendSystemMessage("PROMPT_ID:\(prompt.id)")
                    }
                }
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