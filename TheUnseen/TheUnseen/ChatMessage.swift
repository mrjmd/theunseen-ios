import Foundation

// A simple struct to represent a chat message.
// Identifiable allows SwiftUI to track each message uniquely in a List.
struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
}
