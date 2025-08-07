import Foundation
import MultipeerConnectivity

class P2PConnectivityService: NSObject, ObservableObject {

    @Published var messages: [ChatMessage] = []
    @Published var connectedPeer: MCPeerID?
    @Published var isHandshakeComplete = false
    @Published var sessionStartTime: Date?

    private let serviceType = "unseen-app"
    private let myPeerID = MCPeerID(displayName: UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString)
    private var serviceAdvertiser: MCNearbyServiceAdvertiser!
    private var serviceBrowser: MCNearbyServiceBrowser!
    
    private var noiseServices: [MCPeerID: NoiseService] = [:]
    private var pendingData: [MCPeerID: Data] = [:]
    
    // Connection state management
    private var connectionAttempts: Set<MCPeerID> = []
    private var isDiscoveryActive = false
    private var reconnectionTimer: Timer?
    private let reconnectionDelay: TimeInterval = 5.0  // Increased to 5 seconds for stability
    private var hasAwardedAnimaForSession = false
    private let minimumInteractionMessages = 3  // Require at least 3 message exchanges for ANIMA
    
    // Keepalive mechanism
    private var keepaliveTimer: Timer?
    private let keepaliveInterval: TimeInterval = 5.0  // Send keepalive every 5 seconds
    private let keepaliveMessage = "[KEEPALIVE]"

    lazy var session: MCSession = {
        let session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        return session
    }()

    override init() {
        super.init()
        startDiscovery()
    }
    
    deinit {
        stopDiscovery()
        stopKeepalive()
        reconnectionTimer?.invalidate()
        session.disconnect()
    }
    
    // Encapsulate starting both advertiser and browser
    private func startDiscovery() {
        guard !isDiscoveryActive else { 
            print("Discovery already active, skipping...")
            return 
        }
        
        print("Starting discovery...")
        isDiscoveryActive = true
        
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: serviceType)
        self.serviceAdvertiser.delegate = self
        self.serviceAdvertiser.startAdvertisingPeer()

        self.serviceBrowser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: serviceType)
        self.serviceBrowser.delegate = self
        self.serviceBrowser.startBrowsingForPeers()
    }
    
    // Encapsulate stopping both advertiser and browser
    private func stopDiscovery() {
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
            
            // Track our own sent messages for ANIMA calculation
            DispatchQueue.main.async {
                self.messages.append(ChatMessage(text: "[sent]\(message)"))
                self.checkAndAwardAnimaForMeaningfulInteraction()
            }
        }
    }

    private func initiateHandshake(for peerID: MCPeerID) {
        let isInitiator = myPeerID.displayName < peerID.displayName
        let role: NoiseService.HandshakeRole = isInitiator ? .initiator : .responder
        print("I am the \(role).")
        
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
                    print("📡 Keepalive received from \(peerID.displayName)")
                    return
                }
                
                print("🎉 Decrypted message: \(decryptedText)")
                DispatchQueue.main.async {
                    self.messages.append(ChatMessage(text: decryptedText))
                    self.checkAndAwardAnimaForMeaningfulInteraction()
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
                DispatchQueue.main.async {
                    self.isHandshakeComplete = true
                    self.sessionStartTime = Date()
                    print("Handshake complete. Session started.")
                    // Do NOT award ANIMA here - wait for meaningful interaction
                }
            }
        }
    }
}

extension P2PConnectivityService: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // Only accept if we're not already connected
        if session.connectedPeers.isEmpty && !connectionAttempts.contains(peerID) {
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
        // Prevent duplicate invitations
        guard connectionAttempts.insert(peerID).inserted else {
            return // Already attempting connection with this peer
        }
        
        // Check if we're already connected or have peers
        let isConnectedOrHasPeers = !session.connectedPeers.isEmpty
        
        // Only invite if we're not already connected and we're the "initiator" (lower ID)
        if !isConnectedOrHasPeers && myPeerID.displayName < peerID.displayName {
            print("Inviting peer: \(peerID.displayName)")
            browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 10)
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
                    self.messages.removeAll() // Clear messages on disconnect
                    self.stopKeepalive()  // Stop keepalive timer
                    
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
    
    // Award ANIMA only after meaningful interaction
    private func checkAndAwardAnimaForMeaningfulInteraction() {
        // Log current state for debugging
        let sentCount = messages.filter { $0.text.hasPrefix("[sent]") }.count
        let receivedCount = messages.filter { !$0.text.hasPrefix("[sent]") }.count
        print("📊 Message count - Sent: \(sentCount), Received: \(receivedCount), Total: \(messages.count)")
        
        guard !hasAwardedAnimaForSession,
              messages.count >= minimumInteractionMessages,
              isHandshakeComplete else { 
            if hasAwardedAnimaForSession {
                print("ANIMA already awarded for this session")
            } else if messages.count < minimumInteractionMessages {
                print("Need \(minimumInteractionMessages - messages.count) more messages for ANIMA")
            }
            return 
        }
        
        // Check if we have a mix of sent and received messages (real conversation)
        let hasSentMessages = sentCount > 0
        let hasReceivedMessages = receivedCount > 0
        
        guard hasSentMessages && hasReceivedMessages else { 
            print("Waiting for two-way conversation (sent: \(hasSentMessages), received: \(hasReceivedMessages))")
            return 
        }
        
        hasAwardedAnimaForSession = true
        
        // Award ANIMA through FirestoreService
        let firestoreService = FirestoreService()
        firestoreService.awardAnimaForConnection()
        
        print("✨ Meaningful interaction achieved! ANIMA awarded after \(messages.count) messages.")
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
                print("📡 Keepalive sent to \(peerID.displayName)")
            }
        }
    }
    
    private func stopKeepalive() {
        keepaliveTimer?.invalidate()
        keepaliveTimer = nil
    }
}
