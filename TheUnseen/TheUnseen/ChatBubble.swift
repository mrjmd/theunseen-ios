import SwiftUI

// MARK: - Chat Bubble View
// Custom chat bubble design for The Unseen conversations

struct ChatBubble: View {
    let message: ChatMessage
    let direction: MessageDirection
    
    enum MessageDirection {
        case sent
        case received
    }
    
    var body: some View {
        HStack {
            if direction == .sent {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: direction == .sent ? .trailing : .leading, spacing: 4) {
                // Message bubble
                Text(extractMessageText())
                    .font(DesignSystem.Typography.body())
                    .foregroundColor(direction == .sent ? DesignSystem.Colors.textPrimary : DesignSystem.Colors.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        BubbleShape(direction: direction)
                            .fill(direction == .sent ? 
                                  DesignSystem.Colors.sentMessageBubble : 
                                  DesignSystem.Colors.receivedMessageBubble)
                    )
                    .overlay(
                        BubbleShape(direction: direction)
                            .stroke(
                                direction == .sent ?
                                DesignSystem.Colors.accentPrimary.opacity(0.1) :
                                DesignSystem.Colors.textTertiary.opacity(0.1),
                                lineWidth: 1
                            )
                    )
                
                // Timestamp (optional)
                if shouldShowTimestamp() {
                    Text(formatTimestamp())
                        .font(DesignSystem.Typography.caption(10))
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                        .padding(.horizontal, 4)
                }
            }
            
            if direction == .received {
                Spacer(minLength: 60)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 2)
        .transition(.asymmetric(
            insertion: .move(edge: direction == .sent ? .trailing : .leading)
                .combined(with: .opacity),
            removal: .opacity
        ))
    }
    
    // Extract clean message text without prefixes
    private func extractMessageText() -> String {
        let text = message.text
        
        // Remove "You: " or "Initiate: " prefixes
        if text.hasPrefix("You: ") {
            return String(text.dropFirst(5))
        } else if text.hasPrefix("Initiate: ") {
            return String(text.dropFirst(10))
        }
        
        return text
    }
    
    // Determine if we should show timestamp
    private func shouldShowTimestamp() -> Bool {
        // Could add logic to show timestamps for first message,
        // or messages with >5 min gap, etc.
        return false // For now, keeping it clean
    }
    
    // Format timestamp for display
    private func formatTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: Date())
    }
}

// MARK: - Bubble Shape
struct BubbleShape: Shape {
    let direction: ChatBubble.MessageDirection
    
    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        let cornerRadius: CGFloat = 18
        let tailSize: CGFloat = 8
        
        return Path { path in
            if direction == .sent {
                // Sent message (tail on right)
                path.move(to: CGPoint(x: cornerRadius, y: 0))
                path.addLine(to: CGPoint(x: width - cornerRadius - tailSize, y: 0))
                path.addArc(
                    center: CGPoint(x: width - cornerRadius - tailSize, y: cornerRadius),
                    radius: cornerRadius,
                    startAngle: .degrees(-90),
                    endAngle: .degrees(0),
                    clockwise: false
                )
                
                // Tail
                path.addLine(to: CGPoint(x: width - tailSize, y: height - cornerRadius))
                path.addQuadCurve(
                    to: CGPoint(x: width, y: height),
                    control: CGPoint(x: width - tailSize, y: height)
                )
                path.addQuadCurve(
                    to: CGPoint(x: width - tailSize - cornerRadius, y: height),
                    control: CGPoint(x: width - tailSize, y: height)
                )
                
                // Bottom left corner
                path.addLine(to: CGPoint(x: cornerRadius, y: height))
                path.addArc(
                    center: CGPoint(x: cornerRadius, y: height - cornerRadius),
                    radius: cornerRadius,
                    startAngle: .degrees(90),
                    endAngle: .degrees(180),
                    clockwise: false
                )
                
                // Left side
                path.addLine(to: CGPoint(x: 0, y: cornerRadius))
                path.addArc(
                    center: CGPoint(x: cornerRadius, y: cornerRadius),
                    radius: cornerRadius,
                    startAngle: .degrees(180),
                    endAngle: .degrees(270),
                    clockwise: false
                )
            } else {
                // Received message (tail on left)
                path.move(to: CGPoint(x: cornerRadius + tailSize, y: 0))
                path.addLine(to: CGPoint(x: width - cornerRadius, y: 0))
                path.addArc(
                    center: CGPoint(x: width - cornerRadius, y: cornerRadius),
                    radius: cornerRadius,
                    startAngle: .degrees(-90),
                    endAngle: .degrees(0),
                    clockwise: false
                )
                
                // Right side
                path.addLine(to: CGPoint(x: width, y: height - cornerRadius))
                path.addArc(
                    center: CGPoint(x: width - cornerRadius, y: height - cornerRadius),
                    radius: cornerRadius,
                    startAngle: .degrees(0),
                    endAngle: .degrees(90),
                    clockwise: false
                )
                
                // Bottom with tail
                path.addLine(to: CGPoint(x: tailSize + cornerRadius, y: height))
                path.addQuadCurve(
                    to: CGPoint(x: 0, y: height),
                    control: CGPoint(x: tailSize, y: height)
                )
                path.addQuadCurve(
                    to: CGPoint(x: tailSize, y: height - cornerRadius),
                    control: CGPoint(x: tailSize, y: height)
                )
                
                // Left side
                path.addLine(to: CGPoint(x: tailSize, y: cornerRadius))
                path.addArc(
                    center: CGPoint(x: tailSize + cornerRadius, y: cornerRadius),
                    radius: cornerRadius,
                    startAngle: .degrees(180),
                    endAngle: .degrees(270),
                    clockwise: false
                )
            }
        }
    }
}

// MARK: - Typing Indicator
struct TypingIndicator: View {
    @State private var animationPhase = 0
    
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(DesignSystem.Colors.textSecondary)
                        .frame(width: 8, height: 8)
                        .scaleEffect(animationPhase == index ? 1.2 : 0.8)
                        .opacity(animationPhase == index ? 1.0 : 0.5)
                        .animation(
                            .easeInOut(duration: 0.5)
                            .repeatForever()
                            .delay(Double(index) * 0.15),
                            value: animationPhase
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                BubbleShape(direction: .received)
                    .fill(DesignSystem.Colors.receivedMessageBubble)
            )
            .onAppear {
                withAnimation(.easeInOut(duration: 0.5).repeatForever()) {
                    animationPhase = 2
                }
            }
            
            Spacer(minLength: 60)
        }
        .padding(.horizontal, 12)
    }
}

// MARK: - Preview
struct ChatBubble_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ChatBubble(
                message: ChatMessage(text: "You: Hello, fellow Initiate"),
                direction: .sent
            )
            
            ChatBubble(
                message: ChatMessage(text: "Initiate: Greetings, I sense your presence"),
                direction: .received
            )
            
            TypingIndicator()
        }
        .padding()
        .background(DesignSystem.Colors.background)
    }
}