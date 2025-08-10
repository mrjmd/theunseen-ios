import SwiftUI
import FirebaseFirestore

struct PathLaunchView: View {
    @EnvironmentObject var p2pService: P2PConnectivityService
    @EnvironmentObject var authService: AuthService
    @State private var isSearching = false
    @State private var connectionStatus = "Ready to begin"
    @State private var showChat = false
    @State private var pulseAnimation = false
    @State private var showDeveloperMenu = false
    @State private var animaBalance: Int = 0
    @State private var hasPendingIntegration = false
    @State private var pendingIntegrationData: PendingIntegration?
    @State private var showIntegration = false
    @State private var checkTimer: Timer?
    @State private var showingIntegrationWarning = false
    
    struct PendingIntegration: Codable {
        let sessionId: String
        let artifact: String
        let timestamp: TimeInterval  // Store as TimeInterval, convert to Date when needed
        let partnerName: String?
        let peerId: String?  // Peer ID for cooldown management
        let partnerFirebaseUID: String?  // Partner's Firebase UID for session recovery
        
        var date: Date {
            return Date(timeIntervalSince1970: timestamp)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Clean, light background (Normie Mode)
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // ANIMA Balance Display
                    VStack(spacing: 8) {
                        Text("Your ANIMA")
                            .font(.system(size: 14, weight: .light))
                            .foregroundColor(.gray)
                            .tracking(1)
                        
                        HStack(alignment: .bottom, spacing: 4) {
                            Image(systemName: "sparkle")
                                .font(.system(size: 24))
                                .foregroundColor(.purple)
                            Text("\(animaBalance)")
                                .font(.system(size: 36, weight: .light, design: .rounded))
                                .foregroundColor(.primary)
                                .contentTransition(.numericText())
                                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: animaBalance)
                        }
                    }
                    .padding(.top, 40)
                    
                    Spacer()
                    
