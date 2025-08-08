import SwiftUI

struct MeaningfulInteractionView: View {
    @EnvironmentObject var p2pService: P2PConnectivityService
    
    // TODO: DEVELOPMENT MODE - Change back to 150 seconds (2.5 minutes) for production!
    private let minimumDuration: TimeInterval = 30 // 30 seconds for dev testing (should be 150)
    private let minimumMessages = 3
    
    var timeProgress: Double {
        min(p2pService.connectionDuration / minimumDuration, 1.0)
    }
    
    var sentMessageProgress: Double {
        min(Double(p2pService.sentMessageCount) / Double(minimumMessages), 1.0)
    }
    
    var receivedMessageProgress: Double {
        min(Double(p2pService.receivedMessageCount) / Double(minimumMessages), 1.0)
    }
    
    var formattedTime: String {
        let remaining = max(0, minimumDuration - p2pService.connectionDuration)
        let minutes = Int(remaining) / 60
        let seconds = Int(remaining) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            if p2pService.isMeaningfulInteraction {
                // Success state
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Meaningful Interaction Achieved")
                        .font(.caption)
                        .fontWeight(.medium)
                    Image(systemName: "sparkles")
                        .foregroundColor(.yellow)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.green.opacity(0.1))
                .cornerRadius(20)
            } else {
                // Progress indicators
                VStack(spacing: 12) {
                    Text("Approaching Meaningful Interaction")
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .tracking(0.5)
                    
                    HStack(spacing: 20) {
                        // Time progress
                        VStack(spacing: 4) {
                            ZStack {
                                Circle()
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 3)
                                    .frame(width: 40, height: 40)
                                
                                Circle()
                                    .trim(from: 0, to: timeProgress)
                                    .stroke(
                                        timeProgress >= 1 ? Color.green : Color.blue,
                                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                                    )
                                    .frame(width: 40, height: 40)
                                    .rotationEffect(.degrees(-90))
                                
                                Image(systemName: "clock")
                                    .font(.system(size: 16))
                                    .foregroundColor(timeProgress >= 1 ? .green : .primary)
                            }
                            
                            Text(formattedTime)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.gray)
                        }
                        
                        // Sent messages progress
                        VStack(spacing: 4) {
                            ZStack {
                                Circle()
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 3)
                                    .frame(width: 40, height: 40)
                                
                                Circle()
                                    .trim(from: 0, to: sentMessageProgress)
                                    .stroke(
                                        sentMessageProgress >= 1 ? Color.green : Color.purple,
                                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                                    )
                                    .frame(width: 40, height: 40)
                                    .rotationEffect(.degrees(-90))
                                
                                Text("\(p2pService.sentMessageCount)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(sentMessageProgress >= 1 ? .green : .primary)
                            }
                            
                            Text("Sent")
                                .font(.system(size: 10))
                                .foregroundColor(.gray)
                        }
                        
                        // Received messages progress
                        VStack(spacing: 4) {
                            ZStack {
                                Circle()
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 3)
                                    .frame(width: 40, height: 40)
                                
                                Circle()
                                    .trim(from: 0, to: receivedMessageProgress)
                                    .stroke(
                                        receivedMessageProgress >= 1 ? Color.green : Color.orange,
                                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                                    )
                                    .frame(width: 40, height: 40)
                                    .rotationEffect(.degrees(-90))
                                
                                Text("\(p2pService.receivedMessageCount)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(receivedMessageProgress >= 1 ? .green : .primary)
                            }
                            
                            Text("Received")
                                .font(.system(size: 10))
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: p2pService.isMeaningfulInteraction)
        .animation(.easeInOut(duration: 0.3), value: p2pService.connectionDuration)
    }
}

#Preview {
    MeaningfulInteractionView()
        .environmentObject(P2PConnectivityService())
}