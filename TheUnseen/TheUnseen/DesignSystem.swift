import SwiftUI

// MARK: - Design System
// Centralized design constants for The Unseen

struct DesignSystem {
    
    // MARK: - Colors
    struct Colors {
        // Primary Palette - Monochrome base
        static let primary = Color.black
        static let secondary = Color.white
        static let backgroundPrimary = Color.white
        static let backgroundSecondary = Color.gray.opacity(0.05)
        
        // Accent Colors - Deep twilight tones
        static let accentPrimary = Color(red: 0.2, green: 0.1, blue: 0.3) // Deep purple
        static let accentSecondary = Color(red: 0.1, green: 0.2, blue: 0.4) // Midnight blue
        static let accentTertiary = Color(red: 0.3, green: 0.2, blue: 0.4) // Mystic violet
        
        // Semantic Colors
        static let success = Color(red: 0.2, green: 0.5, blue: 0.3) // Forest green
        static let warning = Color(red: 0.7, green: 0.5, blue: 0.2) // Amber
        static let danger = Color(red: 0.6, green: 0.2, blue: 0.2) // Deep red
        
        // ANIMA Colors - For celebration
        static let animaGold = Color(red: 0.9, green: 0.7, blue: 0.3)
        static let animaSilver = Color(red: 0.7, green: 0.7, blue: 0.8)
        static let animaBronze = Color(red: 0.6, green: 0.4, blue: 0.3)
        
        // Text Colors
        static let textPrimary = Color.black
        static let textSecondary = Color.gray
        static let textTertiary = Color.gray.opacity(0.6)
        static let textOnDark = Color.white
        
