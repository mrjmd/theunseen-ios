import SwiftUI

struct PathLaunchView: View {
    @EnvironmentObject var p2pService: P2PConnectivityService
    @State private var isSearching = false
    @State private var connectionStatus = "Ready to begin"
    @State private var showChat = false
    @State private var pulseAnimation = false
    @State private var showDeveloperMenu = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Clean, light background (Normie Mode)
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 50) {
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
                    .disabled(isSearching)
                    .scaleEffect(isSearching ? 0.95 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isSearching)
                    
                    Spacer()
                    Spacer()
                }
                .padding()
            }
            .navigationDestination(isPresented: $showChat) {
                EnhancedChatView()
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
        }
        .preferredColorScheme(.light) // Force light mode for Normie Mode
        .onReceive(p2pService.$connectedPeer) { peer in
            if peer != nil {
                connectionStatus = "Container established.\nThe Mirror is ready."
                
                // Transition to chat after a brief moment
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation {
                        showChat = true
                    }
                }
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
        
        // P2P service is already running from app launch
        // This just updates the UI state
    }
}

#Preview {
    PathLaunchView()
        .environmentObject(P2PConnectivityService())
}