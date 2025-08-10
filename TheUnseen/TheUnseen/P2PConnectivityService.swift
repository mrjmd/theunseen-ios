import Foundation
import MultipeerConnectivity
import FirebaseCrashlytics
import FirebasePerformance

class P2PConnectivityService: NSObject, ObservableObject {

    @Published var messages: [ChatMessage] = []
    @Published var connectedPeer: MCPeerID?
    @Published var isHandshakeComplete = false
    @Published var sessionStartTime: Date?
    @Published var currentPrompt: String?
    @Published var isMeaningfulInteraction = false
    @Published var connectionDuration: TimeInterval = 0
    @Published var connectionQuality: ConnectionQuality = .unknown
    
    enum ConnectionQuality {
        case unknown
        case poor       // Frequent disconnects
        case fair       // Some packet loss
        case good       // Stable connection
    }

    private let serviceType = "unseen-app"
    let myPeerID = MCPeerID(displayName: UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString)
    private var serviceAdvertiser: MCNearbyServiceAdvertiser!
    private var serviceBrowser: MCNearbyServiceBrowser!
    
    private var noiseServices: [MCPeerID: NoiseService] = [:]
    private var pendingData: [MCPeerID: Data] = [:]
    
    // Connection state management
    private var connectionAttempts: Set<MCPeerID> = []
    private var isDiscoveryActive = false
    private var reconnectionTimer: Timer?
    private let reconnectionDelay: TimeInterval = 5.0  // Increased to 5 seconds for stability
    
    // Block list management
    private var blockedFirebaseUIDs: Set<String> = []
    private var peerToFirebaseUID: [MCPeerID: String] = [:]
    
    // Performance tracking
    private var handshakeTrace: Trace?
    private var messageEncryptionTrace: Trace?
    
    // Meaningful Interaction requirements (per README)
    private var hasAwardedAnimaForSession = false
    private var minimumSessionDuration: TimeInterval {
        DeveloperSettings.shared.minimumSessionDuration
    }
    private let minimumMessagesPerUser = 3  // Each user must send at least 3 messages
    @Published var sentMessageCount = 0
    @Published var receivedMessageCount = 0
    private var sessionTimer: Timer?
    private var lastLoggedMessageCount = 0
    
    // Keepalive mechanism
    private var keepaliveTimer: Timer?
    private let keepaliveInterval: TimeInterval = 5.0  // Send keepalive every 5 seconds
    private let keepaliveMessage = "[KEEPALIVE]"
    private var keepaliveFailures = 0
    private var successfulMessages = 0

    lazy var session: MCSession = {
        let session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        return session
    }()

    override init() {
        super.init()
        // Never auto-start discovery - user must click "Begin The Path"
        // This ensures users have control over when they start seeking connections
        
        // Load blocked users list on initialization
        loadBlockedUsers()
    }
    
    deinit {
        stopDiscovery()
        stopKeepalive()
        reconnectionTimer?.invalidate()
        session.disconnect()
    }
    
    // Encapsulate starting both advertiser and browser
    func startDiscovery() {
        guard !isDiscoveryActive else { 
            print("Discovery already active, skipping...")
            return 
        }
        
        print("Starting discovery...")
        isDiscoveryActive = true
        
        // Include Firebase UID in discovery info for pre-connection blocking
        var discoveryInfo: [String: String]? = nil
        if let userId = AuthService().user?.uid {
            discoveryInfo = ["uid": userId]
        }
        
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: discoveryInfo, serviceType: serviceType)
        self.serviceAdvertiser.delegate = self
        self.serviceAdvertiser.startAdvertisingPeer()