                    // Status message
                    VStack(spacing: 10) {
                        if isSearching {
                            // Searching animation
                            HStack(spacing: 4) {
                                ForEach(0..<3) { index in
                                    Circle()
                                        .frame(width: 8, height: 8)
                                        .foregroundColor(.gray)
                                        .opacity(pulseAnimation ? 0.3 : 1.0)
                                        .animation(
                                            .easeInOut(duration: 0.6)
                                            .repeatForever()
                                            .delay(Double(index) * 0.2),
                                            value: pulseAnimation
                                        )
                                }
                            }
                            .onAppear {
                                pulseAnimation = true
                            }
                        }
                        
                        Text(connectionStatus)
                            .font(.system(size: 18, weight: .light))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .animation(.easeInOut, value: connectionStatus)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 20) {
                        // The Path button
                        Button(action: beginPath) {
                            HStack {
                                if isSearching {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                        .scaleEffect(0.5)
                                        .tint(.purple)
                                }
                                Text(isSearching ? "SEEKING..." : "BEGIN THE PATH")
                                    .font(.system(size: 16, weight: .medium))
                                    .tracking(2)
                            }
                            .foregroundColor(isSearching ? .gray : .white)
                            .padding(.horizontal, 60)
                            .padding(.vertical, 20)
                            .background(
                                Capsule()
                                    .fill(isSearching ? Color.gray.opacity(0.3) : Color.black)
                            )
                            .overlay(
                                Capsule()
                                    .stroke(Color.black.opacity(0.1), lineWidth: 1)
                            )
                        }
                        .disabled(isSearching)
                        .scaleEffect(isSearching ? 0.95 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: isSearching)
                        
                        // Pending Integration button
                        if hasPendingIntegration {
                            Button(action: {
                                showIntegration = true
                            }) {
                                VStack(spacing: 8) {
                                    HStack {
                                        Image(systemName: "flame.fill")
                                            .font(.system(size: 14))
                                        Text("COMPLETE INTEGRATION")
                                            .font(.system(size: 12, weight: .medium))
                                            .tracking(1.5)
                                        Image(systemName: "flame.fill")
                                            .font(.system(size: 14))
                                    }
                                    .foregroundColor(.orange)
                                    
                                    if let data = pendingIntegrationData {
                                        Text("From: \(timeAgo(from: data.date))")
                                            .font(.system(size: 10))
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding(.horizontal, 40)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(
                                            LinearGradient(
                                                colors: [.orange, .red],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            ),
                                            lineWidth: 2
                                        )
                                )
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    
                    Spacer()
                    Spacer()
                }
                .padding()
            }
            .navigationDestination(isPresented: $showChat) {
                EnhancedChatView()
                    .onDisappear {
                        // Reload ANIMA balance when returning from chat
                        loadAnimaBalance()
                        checkPendingIntegration()
                    }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showDeveloperMenu = true
                    }) {
                        Image(systemName: DeveloperSettings.shared.isDeveloperModeEnabled ? "wrench.and.screwdriver.fill" : "gearshape")
                            .foregroundColor(DeveloperSettings.shared.isDeveloperModeEnabled ? .purple : .gray.opacity(0.5))
                    }
                }
            }
            .sheet(isPresented: $showDeveloperMenu) {
                DeveloperMenuView()
            }
            .alert("Incomplete Integration", isPresented: $showingIntegrationWarning) {
                Button("Cancel", role: .cancel) { }
                Button("Continue Anyway", role: .destructive) {
                    // Clear the pending Integration
                    UserDefaults.standard.removeObject(forKey: "pendingIntegration")
                    hasPendingIntegration = false
                    pendingIntegrationData = nil
                    
                    // Start new path
                    startSearching()
                }
            } message: {
                if let data = pendingIntegrationData {
                    let hoursRemaining = Int(24 - (Date().timeIntervalSince(data.date) / 3600))
                    Text("You have an incomplete Integration that will expire in \(max(1, hoursRemaining)) hour\(hoursRemaining == 1 ? "" : "s").\n\nStarting a new path will replace it and no ANIMA will be rewarded to either player from the previous Convergence.")
                } else {
                    Text("You have an incomplete Integration.\n\nStarting a new path will replace it and no ANIMA will be rewarded to either player from the previous Convergence.")
                }
            }
            .fullScreenCover(isPresented: $showIntegration) {
                if let data = pendingIntegrationData {
                    NavigationStack {
                        IntegrationView(
                            sessionId: data.sessionId,
                            sharedArtifact: data.artifact,
                            peerId: data.peerId,
                            partnerFirebaseUID: data.partnerFirebaseUID,
                            onComplete: {
                                // Clear pending integration
                                UserDefaults.standard.removeObject(forKey: "pendingIntegration")
                                hasPendingIntegration = false
                                pendingIntegrationData = nil
                                // Clear re-match cooldown if we have the peer ID (dev mode only)
                                if DeveloperSettings.shared.isDeveloperModeEnabled, let peerId = data.peerId {
                                    UserDefaults.standard.removeObject(forKey: "lastSession_\(peerId)")
                                    print("🔓 [DEV MODE] Cleared re-match cooldown for \(peerId)")
                                }
                                // Reload ANIMA balance
                                loadAnimaBalance()
                            }
                        )
                    }
                }
            }
        }
        .preferredColorScheme(.light) // Force light mode for Normie Mode
        .onAppear {
            loadAnimaBalance()
            checkPendingIntegration()
            
            // Reload block list in case it changed
            p2pService.loadBlockedUsers()
            
            // Start periodic check for pending Integration (less frequent)
            checkTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
                checkPendingIntegration()
            }
        }
        .onDisappear {
            checkTimer?.invalidate()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenPendingIntegration"))) { _ in
            // Open pending Integration when notification is tapped
            checkPendingIntegration()  // Reload first
            if hasPendingIntegration {
                showIntegration = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            // Reload when app becomes active (e.g., returning from background)
            checkPendingIntegration()
            loadAnimaBalance()
        }
        .onReceive(p2pService.$connectedPeer) { peer in
            if peer != nil {
                connectionStatus = "Container established.\nThe Mirror is ready."
                
                // Stop discovery once connected (save battery)
                p2pService.stopDiscovery()
                
                // Transition to chat after a brief moment
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation {
                        showChat = true
                    }
                }
            } else {
                // Peer disconnected, reset the state
                isSearching = false
                connectionStatus = "Ready to begin"
                showChat = false
                
                // Make sure discovery is stopped
                p2pService.stopDiscovery()
            }
        }
        .onReceive(p2pService.$isHandshakeComplete) { complete in
            if complete && !showChat {
                // Handshake complete, prepare for interaction
                connectionStatus = "Securing the container..."
            }
        }
    }
    
    private func beginPath() {
        HapticManager.shared.pathBegun()
        // Check if there's a pending Integration before starting a new path
        if hasPendingIntegration {
            showingIntegrationWarning = true
        } else {
            startSearching()
        }
    }
    
    private func startSearching() {
        isSearching = true
        connectionStatus = "Seeking a fellow Initiate nearby..."
        
        // Always start discovery when user clicks the button
        // This gives users control over when they want to connect
        p2pService.startDiscovery()
    }
    
    private func loadAnimaBalance() {
        // First get from UserDefaults for immediate display
        animaBalance = UserDefaults.standard.integer(forKey: "animaBalance")
        
        // Then sync with Firestore for accuracy
        if let userId = authService.user?.uid {
            let db = Firestore.firestore()
            db.collection("users").document(userId).getDocument { document, error in
                if let document = document, document.exists,
                   let firestoreAnima = document.data()?["animaPoints"] as? Int {
                    DispatchQueue.main.async {
                        self.animaBalance = firestoreAnima
                        // Update UserDefaults to stay in sync
                        UserDefaults.standard.set(firestoreAnima, forKey: "animaBalance")
                    }
                }
            }
        }
    }
    
    private func checkPendingIntegration() {
        // Check if there's a pending integration stored
        if let data = UserDefaults.standard.data(forKey: "pendingIntegration") {
            print("📱 Found pending Integration data, attempting to decode...")
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("📱 JSON decoded: \(json)")
                
                if let sessionId = json["sessionId"] as? String,
                   let artifact = json["artifact"] as? String,
                   let timestamp = json["timestamp"] as? TimeInterval {
                    
                    // Check if it's not too old (e.g., within 24 hours)
                    let date = Date(timeIntervalSince1970: timestamp)
                    let hoursSince = Date().timeIntervalSince(date) / 3600
                    
                    if hoursSince < 24 {
                        let partnerName = json["partnerName"] as? String
                        let peerId = json["peerId"] as? String
                        let partnerFirebaseUID = json["partnerFirebaseUID"] as? String
                        pendingIntegrationData = PendingIntegration(
                            sessionId: sessionId,
                            artifact: artifact,
                            timestamp: timestamp,
                            partnerName: partnerName,
                            peerId: peerId,
                            partnerFirebaseUID: partnerFirebaseUID
                        )
                        hasPendingIntegration = true
                        print("📱 ✅ Loaded pending Integration: \(sessionId), artifact: \(artifact)")
                    } else {
                        // Clear old pending integration
                        UserDefaults.standard.removeObject(forKey: "pendingIntegration")
                        print("🗑️ Cleared old pending Integration (>24h)")
                    }
                } else {
                    print("📱 ❌ Failed to extract required fields from JSON")
                }
            } else {
                print("📱 ❌ Failed to decode JSON from data")
            }
        } else {
            print("📱 No pending Integration data in UserDefaults")
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 60 {
            return "just now"
        } else if seconds < 3600 {
            let minutes = seconds / 60
            return "\(minutes) min\(minutes == 1 ? "" : "s") ago"
        } else if seconds < 86400 {
            let hours = seconds / 3600
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        } else {
            let days = seconds / 86400
            return "\(days) day\(days == 1 ? "" : "s") ago"
        }
    }
}

#Preview {
    PathLaunchView()
        .environmentObject(P2PConnectivityService())
}