        // Gradient Definitions
        static let twilightGradient = LinearGradient(
            colors: [accentPrimary, accentSecondary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let sacredGradient = LinearGradient(
            colors: [accentPrimary.opacity(0.3), accentTertiary.opacity(0.3)],
            startPoint: .top,
            endPoint: .bottom
        )
        
        static let animaGradient = LinearGradient(
            colors: [animaGold, animaSilver],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Typography
    struct Typography {
        // Font Sizes
        static let titleLarge: CGFloat = 32
        static let titleMedium: CGFloat = 24
        static let titleSmall: CGFloat = 20
        
        static let bodyLarge: CGFloat = 18
        static let bodyMedium: CGFloat = 16
        static let bodySmall: CGFloat = 14
        
        static let captionLarge: CGFloat = 12
        static let captionSmall: CGFloat = 10
        
        // Font Weights
        static let weightBold = Font.Weight.bold
        static let weightSemibold = Font.Weight.semibold
        static let weightMedium = Font.Weight.medium
        static let weightRegular = Font.Weight.regular
        static let weightLight = Font.Weight.light
        
        // Letter Spacing
        static let trackingTight: CGFloat = -0.5
        static let trackingNormal: CGFloat = 0
        static let trackingWide: CGFloat = 1
        static let trackingWider: CGFloat = 2
        
        // Pre-configured Text Styles
        static func title(_ size: CGFloat = titleMedium) -> Font {
            Font.system(size: size, weight: .semibold, design: .default)
        }
        
        static func body(_ size: CGFloat = bodyMedium) -> Font {
            Font.system(size: size, weight: .regular, design: .default)
        }
        
        static func caption(_ size: CGFloat = captionLarge) -> Font {
            Font.system(size: size, weight: .light, design: .default)
        }
        
        static func sacred(_ size: CGFloat = bodyLarge) -> Font {
            Font.system(size: size, weight: .medium, design: .serif)
        }
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xxSmall: CGFloat = 4
        static let xSmall: CGFloat = 8
        static let small: CGFloat = 12
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let xLarge: CGFloat = 32
        static let xxLarge: CGFloat = 48
        static let xxxLarge: CGFloat = 64
    }
    
    // MARK: - Animation
    struct Animation {
        static let durationQuick: Double = 0.2
        static let durationNormal: Double = 0.3
        static let durationSlow: Double = 0.5
        static let durationVerySlow: Double = 1.0
        
        static let springResponse: Double = 0.5
        static let springDamping: Double = 0.7
        
        static let defaultSpring = SwiftUI.Animation.spring(
            response: springResponse,
            dampingFraction: springDamping,
            blendDuration: 0
        )
        
        static let easeInOut = SwiftUI.Animation.easeInOut(duration: durationNormal)
        static let easeIn = SwiftUI.Animation.easeIn(duration: durationNormal)
        static let easeOut = SwiftUI.Animation.easeOut(duration: durationNormal)
    }
    
    // MARK: - Shadows
    struct Shadow {
        static let subtle = (color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        static let medium = (color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
        static let strong = (color: Color.black.opacity(0.2), radius: 16, x: 0, y: 8)
        static let glow = (color: Colors.animaGold.opacity(0.3), radius: 20, x: 0, y: 0)
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xLarge: CGFloat = 24
        static let pill: CGFloat = 100
    }
}

// MARK: - View Extensions for Easy Application
extension View {
    func applyPrimaryButtonStyle() -> some View {
        self
            .font(DesignSystem.Typography.body(DesignSystem.Typography.bodyMedium))
            .foregroundColor(DesignSystem.Colors.textOnDark)
            .padding(.horizontal, DesignSystem.Spacing.large)
            .padding(.vertical, DesignSystem.Spacing.medium)
            .background(DesignSystem.Colors.primary)
            .cornerRadius(DesignSystem.CornerRadius.pill)
    }
    
    func applySecondaryButtonStyle() -> some View {
        self
            .font(DesignSystem.Typography.body(DesignSystem.Typography.bodyMedium))
            .foregroundColor(DesignSystem.Colors.textPrimary)
            .padding(.horizontal, DesignSystem.Spacing.large)
            .padding(.vertical, DesignSystem.Spacing.medium)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.pill)
                    .stroke(DesignSystem.Colors.primary, lineWidth: 1)
            )
    }
    
    func applyCardStyle() -> some View {
        self
            .padding(DesignSystem.Spacing.medium)
            .background(DesignSystem.Colors.backgroundSecondary)
            .cornerRadius(DesignSystem.CornerRadius.medium)
            .shadow(
                color: DesignSystem.Shadow.subtle.color,
                radius: CGFloat(DesignSystem.Shadow.subtle.radius),
                x: CGFloat(DesignSystem.Shadow.subtle.x),
                y: CGFloat(DesignSystem.Shadow.subtle.y)
            )
    }
    
    func applySacredGlow() -> some View {
        self
            .shadow(
                color: DesignSystem.Shadow.glow.color,
                radius: CGFloat(DesignSystem.Shadow.glow.radius),
                x: CGFloat(DesignSystem.Shadow.glow.x),
                y: CGFloat(DesignSystem.Shadow.glow.y)
            )
    }
}

// MARK: - Loading Animation View
struct LoadingAnimation: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Outer circle
            Circle()
                .stroke(DesignSystem.Colors.accentPrimary.opacity(0.3), lineWidth: 2)
                .frame(width: 40, height: 40)
            
            // Animated arc
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(
                    DesignSystem.Colors.twilightGradient,
                    style: StrokeStyle(lineWidth: 2, lineCap: .round)
                )
                .frame(width: 40, height: 40)
                .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                .animation(
                    Animation.linear(duration: 1.5).repeatForever(autoreverses: false),
                    value: isAnimating
                )
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - ANIMA Celebration View
struct ANIMACelebrationView: View {
    let amount: Int
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var particleOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Glowing background
            Circle()
                .fill(DesignSystem.Colors.animaGradient)
                .frame(width: 200, height: 200)
                .blur(radius: 40)
                .opacity(opacity * 0.5)
            
            // ANIMA text
            VStack(spacing: DesignSystem.Spacing.small) {
                Text("+\(amount)")
                    .font(DesignSystem.Typography.title(DesignSystem.Typography.titleLarge))
                    .fontWeight(.bold)
                    .foregroundStyle(DesignSystem.Colors.animaGradient)
                
                Text("ANIMA")
                    .font(DesignSystem.Typography.sacred(DesignSystem.Typography.bodyLarge))
                    .tracking(DesignSystem.Typography.trackingWider)
                    .foregroundColor(DesignSystem.Colors.animaGold)
            }
            .scaleEffect(scale)
            .opacity(opacity)
            
            // Particle effects
            ForEach(0..<8, id: \.self) { index in
                Circle()
                    .fill(DesignSystem.Colors.animaGold)
                    .frame(width: 4, height: 4)
                    .offset(y: -particleOffset)
                    .rotationEffect(.degrees(Double(index) * 45))
                    .opacity(opacity)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                scale = 1.0
                opacity = 1.0
            }
            
            withAnimation(.easeOut(duration: 1.5)) {
                particleOffset = 100
            }
            
            withAnimation(.easeOut(duration: 0.5).delay(1.5)) {
                opacity = 0
            }
        }
    }
}