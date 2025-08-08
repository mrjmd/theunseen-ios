import SwiftUI

struct MeetupFlowView: View {
    @EnvironmentObject var p2pService: P2PConnectivityService
    @StateObject private var handshakeService = ConvergenceHandshakeService()
    @State private var meetupPhase: MeetupPhase = .describing
    @State private var locationDescription = ""
    @State private var appearanceDescription = ""
    @State private var peerDescription = ""
    @State private var handshakeInProgress = false
    @State private var handshakeComplete = false
    @State private var showingConvergence = false
    @State private var sessionId = UUID().uuidString
    
    enum MeetupPhase {
        case describing      // Initiator describes location/appearance
        case findingPeer    // Responder looking for initiator
        case confirming     // Both confirming arrival
        case verified       // Handshake complete
    }
    
    var isInitiator: Bool {
        p2pService.myPeerID.displayName < (p2pService.connectedPeer?.displayName ?? "")
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "figure.2.circle")
                    .font(.system(size: 40))
                    .foregroundColor(.purple)
                
                Text("The Convergence")
                    .font(.title2)
                    .fontWeight(.light)
                    .tracking(2)
                
                Text("Physical Meetup")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
            
            Spacer()
            
            // Content based on phase
            switch meetupPhase {
            case .describing:
                if isInitiator {
                    DescribeLocationView(
                        locationDescription: $locationDescription,
                        appearanceDescription: $appearanceDescription,
                        onSubmit: {
                            sendDescription()
                            meetupPhase = .confirming
                        }
                    )
                } else {
                    WaitingForDescriptionView()
                }
                
            case .findingPeer:
                FindingPeerView(peerDescription: peerDescription)
                
            case .confirming:
                ConfirmArrivalView(
                    peerDescription: isInitiator ? "Waiting for peer to arrive..." : peerDescription,
                    handshakeInProgress: handshakeInProgress,
                    handshakeService: handshakeService,
                    onConfirm: {
                        initiateHandshake()
                    }
                )
                
            case .verified:
                HandshakeSuccessView(
                    onContinue: {
                        showingConvergence = true
                    }
                )
            }
            
            Spacer()
        }
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.light)
        .onReceive(p2pService.$messages) { messages in
            handleSystemMessages(messages)
        }
        .fullScreenCover(isPresented: $showingConvergence) {
            NavigationStack {
                ConvergenceView()
            }
        }
    }
    
    private func sendDescription() {
        let description = "LOCATION:\(locationDescription)|APPEARANCE:\(appearanceDescription)|SESSION:\(sessionId)"
        p2pService.sendSystemMessage("MEETUP_DESC:\(description)")
    }
    
    private func handleSystemMessages(_ messages: [ChatMessage]) {
        guard let lastMessage = messages.last else { return }
        
        if lastMessage.text.contains("MEETUP_DESC:") {
            // Parse peer's description including session ID
            let desc = lastMessage.text.replacingOccurrences(of: "[SYSTEM]MEETUP_DESC:", with: "")
            
            // Extract session ID
            if let sessionRange = desc.range(of: "SESSION:") {
                let sessionPart = desc[sessionRange.upperBound...]
                if let endIndex = sessionPart.firstIndex(of: "|") {
                    sessionId = String(sessionPart[..<endIndex])
                } else {
                    sessionId = String(sessionPart)
                }
            }
            
            // Format description for display
            peerDescription = desc
                .replacingOccurrences(of: "LOCATION:", with: "Location: ")
                .replacingOccurrences(of: "|APPEARANCE:", with: "\nAppearance: ")
                .replacingOccurrences(of: "|SESSION:\(sessionId)", with: "")
            
            if !isInitiator {
                meetupPhase = .findingPeer
            }
        } else if lastMessage.text.contains("HANDSHAKE_INITIATE") {
            // Peer is ready for handshake
            performDigitalHandshake()
        } else if lastMessage.text.contains("HANDSHAKE_CONFIRM") {
            // Handshake confirmed
            completeHandshake()
        }
    }
    
    private func initiateHandshake() {
        handshakeInProgress = true
        p2pService.sendSystemMessage("HANDSHAKE_INITIATE")
        
        // Start verification process
        performDigitalHandshake()
    }
    
    private func performDigitalHandshake() {
        // Use MultipeerConnectivity for proximity verification
        handshakeInProgress = true
        
        // Check if we should use mock mode for simulator
        #if targetEnvironment(simulator)
        handshakeService.startMockVerification(success: true)
        #else
        handshakeService.startVerification(isInitiator: isInitiator, sessionId: sessionId)
        #endif
        
        // Monitor verification state
        observeHandshakeVerification()
    }
    
    private func observeHandshakeVerification() {
        // Check verification state periodically
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            switch handshakeService.verificationState {
            case .verified:
                timer.invalidate()
                p2pService.sendSystemMessage("HANDSHAKE_CONFIRM")
                completeHandshake()
            case .failed(let reason):
                timer.invalidate()
                handshakeInProgress = false
                print("❌ Handshake failed: \(reason)")
                // Could show an alert here
            default:
                // Still verifying
                break
            }
        }
    }
    
    private func completeHandshake() {
        handshakeInProgress = false
        handshakeComplete = true
        meetupPhase = .verified
        
        // Haptic feedback
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }
}

