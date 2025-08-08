import SwiftUI

struct IntegrationView: View {
    @EnvironmentObject var p2pService: P2PConnectivityService
    @Environment(\.dismiss) var dismiss
    
    let sessionId: String
    
    // The three sliders
    @State private var presenceScore: Double = 50
    @State private var courageScore: Double = 50
    @State private var mirrorScore: Double = 50
    
    // The private reflection
    @State private var reflection: String = ""
    @State private var selectedPrompt = 0
    
    // UI states
    @State private var hasSubmitted = false
    @State private var showingCompletion = false
    @State private var finalANIMA = 0
    @State private var peerSubmitted = false
    @State private var checkingMultiplier = false
    
    let reflectionPrompts = [
        "What did that interaction reveal in YOU?",
        "What part of you were you most afraid to show? What happened when you did?",
        "Describe a moment in the interaction where you felt most alive."
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "flame")
                            .font(.system(size: 40))
                            .foregroundColor(.purple)
                            .symbolEffect(.pulse)
                        
                        Text("The Integration")
                            .font(.title2)
                            .fontWeight(.light)
                            .tracking(2)
                        
                        Text("Alchemize your experience into wisdom")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 30)
                    
                    if !hasSubmitted {
                        // Part 1: The Private Journal
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Your Offering")
                                .font(.caption)
                                .foregroundColor(.purple)
                                .tracking(1)
                            
                            // Prompt selector
                            Picker("Prompt", selection: $selectedPrompt) {
                                ForEach(0..<reflectionPrompts.count, id: \.self) { index in
                                    Text(reflectionPrompts[index])
                                        .tag(index)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(.purple)
                            
                            // Reflection text area
                            VStack(alignment: .leading, spacing: 8) {
                                Text(reflectionPrompts[selectedPrompt])
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                                    .italic()
                                
                                TextEditor(text: $reflection)
                                    .frame(minHeight: 100)
                                    .padding(8)
                                    .background(Color(UIColor.secondarySystemBackground))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                                    )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                        
                        // Part 2: The Resonance Scores
                        VStack(spacing: 30) {
                            // Presence Slider
                            SliderSection(
                                title: "Presence",
                                subtitle: "How present were you in the container?",
                                value: $presenceScore,
                                symbolName: "flame",
                                color: .orange
                            )
                            
                            // Courage Slider
                            SliderSection(
                                title: "Courage",
                                subtitle: "How much courage did you bring to the interaction?",
                                value: $courageScore,
                                symbolName: "lion",
                                color: .red
                            )
                            
                            // The Mirror Slider
                            SliderSection(
                                title: "The Mirror",
                                subtitle: "How clearly did you see yourself in them?",
                                value: $mirrorScore,
                                symbolName: "circle.hexagongrid.circle",
                                color: .purple
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                        
                        // Submit Button
                        Button(action: submitIntegration) {
                            HStack {
                                Image(systemName: "seal.fill")
                                Text("Seal the Offering")
                                Image(systemName: "sparkles")
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [.purple, .indigo],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(25)
                            .shadow(color: .purple.opacity(0.3), radius: 10, y: 5)
                        }
                        .disabled(reflection.isEmpty)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                        
                    } else {
                        // Completion State
                        CompletionView(
                            finalANIMA: finalANIMA,
                            peerSubmitted: peerSubmitted,
                            onComplete: {
                                dismiss()
                            }
                        )
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.dark) // Integration uses dark mode for deeper feeling
        }
        .onReceive(p2pService.$messages) { messages in
            // Listen for peer's resonance scores
            if let lastMessage = messages.last {
                if lastMessage.text.contains("RESONANCE_SCORES:") && !peerSubmitted {
                    DispatchQueue.main.async {
                        self.peerSubmitted = true
                        
                        // If we've also submitted, check for final multiplier
                        if self.hasSubmitted && !self.checkingMultiplier {
                            self.checkingMultiplier = true
                            self.checkForFinalMultiplier()
                        }
                    }
                }
            }
        }
    }
    
    private func submitIntegration() {
        // Calculate ANIMA
        let baseANIMA = 50
        let courageBonus = Int(courageScore)
        
        // Send scores to peer for multiplier calculation
        let scoreData = "RESONANCE_SCORES:presence=\(Int(presenceScore)),courage=\(Int(courageScore)),mirror=\(Int(mirrorScore))"
        p2pService.sendSystemMessage(scoreData)
        
        // Store reflection in Firestore (not E2E encrypted for moderation)
        let firestoreService = FirestoreService()
        
        // Save reflection data
        firestoreService.saveReflection(
            sessionId: sessionId,
            reflection: reflection,
            promptIndex: selectedPrompt,
            presenceScore: Int(presenceScore),
            courageScore: Int(courageScore),
            mirrorScore: Int(mirrorScore)
        )
        
        // Calculate preliminary ANIMA (final will be calculated when both submit)
        finalANIMA = baseANIMA + courageBonus
        
        withAnimation(.easeInOut) {
            hasSubmitted = true
        }
        
        // Play haptic feedback
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        
        // Check if peer has also submitted
        if peerSubmitted && !checkingMultiplier {
            checkingMultiplier = true
            checkForFinalMultiplier()
        }
    }
    
    private func checkForFinalMultiplier() {
        // After both users submit, calculate final multiplier
        let firestoreService = FirestoreService()
        
        // Wait a moment for Firestore to sync
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            firestoreService.calculateResonanceMultiplier(sessionId: sessionId) { calculatedANIMA in
                if calculatedANIMA > 0 {
                    DispatchQueue.main.async {
                        self.finalANIMA = calculatedANIMA
                        print("✨ Final ANIMA calculated with multiplier: \(calculatedANIMA)")
                    }
                }
            }
        }
    }
}

// MARK: - Slider Section Component
struct SliderSection: View {
    let title: String
    let subtitle: String
    @Binding var value: Double
    let symbolName: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: symbolName)
                    .foregroundColor(color)
                    .font(.system(size: 20))
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(Int(value))")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(color)
            }
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.gray)
            
            // Custom styled slider
            ZStack(alignment: .leading) {
                // Track
                Capsule()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 8)
                
                // Fill
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.6), color],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: CGFloat(value) / 100.0 * (UIScreen.main.bounds.width - 40), height: 8)
                    .animation(.interactiveSpring(), value: value)
            }
            .overlay(
                // Invisible slider for interaction
                Slider(value: $value, in: 0...100)
                    .opacity(0.01)
            )
        }
    }
}

