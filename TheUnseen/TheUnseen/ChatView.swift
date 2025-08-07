import SwiftUI

struct ChatView: View {
    @EnvironmentObject var p2pService: P2PConnectivityService
    
    @State private var messageText: String = ""
    // This local array is for displaying our own messages instantly.
    @State private var displayedMessages: [ChatMessage] = []

    var body: some View {
        VStack {
            // Display a status message until the handshake is complete.
            if !p2pService.isHandshakeComplete {
                Text("Searching for another Initiate...")
                    .padding()
                    .foregroundColor(.gray)
            }
            
            List(displayedMessages) { msg in
                Text(msg.text)
            }
            
            HStack {
                TextField("Enter message...", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.leading)
                
                Button(action: {
                    let sentMessage = "Me: \(messageText)"
                    displayedMessages.append(ChatMessage(text: sentMessage))
                    p2pService.sendMessage(messageText)
                    messageText = ""
                }) {
                    Text("Send")
                }
                .padding(.trailing)
                .disabled(!p2pService.isHandshakeComplete || messageText.isEmpty)
            }
            .padding(.bottom)
        }
        .navigationTitle("The Path")
        // This is a more robust way to receive and display messages.
        .onReceive(p2pService.$messages) { newMessages in
            // When the service gets a new message, add it to our display list.
            if let lastMessage = newMessages.last {
                // Avoid adding duplicates.
                if !self.displayedMessages.contains(where: { $0.id == lastMessage.id }) {
                     self.displayedMessages.append(ChatMessage(text: "Peer: \(lastMessage.text)"))
                }
            }
        }
    }
}

#Preview {
    ChatView()
        .environmentObject(P2PConnectivityService())
}
