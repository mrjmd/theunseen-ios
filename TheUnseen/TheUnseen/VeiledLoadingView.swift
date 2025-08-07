import SwiftUI

struct VeiledLoadingView: View {
    @State private var symbolOpacity: Double = 0.3
    @State private var glitchOffset: CGFloat = 0
    @State private var glitchOffset2: CGFloat = 0
    @State private var chromaOffset: CGFloat = 0
    @State private var textOpacity: Double = 0
    @State private var currentText = "Waking the Mirror..."
    @State private var showSecondText = false
    @State private var scanlineOffset: CGFloat = -200
    @State private var noiseOpacity: Double = 0.1
    
    // Set this to true once you've added your logo to Assets.xcassets
    let useCustomLogo = false
    let logoImageName = "Logo" // Replace with your actual asset name
    
    var body: some View {
        ZStack {
            // Pure black background
            Color.black
                .ignoresSafeArea()
            
            // Digital noise overlay
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.purple.opacity(noiseOpacity),
                            Color.clear,
                            Color.cyan.opacity(noiseOpacity),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .ignoresSafeArea()
                .blendMode(.screen)
                .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: noiseOpacity)
                .onAppear {
                    noiseOpacity = 0.3
                }
            
            // Scanline effect
            Rectangle()
                .fill(Color.white.opacity(0.02))
                .frame(height: 100)
                .offset(y: scanlineOffset)
                .blur(radius: 20)
                .onAppear {
                    withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) {
                        scanlineOffset = UIScreen.main.bounds.height + 200
                    }
                }
            
            VStack(spacing: 60) {
                Spacer()
                
                // Alchemical Symbol with enhanced glitch effect
                ZStack {
                    if useCustomLogo {
                        // Use your custom logo when available
                        logoWithGlitchEffect
                    } else {
                        // Fallback to generated symbol
                        generatedSymbolWithGlitch
                    }
                }
                .onAppear {
                    startGlitchAnimations()
                }
                
                // Koan text
                Text(currentText)
                    .font(.system(size: 16, weight: .thin, design: .monospaced))
                    .foregroundColor(.white.opacity(textOpacity))
                    .tracking(2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .onAppear {
                        // Fade in first text
                        withAnimation(.easeIn(duration: 1).delay(0.5)) {
                            textOpacity = 0.8
                        }
                        
                        // Switch to second text
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation(.easeOut(duration: 0.5)) {
                                textOpacity = 0
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                currentText = "We're already whole.\nFor those with the eyes to see."
                                withAnimation(.easeIn(duration: 1)) {
                                    textOpacity = 0.8
                                }
                            }
                        }
                    }
                
                Spacer()
                Spacer()
            }
        }
    }
    
    // Logo with glitch effect (for when you add your custom logo)
    var logoWithGlitchEffect: some View {
        ZStack {
            // Background ghost layer
            Image(logoImageName)
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
                .foregroundColor(.white.opacity(0.05))
                .scaleEffect(1.1)
                .blur(radius: 5)
            
            // Multiple glitch layers
            ForEach(0..<5) { index in
                Image(logoImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .foregroundColor(glitchColor(for: index))
                    .offset(x: glitchOffset * CGFloat(index % 2 == 0 ? 1 : -1),
                           y: glitchOffset2 * CGFloat(index % 3 == 0 ? 1 : -0.5))
                    .opacity(0.3)
                    .blendMode(.screen)
            }
            
            // Main logo
            Image(logoImageName)
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
                .foregroundColor(.white.opacity(symbolOpacity))
        }
    }
    
    // Generated symbol with enhanced glitch
    var generatedSymbolWithGlitch: some View {
        ZStack {
            // Background distortion layers
            ForEach(0..<8) { index in
                AlchemicalSymbol()
                    .foregroundColor(glitchColor(for: index))
                    .frame(width: 150, height: 150)
                    .offset(
                        x: sin(Double(index)) * Double(glitchOffset) * Double(index) * 0.3,
                        y: cos(Double(index)) * Double(glitchOffset2) * Double(index) * 0.3
                    )
                    .opacity(0.1)
                    .blur(radius: CGFloat(index) * 0.5)
                    .scaleEffect(1 + CGFloat(index) * 0.02)
            }
            
            // Chromatic aberration layers
            AlchemicalSymbol()
                .foregroundColor(.red.opacity(0.3))
                .frame(width: 150, height: 150)
                .offset(x: -chromaOffset, y: 0)
                .blendMode(.screen)
            
            AlchemicalSymbol()
                .foregroundColor(.green.opacity(0.3))
                .frame(width: 150, height: 150)
                .offset(x: 0, y: chromaOffset * 0.5)
                .blendMode(.screen)
            
            AlchemicalSymbol()
                .foregroundColor(.blue.opacity(0.3))
                .frame(width: 150, height: 150)
                .offset(x: chromaOffset, y: -chromaOffset * 0.5)
                .blendMode(.screen)
            
            // Main symbol
            AlchemicalSymbol()
                .foregroundColor(.white.opacity(symbolOpacity))
                .frame(width: 150, height: 150)
        }
    }
    
    func glitchColor(for index: Int) -> Color {
        switch index % 4 {
        case 0: return .cyan
        case 1: return Color(red: 1, green: 0, blue: 1) // Magenta
        case 2: return .green
        case 3: return .yellow
        default: return .white
        }
    }
    
    func startGlitchAnimations() {
        // Main pulse
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            symbolOpacity = 0.9
        }
        
        // Fast glitch
        withAnimation(.linear(duration: 0.15).repeatForever()) {
            glitchOffset = 3
        }
        
        // Slower secondary glitch
        withAnimation(.easeInOut(duration: 0.3).repeatForever()) {
            glitchOffset2 = 2
        }
        
        // Chromatic aberration
        withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
            chromaOffset = 2
        }
    }
}

// Custom alchemical symbol shape
struct AlchemicalSymbol: View {
    var body: some View {
        ZStack {
            // Outer circle
            Circle()
                .stroke(lineWidth: 1)
            
            // Inner triangle
            Triangle()
                .stroke(lineWidth: 1)
                .frame(width: 60, height: 60)
                .rotationEffect(.degrees(180))
            
            // Center dot
            Circle()
                .frame(width: 8, height: 8)
            
            // Horizontal line
            Rectangle()
                .frame(width: 100, height: 0.5)
            
            // Vertical line
            Rectangle()
                .frame(width: 0.5, height: 100)
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    VeiledLoadingView()
}