// MARK: - Completion View
struct CompletionView: View {
    let finalANIMA: Int
    let peerSubmitted: Bool
    let onComplete: () -> Void
    @State private var showingANIMA = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Success animation
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.purple.opacity(0.3), .clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .scaleEffect(showingANIMA ? 1 : 0)
                    .animation(.easeOut(duration: 1), value: showingANIMA)
                
                VStack(spacing: 12) {
                    Image(systemName: "seal.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.purple)
                        .scaleEffect(showingANIMA ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.3), value: showingANIMA)
                    
                    if showingANIMA {
                        Text("+\(finalANIMA) ANIMA")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.purple)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            
            VStack(spacing: 12) {
                Text("Offering Sealed")
                    .font(.title2)
                    .fontWeight(.light)
                
                Text("Your wisdom has been alchemized")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                if peerSubmitted {
                    Text("✅ Both souls have completed the integration")
                        .font(.caption2)
                        .foregroundColor(.green)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                } else {
                    Text("⏳ Waiting for your partner to complete their integration...")
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            
            Spacer()
            
            Button(action: onComplete) {
                Text("Return to the Path")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple.opacity(0.8))
                    .cornerRadius(12)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    showingANIMA = true
                }
            }
        }
    }
}

#Preview {
    IntegrationView(sessionId: "preview-session-123")
        .environmentObject(P2PConnectivityService())
}