        self.serviceBrowser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: serviceType)
        self.serviceBrowser.delegate = self
        self.serviceBrowser.startBrowsingForPeers()
    }
    
    // Encapsulate stopping both advertiser and browser
    func stopDiscovery() {
        guard isDiscoveryActive else { return }
        
        print("Stopping discovery...")
        isDiscoveryActive = false
        
        self.serviceAdvertiser?.stopAdvertisingPeer()
        self.serviceBrowser?.stopBrowsingForPeers()
        
        // Cancel any pending reconnection
        reconnectionTimer?.invalidate()
        reconnectionTimer = nil
    }
    
    func send(data: Data, to peer: MCPeerID) {
        guard !session.connectedPeers.isEmpty else { return }
        do {
            try session.send(data, toPeers: [peer], with: .reliable)
        } catch {
            print("Error sending data: \(error.localizedDescription)")
        }
    }

    func sendMessage(_ message: String) {
        guard let peerID = session.connectedPeers.first,
              let noiseService = noiseServices[peerID],
              isHandshakeComplete else {
            print("Error: Cannot send message. Handshake not complete or not connected.")
            return
        }

        if let encryptedData = noiseService.encrypt(message) {
            send(data: encryptedData, to: peerID)
            
            // Track our own sent messages (don't add to messages array - UI handles that)
            DispatchQueue.main.async {
                self.sentMessageCount += 1
                self.successfulMessages += 1
                self.updateConnectionQuality()
                self.checkMeaningfulInteraction()
            }
        }
    }
    
    // Send a system message (like prompt sync) that doesn't count as user message
    func sendSystemMessage(_ message: String) {
        guard let peerID = session.connectedPeers.first,
              let noiseService = noiseServices[peerID],
              isHandshakeComplete else {
            return
        }
        
        let systemMessage = "[SYSTEM]\(message)"
        if let encryptedData = noiseService.encrypt(systemMessage) {
            send(data: encryptedData, to: peerID)
            // Only log important system messages
            if message.contains("SACRED_SPACE") || message.contains("CONVERGENCE") || message.contains("HANDSHAKE") || message.contains("ACT_CHANGE") || message.contains("MEETUP") {
                print("📤 \(message)")
            }
        }
    }

    private func initiateHandshake(for peerID: MCPeerID) {
        let isInitiator = myPeerID.displayName < peerID.displayName
        let role: NoiseService.HandshakeRole = isInitiator ? .initiator : .responder
        print("I am the \(role).")
        
        // Start performance trace for handshake
        handshakeTrace = Performance.startTrace(name: "p2p_handshake")
        handshakeTrace?.setValue(role == .initiator ? "initiator" : "responder", forAttribute: "role")
        
        // Log to Crashlytics for debugging
        Crashlytics.crashlytics().log("Starting P2P handshake as \(role)")
        
        let noiseService = NoiseService(role: role)
        noiseServices[peerID] = noiseService
        
        if isInitiator {
            if let initialMessage = noiseService.createInitialHandshakeMessage() {
                send(data: initialMessage, to: peerID)
            }
        }
    }
    
    private func processReceivedData(_ data: Data, from peerID: MCPeerID) {
        guard let noiseService = noiseServices[peerID] else {
            print("Error: No NoiseService found for peer \(peerID.displayName) during processing.")
            return
        }

        if noiseService.isHandshakeComplete() {
            if let decryptedText = noiseService.decrypt(data) {
                // Ignore keepalive messages
                if decryptedText == keepaliveMessage {
                    // Silently ignore keepalive messages
                    return
                }
                
                // Handle system messages
                if decryptedText.hasPrefix("[SYSTEM]") {
                    let systemContent = decryptedText.replacingOccurrences(of: "[SYSTEM]", with: "")
                    // Only log important system messages
                    if systemContent.contains("SACRED_SPACE") || systemContent.contains("CONVERGENCE") || systemContent.contains("HANDSHAKE") || systemContent.contains("ACT_CHANGE") || systemContent.contains("MEETUP") {
                        print("📥 \(systemContent)")
                    }
                    
                    // Handle journey and prompt sync
                    if systemContent.hasPrefix("JOURNEY_ID:") {
                        let journeyId = systemContent.replacingOccurrences(of: "JOURNEY_ID:", with: "")
                        // Journey ID received (logged elsewhere)
                        DispatchQueue.main.async {
                            PromptsService.shared.receiveJourneyId(journeyId, using: self)
                            // Update our current prompt display
                            if let prompt = PromptsService.shared.currentPrompt {
                                self.currentPrompt = PromptsService.shared.formatPromptWithVoice(prompt)
                            }
                            // Send acknowledgment
                            self.sendSystemMessage("JOURNEY_ACK")
                        }
                    }
                    // Handle journey request from responder
                    else if systemContent == "REQUEST_JOURNEY" {
                        // Resending journey on request
                        DispatchQueue.main.async {
                            if let journey = PromptsService.shared.currentJourney {
                                self.sendSystemMessage("JOURNEY_ID:\(journey.id)")
                            }
                        }
                    }
                    // Handle journey acknowledgment
                    else if systemContent == "JOURNEY_ACK" {
                        // Journey acknowledged
                    }
                    // Handle act changes
                    else if systemContent.hasPrefix("ACT_CHANGE:") {
                        let actString = systemContent.replacingOccurrences(of: "ACT_CHANGE:", with: "")
                        if let act = Int(actString) {
                            print("🎭 Received act change: \(act)")
                            DispatchQueue.main.async {
                                PromptsService.shared.receiveActChange(act, using: self)
                            }
                        }
                    }
                    // Legacy prompt ID sync
                    else if systemContent.hasPrefix("PROMPT_ID:") {
                        let promptId = systemContent.replacingOccurrences(of: "PROMPT_ID:", with: "")
                        print("📥 Received prompt ID: \(promptId)")
                        DispatchQueue.main.async {
                            PromptsService.shared.receivePromptId(promptId, using: self)
                        }
                    }
                    // Legacy prompt sync support
                    else if systemContent.hasPrefix("PROMPT:") {
                        let prompt = systemContent.replacingOccurrences(of: "PROMPT:", with: "")
                        print("📥 Setting shared prompt (legacy): \(prompt)")
                        DispatchQueue.main.async {
                            self.currentPrompt = prompt
                        }
                    }
                    // Handle Convergence, Meetup, and Sacred Space messages - add them to messages array for UI to see
                    else if systemContent.contains("CONVERGENCE") || systemContent.contains("MEETUP") || systemContent.contains("HANDSHAKE") || systemContent.contains("SACRED_SPACE") || systemContent.contains("ARTIFACT_CREATED") || systemContent.contains("RESONANCE_SCORES") {
                        DispatchQueue.main.async {
                            // Add to messages array so UI components can detect it
                            self.messages.append(ChatMessage(text: "[SYSTEM]\(systemContent)"))
                        }
                    }
                    return
                }
                
                print("🎉 Decrypted message: \(decryptedText)")
                DispatchQueue.main.async {
                    self.messages.append(ChatMessage(text: decryptedText))
                    self.receivedMessageCount += 1
                    self.checkMeaningfulInteraction()
                    
                    // Light haptic for received message
                    HapticManager.shared.lightImpact()
                    SoundManager.shared.play(.messageReceived, volume: 0.3)
                }
            }
        } else {
            print("Received handshake data from \(peerID.displayName).")
            var handshakeDidComplete = false
            if noiseService.isExpectingInitialMessage() {
                if let reply = noiseService.handleInitialHandshakeMessage(data) {
                    send(data: reply, to: peerID)
                    handshakeDidComplete = true
                }
            } else {
                handshakeDidComplete = noiseService.handleResponderReplyMessage(data)
            }
            
            if handshakeDidComplete {
                // Stop performance trace
                handshakeTrace?.stop()
                handshakeTrace = nil
                
                // Log success to Crashlytics
                Crashlytics.crashlytics().log("P2P handshake completed successfully")
                
                DispatchQueue.main.async {
                    self.isHandshakeComplete = true
                    // Don't start timer yet - wait for journey to be established
                    print("Handshake complete. Ready for journey.")
                    // Do NOT award ANIMA here - wait for meaningful interaction
                    
                    // Sensory feedback for connection
                    HapticManager.shared.connectionEstablished()
                    SoundManager.shared.playConnectionSequence()
                }
            }
        }
    }
}

