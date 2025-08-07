import Foundation
import MultipeerConnectivity

class P2PConnectivityService: NSObject, ObservableObject {

    @Published var messages: [ChatMessage] = []
    @Published var connectedPeer: MCPeerID?
    @Published var isHandshakeComplete = false

    private let serviceType = "unseen-app"
    private let myPeerID = MCPeerID(displayName: UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString)
    private var serviceAdvertiser: MCNearbyServiceAdvertiser!
    private var serviceBrowser: MCNearbyServiceBrowser!
    
    private var noiseServices: [MCPeerID: NoiseService] = [:]
    // This queue will hold data that arrives before the session is fully ready.
    private var pendingData: [MCPeerID: Data] = [:]

    lazy var session: MCSession = {
        let session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        return session
    }()

    override init() {
        super.init()
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: serviceType)
        self.serviceAdvertiser.delegate = self
        self.serviceAdvertiser.startAdvertisingPeer()

        self.serviceBrowser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: serviceType)
        self.serviceBrowser.delegate = self
        self.serviceBrowser.startBrowsingForPeers()
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
    
    // This new function will process data, either immediately or from the queue.
    private func processReceivedData(_ data: Data, from peerID: MCPeerID) {
        guard let noiseService = noiseServices[peerID] else {
            print("Error: No NoiseService found for peer \(peerID.displayName)")
            return
        }

        if noiseService.isHandshakeComplete() {
            if let decryptedText = noiseService.decrypt(data) {
                print("🎉 Decrypted message: \(decryptedText)")
                DispatchQueue.main.async {
                    self.messages.append(ChatMessage(text: decryptedText))
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
                }
            }
        }
    }
}

extension P2PConnectivityService: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, self.session)
    }
}

extension P2PConnectivityService: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 10)
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        // Delegate not needed, session state is more reliable.
    }
}

extension P2PConnectivityService: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected:
                print("Connected to: \(peerID.displayName)")
                self.serviceBrowser.stopBrowsingForPeers()
                self.connectedPeer = peerID
                self.initiateHandshake(for: peerID)
                
                // After setting up the handshake, check for and process any queued data.
                if let data = self.pendingData[peerID] {
                    print("Processing queued data for \(peerID.displayName)")
                    self.processReceivedData(data, from: peerID)
                    self.pendingData.removeValue(forKey: peerID)
                }
                
            case .connecting:
                print("Connecting to: \(peerID.displayName)")
                
            case .notConnected:
                print("Not connected to: \(peerID.displayName)")
                self.noiseServices.removeValue(forKey: peerID)
                self.pendingData.removeValue(forKey: peerID) // Clear pending data on disconnect
                if self.connectedPeer == peerID {
                    self.connectedPeer = nil
                    self.isHandshakeComplete = false
                }
                self.serviceBrowser.startBrowsingForPeers()
                
            @unknown default:
                print("Unknown state received: \(state)")
            }
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        // If the noise service isn't ready yet, queue the data.
        if noiseServices[peerID] == nil {
            print("Queuing data from \(peerID.displayName), session not fully established.")
            pendingData[peerID] = data
        } else {
            // Otherwise, process it immediately.
            processReceivedData(data, from: peerID)
        }
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}
