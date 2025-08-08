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
    
    struct PendingIntegration: Codable {
        let sessionId: String
        let artifact: String
        let timestamp: TimeInterval  // Store as TimeInterval, convert to Date when needed
        let partnerName: String?
        
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
                            Text("BEGIN THE PATH")
                                .font(.system(size: 16, weight: .medium))
                                .tracking(2)
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
                        .disabled(isSearching || hasPendingIntegration)
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
            .fullScreenCover(isPresented: $showIntegration) {
                if let data = pendingIntegrationData {
                    NavigationStack {
                        IntegrationView(
                            sessionId: data.sessionId,
                            sharedArtifact: data.artifact,
                            onComplete: {
                                // Clear pending integration
                                UserDefaults.standard.removeObject(forKey: "pendingIntegration")
                                hasPendingIntegration = false
                                pendingIntegrationData = nil
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
        }
        .onReceive(p2pService.$connectedPeer) { peer in
            if peer != nil {
                connectionStatus = "Container established.\nThe Mirror is ready."
                
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
        isSearching = true
        connectionStatus = "Seeking a fellow Initiate nearby..."
        
        // In production mode, start discovery when user clicks the button
        // In dev mode, discovery is already running
        if !DeveloperSettings.shared.isDeveloperModeEnabled {
            p2pService.startDiscovery()
        }
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
        if let data = UserDefaults.standard.data(forKey: "pendingIntegration"),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let sessionId = json["sessionId"] as? String,
           let artifact = json["artifact"] as? String,
           let timestamp = json["timestamp"] as? TimeInterval {
            
            // Check if it's not too old (e.g., within 24 hours)
            let date = Date(timeIntervalSince1970: timestamp)
            let hoursSince = Date().timeIntervalSince(date) / 3600
            
            if hoursSince < 24 {
                let partnerName = json["partnerName"] as? String
                pendingIntegrationData = PendingIntegration(
                    sessionId: sessionId,
                    artifact: artifact,
                    timestamp: timestamp,
                    partnerName: partnerName
                )
                hasPendingIntegration = true
                print("📱 Found pending Integration: \(sessionId)")
            } else {
                // Clear old pending integration
                UserDefaults.standard.removeObject(forKey: "pendingIntegration")
                print("🗑️ Cleared old pending Integration (>24h)")
            }
        } else {
            print("📱 No pending Integration found")
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