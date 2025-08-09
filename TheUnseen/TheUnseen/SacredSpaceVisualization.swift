import SwiftUI

struct SacredSpaceVisualization: View {
    @State private var rotationAngle: Double = 0
    @State private var innerRotation: Double = 0
    @State private var outerRotation: Double = 0
    @State private var breathScale: CGFloat = 0.9
    @State private var glowIntensity: Double = 0.3
    
    let isActive: Bool
    
    var body: some View {
        ZStack {
            // Outer glow effect
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            DesignSystem.Colors.accentTertiary.opacity(glowIntensity),
                            DesignSystem.Colors.accentPrimary.opacity(glowIntensity * 0.5),
                            .clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 150
                    )
                )
                .frame(width: 300, height: 300)
                .blur(radius: 20)
                .scaleEffect(breathScale)
            
            // Sacred geometry - outer rings
            ForEach(0..<3) { index in
                SacredRing(
                    radius: 50 + CGFloat(index * 30),
                    rotation: outerRotation + Double(index * 120),
                    strokeWidth: 1.5 - CGFloat(index) * 0.3,
                    opacity: isActive ? 0.6 - Double(index) * 0.15 : 0.2
                )
            }
            
            // Sacred geometry - inner pattern
            ZStack {
                // Triangular formation
                ForEach(0..<6) { index in
                    SacredTriangle()
                        .stroke(
                            DesignSystem.Colors.accentSecondary.opacity(0.4),
                            lineWidth: 1
                        )
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(innerRotation + Double(index) * 60))
                }
                
                // Central hexagon
                Hexagon()
                    .stroke(
                        LinearGradient(
                            colors: [
                                DesignSystem.Colors.accentPrimary,
                                DesignSystem.Colors.accentTertiary
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(rotationAngle))
                
                // Center point
                Circle()
                    .fill(DesignSystem.Colors.animaGold)
                    .frame(width: 8, height: 8)
                    .scaleEffect(breathScale)
                    .applySacredGlow()
            }
        }
        .onAppear {
            if isActive {
                startAnimations()
            }
        }
        .onChange(of: isActive) { newValue in
            if newValue {
                startAnimations()
            }
        }
    }
    
    private func startAnimations() {
        // Main rotation
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
        
        // Inner rotation (counter-clockwise)
        withAnimation(.linear(duration: 15).repeatForever(autoreverses: false)) {
            innerRotation = -360
        }
        
        // Outer rotation
        withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
            outerRotation = 360
        }
        
        // Breathing effect
        withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
            breathScale = 1.1
        }
        
        // Glow pulsing
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
            glowIntensity = 0.6
        }
    }
}

// MARK: - Sacred Geometry Shapes

struct SacredRing: View {
    let radius: CGFloat
    let rotation: Double
    let strokeWidth: CGFloat
    let opacity: Double
    
    var body: some View {
        Circle()
            .stroke(
                DesignSystem.Colors.twilightGradient,
                style: StrokeStyle(
                    lineWidth: strokeWidth,
                    dash: [5, 10],
                    dashPhase: 0
                )
            )
            .frame(width: radius * 2, height: radius * 2)
            .rotationEffect(.degrees(rotation))
            .opacity(opacity)
    }
}

struct SacredTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        path.move(to: CGPoint(x: width / 2, y: 0))
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        
        return path
    }
}

struct Hexagon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        for i in 0..<6 {
            let angle = CGFloat(i) * .pi / 3 - .pi / 2
            let point = CGPoint(
                x: center.x + radius * cos(angle),
                y: center.y + radius * sin(angle)
            )
            
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        
        path.closeSubpath()
        return path
    }
}

// MARK: - Sacred Space Container View
struct SacredSpaceContainer: View {
    let timeRemaining: Double
    let totalDuration: Double
    @State private var isActive = true
    
    var progress: Double {
        timeRemaining / totalDuration
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.95)
                .ignoresSafeArea()
            
            VStack(spacing: DesignSystem.Spacing.xLarge) {
                // Title
                Text("Sacred Space")
                    .font(DesignSystem.Typography.sacred(24))
                    .tracking(DesignSystem.Typography.trackingWider)
                    .foregroundColor(.white)
                    .opacity(0.9)
                
                // Visualization
                SacredSpaceVisualization(isActive: isActive)
                    .frame(height: 300)
                
                // Timer progress
                VStack(spacing: DesignSystem.Spacing.small) {
                    Text("Creating artifact together")
                        .font(DesignSystem.Typography.caption())
                        .foregroundColor(.white.opacity(0.7))
                    
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 4)
                            
                            Capsule()
                                .fill(DesignSystem.Colors.twilightGradient)
                                .frame(width: geometry.size.width * progress, height: 4)
                                .animation(.linear(duration: 0.5), value: progress)
                        }
                    }
                    .frame(height: 4)
                    .padding(.horizontal, DesignSystem.Spacing.xLarge)
                    
                    Text("\(Int(timeRemaining))s")
                        .font(DesignSystem.Typography.body())
                        .monospacedDigit()
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .padding(DesignSystem.Spacing.large)
        }
    }
}

// MARK: - Preview
struct SacredSpaceVisualization_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SacredSpaceVisualization(isActive: true)
                .preferredColorScheme(.dark)
            
            SacredSpaceContainer(timeRemaining: 45, totalDuration: 60)
        }
    }
}