extension P2PConnectivityService: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // Extract Firebase UID from context if available
        var peerUID: String? = nil
        if let context = context {
            do {
                if let info = try JSONSerialization.jsonObject(with: context) as? [String: String] {
                    peerUID = info["uid"]
                }
            } catch {
                print("Failed to parse invitation context")
            }
        }
        
        // Check if this user is blocked
        if let uid = peerUID, blockedFirebaseUIDs.contains(uid) {
            print("🛡️ Declining invitation from blocked user: \(peerID.displayName)")
            invitationHandler(false, nil)
            return
        }
        
        // Check if we recently had a session with this peer
        if let lastSessionDate = UserDefaults.standard.object(forKey: "lastSession_\(peerID.displayName)") as? Date {
            let secondsSinceLastSession = Date().timeIntervalSince(lastSessionDate)
            let cooldownSeconds = DeveloperSettings.shared.rematchCooldown
            if secondsSinceLastSession < cooldownSeconds {
                print("Declining invitation from \(peerID.displayName) - cooldown active")
                invitationHandler(false, nil)
                return
            }
        }
        
        // Only accept if we're not already connected
        if session.connectedPeers.isEmpty && !connectionAttempts.contains(peerID) {
            // Store the peer's Firebase UID for later use
            if let uid = peerUID {
                peerToFirebaseUID[peerID] = uid
            }
            
            print("Accepting invitation from: \(peerID.displayName)")
            connectionAttempts.insert(peerID)
            invitationHandler(true, self.session)
        } else {
            print("Declining invitation from \(peerID.displayName) - already connected or attempting connection")
            invitationHandler(false, nil)
        }
    }
}

