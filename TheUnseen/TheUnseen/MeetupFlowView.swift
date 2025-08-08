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
    @State private var waitingForPartnerToEnter = false
    @State private var partnerReadyToEnter = false
    @State private var lastProcessedMessageCount = 0
    
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
                    waitingForPartner: $waitingForPartnerToEnter,
                    partnerReady: $partnerReadyToEnter,
                    onContinue: {
                        enterSacredSpace()
                    }
                )
            }
            
            Spacer()
        }
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.light)
        .onReceive(p2pService.$messages) { messages in
            // Only process NEW messages we haven't seen before
            let newMessageCount = messages.count - lastProcessedMessageCount
            if newMessageCount > 0 {
                let newMessages = messages.suffix(newMessageCount)
                for message in newMessages {
                    handleSystemMessage(message)
                }
                lastProcessedMessageCount = messages.count
            }
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
    
    private func handleSystemMessage(_ message: ChatMessage) {
        print("📩 MeetupFlowView processing: \(message.text.prefix(50))...")
        
        // Check if this is a sacred space message FIRST
        if message.text.contains("SACRED_SPACE_REQUEST") {
            print("🚨 SACRED_SPACE_REQUEST detected!")
            print("   Message: \(message.text)")
            print("   Current state - waiting: \(waitingForPartnerToEnter), partnerReady: \(partnerReadyToEnter)")
            
            DispatchQueue.main.async {
                self.partnerReadyToEnter = true
                print("   ✅ Set partnerReadyToEnter = true")
                
                // If we're also waiting, both can proceed
                if self.waitingForPartnerToEnter {
                    print("   🎯 Both ready, starting sacred space")
                    self.p2pService.sendSystemMessage("SACRED_SPACE_START")
                    self.showingConvergence = true
                } else {
                    print("   ⏳ Partner is ready, waiting for us to confirm")
                }
            }
            return
        }
        
        if message.text.contains("SACRED_SPACE_START") {
            print("🚨 SACRED_SPACE_START detected!")
            DispatchQueue.main.async {
                self.showingConvergence = true
            }
            return
        }
        
        if message.text.contains("MEETUP_DESC:") {
            // Parse peer's description including session ID
            let desc = message.text.replacingOccurrences(of: "[SYSTEM]MEETUP_DESC:", with: "")
            
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
        } else if message.text.contains("HANDSHAKE_INITIATE") {
            // Peer is ready for handshake
            performDigitalHandshake()
        } else if message.text.contains("HANDSHAKE_CONFIRM") {
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
    
    private func enterSacredSpace() {
        print("🎭 Enter sacred space clicked. Partner ready: \(partnerReadyToEnter)")
        
        // Set our state first
        waitingForPartnerToEnter = true
        
        if partnerReadyToEnter {
            // Partner already signaled ready, both can enter
            print("✅ Partner was ready, starting sacred space")
            p2pService.sendSystemMessage("SACRED_SPACE_START")
            showingConvergence = true
        } else {
            // Send our readiness signal
            print("⏳ Sending ready signal, waiting for partner")
            p2pService.sendSystemMessage("SACRED_SPACE_REQUEST")
        }
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
    @Binding var waitingForPartner: Bool
    @Binding var partnerReady: Bool
    let onContinue: () -> Void
    @State private var showCheckmark = false
    
    var body: some View {
        let _ = print("🎨 HandshakeSuccessView - waiting: \(waitingForPartner), partnerReady: \(partnerReady)")
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
            
            if waitingForPartner {
                VStack(spacing: 12) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .purple))
                    Text("Waiting for partner to be ready...")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
            } else if partnerReady {
                VStack(spacing: 8) {
                    Text("Your partner is ready!")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    Button(action: onContinue) {
                        HStack {
                            Image(systemName: "checkmark.circle")
                            Text("Yes, I'm Ready Too")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
            } else {
                VStack(spacing: 8) {
                    Text("When you're both together and ready, tap below")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    
                    Button(action: onContinue) {
                        HStack {
                            Image(systemName: "arrow.right.circle")
                            Text("We're Both Ready")
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
                }
                .padding(.horizontal)
            }
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