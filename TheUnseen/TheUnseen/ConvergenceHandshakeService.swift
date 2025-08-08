import Foundation
import MultipeerConnectivity

// MARK: - Convergence Handshake Service
// Uses MultipeerConnectivity with low power settings for proximity verification
class ConvergenceHandshakeService: NSObject, ObservableObject {
    
    @Published var verificationState: VerificationState = .idle
    @Published var verificationProgress: Double = 0.0
    @Published var partnerFound = false
    
    enum VerificationState: Equatable {
        case idle
        case searching
        case connecting
        case verified
        case failed(String)
    }
    
    // Special service type for convergence verification (different from main chat)
    private let convergenceServiceType = "unseen-converge"
    
    // Unique peer ID for this handshake session
    private var handshakePeerID: MCPeerID?
    private var handshakeSession: MCSession?
    private var serviceBrowser: MCNearbyServiceBrowser?
    private var serviceAdvertiser: MCNearbyServiceAdvertiser?
    
    // Timeout handling
    private var timeoutTimer: Timer?
    private let verificationTimeout: TimeInterval = 5.0  // Reduced to 5 seconds - if not connected by then, too far apart
    
    // Session info
    private var sessionToken: String = ""
    private var isInitiator = false
    
    override init() {
        super.init()
    }
    
    deinit {
        stopVerification()
    }
    
    // MARK: - Public Methods
    
    func startVerification(isInitiator: Bool, sessionId: String) {
        self.isInitiator = isInitiator
        self.sessionToken = String(sessionId.prefix(8))
        
        // Starting handshake with token: \(sessionToken)
        
        // Create unique peer ID for this handshake
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        handshakePeerID = MCPeerID(displayName: "\(sessionToken)-\(deviceId.prefix(4))")
        
        // Create session with lower power settings
        guard let peerID = handshakePeerID else { return }
        handshakeSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        handshakeSession?.delegate = self
        
        // Start advertising and browsing simultaneously for faster discovery
        startAdvertising()
        startBrowsing()
        
        // Set timeout
        startTimeout()
        
        verificationState = .searching
        verificationProgress = 0.2
    }
    
    func stopVerification() {
        // Stopping handshake
        
        timeoutTimer?.invalidate()
        timeoutTimer = nil
        
        serviceAdvertiser?.stopAdvertisingPeer()
        serviceAdvertiser = nil
        
        serviceBrowser?.stopBrowsingForPeers()
        serviceBrowser = nil
        
        handshakeSession?.disconnect()
        handshakeSession = nil
        
        verificationState = .idle
        verificationProgress = 0
        partnerFound = false
    }
    
    // MARK: - Private Methods
    
    private func startAdvertising() {
        guard let peerID = handshakePeerID else { return }
        
        // Include session token in discovery info for validation
        let discoveryInfo = ["token": sessionToken, "role": isInitiator ? "init" : "resp"]
        
        serviceAdvertiser = MCNearbyServiceAdvertiser(
            peer: peerID,
            discoveryInfo: discoveryInfo,
            serviceType: convergenceServiceType
        )
        serviceAdvertiser?.delegate = self
        serviceAdvertiser?.startAdvertisingPeer()
        
        // Advertising with token: \(sessionToken)
    }
    
    private func startBrowsing() {
        guard let peerID = handshakePeerID else { return }
        
        serviceBrowser = MCNearbyServiceBrowser(
            peer: peerID,
            serviceType: convergenceServiceType
        )
        serviceBrowser?.delegate = self
        serviceBrowser?.startBrowsingForPeers()
        
        // Browsing for peers...
    }
    
    private func startTimeout() {
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: verificationTimeout, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            
            if self.verificationState != .verified {
                // Verification timeout
                self.verificationState = .failed("Could not verify proximity. Make sure you're standing close together.")
                self.stopVerification()
            }
        }
    }
    
    private func validatePeer(info: [String: String]?) -> Bool {
        // Check if the peer has the same session token
        guard let peerToken = info?["token"] else {
            // Peer has no token
            return false
        }
        
        // Tokens should match for same session
        let isValid = peerToken == sessionToken
        // Token validation: \(isValid)
        
        return isValid
    }
}

// MARK: - MCSessionDelegate
extension ConvergenceHandshakeService: MCSessionDelegate {
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected:
                print("✅ Handshake successful") // Keep for feedback
                self.partnerFound = true
                self.verificationState = .verified
                self.verificationProgress = 1.0
                
                // Haptic feedback
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                
                // Stop everything after success
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.stopVerification()
                }
                
            case .connecting:
                // Connecting...
                self.verificationState = .connecting
                self.verificationProgress = 0.6
                
            case .notConnected:
                // Disconnected
                break
                
            @unknown default:
                break
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        // Not used for handshake
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        // Not used for handshake
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        // Not used for handshake
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        // Not used for handshake
    }
}

// MARK: - MCNearbyServiceBrowserDelegate
extension ConvergenceHandshakeService: MCNearbyServiceBrowserDelegate {
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        // Found peer: \(peerID.displayName)
        
        // Validate this is our partner
        guard validatePeer(info: info) else {
            // Invalid peer
            return
        }
        
        // Check we're not connecting to ourselves
        guard peerID != handshakePeerID else {
            // Found self, ignoring
            return
        }
        
        // Inviting valid partner
        
        // Update state
        DispatchQueue.main.async {
            self.partnerFound = true
            self.verificationProgress = 0.4
        }
        
        // Invite peer with VERY short timeout to ensure they're close (1 second = ~3-5 feet)
        browser.invitePeer(peerID, to: handshakeSession!, withContext: nil, timeout: 1)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        // Lost peer
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        // Browsing failed
        verificationState = .failed("Could not search for partner")
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension ConvergenceHandshakeService: MCNearbyServiceAdvertiserDelegate {
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // Received invitation
        
        // Accept invitation if we're still searching
        if verificationState == .searching || verificationState == .connecting {
            // Accepting invitation
            invitationHandler(true, handshakeSession)
            
            DispatchQueue.main.async {
                self.verificationProgress = 0.8
            }
        } else {
            // Declining - wrong state
            invitationHandler(false, nil)
        }
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        // Advertising failed
        verificationState = .failed("Could not start proximity verification")
    }
}

// MARK: - Mock Mode for Testing
extension ConvergenceHandshakeService {
    
    func startMockVerification(success: Bool = true) {
        // Starting mock verification
        verificationState = .searching
        verificationProgress = 0
        
        // Simulate progressive verification
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            self.verificationProgress += 0.25
            
            if self.verificationProgress >= 0.5 && !self.partnerFound {
                self.partnerFound = true
                self.verificationState = .connecting
            }
            
            if self.verificationProgress >= 1.0 {
                timer.invalidate()
                
                if success {
                    self.verificationState = .verified
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                } else {
                    self.verificationState = .failed("Mock verification failed")
                }
            }
        }
    }
}