extension P2PConnectivityService: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        // Check if this user is blocked based on their Firebase UID
        if let uid = info?["uid"], blockedFirebaseUIDs.contains(uid) {
            print("🛡️ Skipping blocked user: \(peerID.displayName)")
            return
        }
        
        // Check if we recently had a session with this peer
        if let lastSessionDate = UserDefaults.standard.object(forKey: "lastSession_\(peerID.displayName)") as? Date {
            let secondsSinceLastSession = Date().timeIntervalSince(lastSessionDate)
            let cooldownSeconds = DeveloperSettings.shared.rematchCooldown
            if secondsSinceLastSession < cooldownSeconds {
                let remaining = Int(cooldownSeconds - secondsSinceLastSession)
                print("Skipping peer \(peerID.displayName) - cooldown active (\(remaining)s remaining)")
                return
            }
        }
        
        // Prevent duplicate invitations
        guard connectionAttempts.insert(peerID).inserted else {
            return // Already attempting connection with this peer
        }
        
        // Check if we're already connected or have peers
        let isConnectedOrHasPeers = !session.connectedPeers.isEmpty
        
        // Only invite if we're not already connected and we're the "initiator" (lower ID)
        if !isConnectedOrHasPeers && myPeerID.displayName < peerID.displayName {
            // Store the peer's Firebase UID for later use
            if let uid = info?["uid"] {
                peerToFirebaseUID[peerID] = uid
            }
            
            // Include our Firebase UID in the invitation context
            var contextData: Data? = nil
            if let myUID = AuthService().user?.uid {
                let contextInfo = ["uid": myUID]
                contextData = try? JSONSerialization.data(withJSONObject: contextInfo)
            }
            
            print("Inviting peer: \(peerID.displayName)")
            browser.invitePeer(peerID, to: self.session, withContext: contextData, timeout: 10)
        } else {
            // Remove from attempts if we're not inviting
            connectionAttempts.remove(peerID)
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        connectionAttempts.remove(peerID)
    }
}