// MARK: - Sub Views

struct DescribeLocationView: View {
    @Binding var locationDescription: String
    @Binding var appearanceDescription: String
    let onSubmit: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Describe Your Location & Appearance")
                .font(.headline)
                .fontWeight(.light)
            
            Text("Help your partner find you")
                .font(.caption)
                .foregroundColor(.gray)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Where are you?")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                TextField("e.g., By the fountain near the entrance", text: $locationDescription)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("What are you wearing?")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                TextField("e.g., Red scarf, black jacket", text: $appearanceDescription)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding(.horizontal)
            
            Button(action: onSubmit) {
                Text("Send to Partner")
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
            .disabled(locationDescription.isEmpty || appearanceDescription.isEmpty)
            .padding()
        }
    }
}

struct WaitingForDescriptionView: View {
    @State private var dots = ""
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Waiting for location details\(dots)")
                .font(.headline)
                .fontWeight(.light)
            
            Text("Your partner is describing where to meet")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .onAppear {
            animateDots()
        }
    }
    
    private func animateDots() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            dots = dots.count >= 3 ? "" : dots + "."
        }
    }
}

struct FindingPeerView: View {
    let peerDescription: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "binoculars")
                .font(.system(size: 50))
                .foregroundColor(.purple)
            
            Text("Find Your Partner")
                .font(.headline)
                .fontWeight(.light)
            
            Text(peerDescription)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
            
            Text("When you find each other, both tap 'Confirm Arrival'")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
}

struct ConfirmArrivalView: View {
    let peerDescription: String
    let handshakeInProgress: Bool
    let handshakeService: ConvergenceHandshakeService?
    let onConfirm: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            if !peerDescription.isEmpty && !peerDescription.contains("Waiting") {
                Text("Meeting Location")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text(peerDescription)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
            }
            
            Image(systemName: handshakeInProgress ? "antenna.radiowaves.left.and.right" : "hand.raised")
                .font(.system(size: 60))
                .foregroundColor(.purple)
                .symbolEffect(.pulse, isActive: handshakeInProgress)
            
            if handshakeInProgress {
                VStack(spacing: 16) {
                    // Show verification progress
                    if let service = handshakeService {
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                                .frame(width: 80, height: 80)
                            
                            Circle()
                                .trim(from: 0, to: service.verificationProgress)
                                .stroke(Color.purple, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                .frame(width: 80, height: 80)
                                .rotationEffect(.degrees(-90))
                                .animation(.easeInOut, value: service.verificationProgress)
                            
                            if service.partnerFound {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 30))
                                    .foregroundColor(.green)
                            } else {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                    } else {
                        ProgressView()
                    }
                    
                    Text("Verifying proximity...")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    if handshakeService?.partnerFound == true {
                        Text("Partner found! Confirming...")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }
            } else {
                VStack(spacing: 12) {
                    Text("Are you both ready?")
                        .font(.headline)
                        .fontWeight(.light)
                    
                    Text("Make sure you're both in the same location")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Button(action: onConfirm) {
                        HStack {
                            Image(systemName: "checkmark.circle")
                            Text("Confirm Arrival")
                        }
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
                    .padding(.horizontal)
                }
            }
        }
    }
}

struct HandshakeSuccessView: View {
    let onContinue: () -> Void
    @State private var showCheckmark = false
    
    var body: some View {
        VStack(spacing: 30) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                    .scaleEffect(showCheckmark ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showCheckmark)
            }
            
            VStack(spacing: 12) {
                Text("Connection Verified!")
                    .font(.title2)
                    .fontWeight(.light)
                
                Text("You're both here. The container is ready.")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Button(action: onContinue) {
                HStack {
                    Image(systemName: "arrow.right.circle")
                    Text("Enter the Sacred Space")
                }
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
            .padding(.horizontal)
        }
        .onAppear {
            showCheckmark = true
        }
    }
}

#Preview {
    NavigationStack {
        MeetupFlowView()
            .environmentObject(P2PConnectivityService())
    }
}