extension P2PConnectivityService: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected:
                print("Connected to: \(peerID.displayName)")
                self.connectionAttempts.remove(peerID)
                self.stopDiscovery() // Stop both advertiser and browser
                self.connectedPeer = peerID
                self.initiateHandshake(for: peerID)
                self.startKeepalive()  // Start sending keepalive messages
                self.keepaliveFailures = 0
                self.successfulMessages = 0
                self.connectionQuality = .unknown
                
                if let data = self.pendingData[peerID] {
                    print("Processing queued data for \(peerID.displayName)")
                    self.processReceivedData(data, from: peerID)
                    self.pendingData.removeValue(forKey: peerID)
                }
                
            case .connecting:
                print("Connecting to: \(peerID.displayName)")
                
            case .notConnected:
                print("Disconnected from: \(peerID.displayName)")
                
                // Log session duration if we had one
                if let startTime = self.sessionStartTime {
                    let duration = Date().timeIntervalSince(startTime)
                    print("Session lasted \(Int(duration)) seconds with \(self.messages.count) messages exchanged")
                }
                
                self.connectionAttempts.remove(peerID)
                self.noiseServices.removeValue(forKey: peerID)
                self.pendingData.removeValue(forKey: peerID)
                
                if self.connectedPeer == peerID {
                    self.connectedPeer = nil
                    self.isHandshakeComplete = false
                    self.sessionStartTime = nil
                    self.hasAwardedAnimaForSession = false
                    self.isMeaningfulInteraction = false
                    self.connectionDuration = 0
                    self.sentMessageCount = 0
                    self.receivedMessageCount = 0
                    self.messages.removeAll() // Clear messages on disconnect
                    self.stopKeepalive()  // Stop keepalive timer
                    self.stopSessionTimer()  // Stop session timer
                    self.connectionQuality = .unknown
                    
                    // Schedule reconnection with delay to prevent flapping
                    self.scheduleReconnection()
                }
                
            @unknown default:
                print("Unknown state received: \(state)")
            }
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if noiseServices[peerID] == nil {
            print("Queuing data from \(peerID.displayName), session not fully established.")
            pendingData[peerID] = data
        } else {
            processReceivedData(data, from: peerID)
        }
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
    
    // Helper method to schedule reconnection with delay
    private func scheduleReconnection() {
        // Cancel any existing timer
        reconnectionTimer?.invalidate()
        
        print("Scheduling reconnection in \(reconnectionDelay) seconds...")
        reconnectionTimer = Timer.scheduledTimer(withTimeInterval: reconnectionDelay, repeats: false) { [weak self] _ in
            self?.startDiscovery()
        }
    }
    
    // Check for meaningful interaction based on time and message count
    func loadBlockedUsers() {
        let firestoreService = FirestoreService()
        firestoreService.getBlockedUsers { blockedUIDs in
            DispatchQueue.main.async {
                self.blockedFirebaseUIDs = Set(blockedUIDs)
                print("🛡️ Loaded \(blockedUIDs.count) blocked users")
            }
        }
    }
    
    private func checkMeaningfulInteraction() {
        // Only log every 10 seconds or when messages change
        let shouldLog = Int(connectionDuration) % 10 == 0 || 
                       (sentMessageCount + receivedMessageCount) != lastLoggedMessageCount
        
        if shouldLog && Int(connectionDuration) % 30 == 0 {
            print("📊 Session: \(Int(connectionDuration))s, Sent: \(sentMessageCount), Received: \(receivedMessageCount)")
            lastLoggedMessageCount = sentMessageCount + receivedMessageCount
        }
        
        // Check if we meet both requirements
        let hasEnoughTime = connectionDuration >= minimumSessionDuration
        let hasEnoughSentMessages = sentMessageCount >= minimumMessagesPerUser
        let hasEnoughReceivedMessages = receivedMessageCount >= minimumMessagesPerUser
        
        if hasEnoughTime && hasEnoughSentMessages && hasEnoughReceivedMessages {
            if !isMeaningfulInteraction {
                DispatchQueue.main.async {
                    self.isMeaningfulInteraction = true
                    print("✅ Meaningful Interaction achieved! Duration: \(Int(self.connectionDuration))s, Messages: \(self.sentMessageCount) sent, \(self.receivedMessageCount) received")
                    
                    // Award ANIMA for meaningful interaction (not just connection)
                    if !self.hasAwardedAnimaForSession {
                        self.hasAwardedAnimaForSession = true
                        let firestoreService = FirestoreService()
                        firestoreService.awardAnimaForConnection()
                        print("✨ ANIMA awarded for meaningful interaction!")
                    }
                }
            }
        } else if shouldLog && !isMeaningfulInteraction {
            // Only show needs occasionally
            var needs = [String]()
            if !hasEnoughTime {
                let remaining = Int(minimumSessionDuration - connectionDuration)
                needs.append("\(remaining)s")
            }
            if !hasEnoughSentMessages {
                needs.append("\(minimumMessagesPerUser - sentMessageCount) sent")
            }
            if !hasEnoughReceivedMessages {
                needs.append("\(minimumMessagesPerUser - receivedMessageCount) received")
            }
            if !needs.isEmpty && Int(connectionDuration) % 30 == 0 {
                print("⏳ Need: \(needs.joined(separator: ", "))")
            }
        }
    }
    
    // Start tracking session duration
    func startSessionTimer() {
        // Only start if not already running
        guard sessionTimer == nil else { return }
        
        // Set start time if not already set
        if sessionStartTime == nil {
            sessionStartTime = Date()
        }
        
        // Update connection duration every second
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self,
                  let startTime = self.sessionStartTime else { return }
            
            DispatchQueue.main.async {
                self.connectionDuration = Date().timeIntervalSince(startTime)
                
                // Check if we've achieved meaningful interaction
                self.checkMeaningfulInteraction()
            }
        }
        
        print("⏱️ Session timer started - meaningful interaction tracking begins")
    }
    
    // Stop tracking session duration
    private func stopSessionTimer() {
        sessionTimer?.invalidate()
        sessionTimer = nil
        print("⏱️ Session timer stopped")
    }
    
    // Keepalive mechanism to prevent connection timeout
    private func startKeepalive() {
        stopKeepalive()  // Ensure no duplicate timers
        
        keepaliveTimer = Timer.scheduledTimer(withTimeInterval: keepaliveInterval, repeats: true) { [weak self] _ in
            guard let self = self,
                  let peerID = self.session.connectedPeers.first,
                  let noiseService = self.noiseServices[peerID],
                  self.isHandshakeComplete else {
                print("⚠️ Cannot send keepalive - not properly connected")
                return
            }
            
            if let encryptedData = noiseService.encrypt(self.keepaliveMessage) {
                self.send(data: encryptedData, to: peerID)
                // Silently send keepalive
            }
        }
    }
    
    private func stopKeepalive() {
        keepaliveTimer?.invalidate()
        keepaliveTimer = nil
    }
    
    private func updateConnectionQuality() {
        // Update connection quality based on success rate
        let totalAttempts = successfulMessages + keepaliveFailures
        guard totalAttempts > 0 else { 
            connectionQuality = .unknown
            return 
        }
        
        let successRate = Double(successfulMessages) / Double(totalAttempts)
        
        if successRate > 0.9 {
            connectionQuality = .good
        } else if successRate > 0.7 {
            connectionQuality = .fair
        } else {
            connectionQuality = .poor
        }
        
        if connectionQuality == .poor && keepaliveFailures > 3 {
            print("⚠️ Poor connection quality detected - \(keepaliveFailures) keepalive failures")
        }
    }
}
