import SwiftUI

// MARK: - Custom Transition Effects
// Meaningful transitions that guide the user through their journey

// MARK: - Veil Transition (Revealing/Concealing)
struct VeilTransition: ViewModifier {
    let isShowing: Bool
    
    func body(content: Content) -> some View {
        content
            .opacity(isShowing ? 1 : 0)
            .scaleEffect(isShowing ? 1 : 0.95)
            .blur(radius: isShowing ? 0 : 10)
            .animation(.easeInOut(duration: 0.6), value: isShowing)
    }
}

// MARK: - Sacred Portal Transition
extension AnyTransition {
    static var sacredPortal: AnyTransition {
        AnyTransition.asymmetric(
            insertion: .scale(scale: 0.8)
                .combined(with: .opacity)
                .combined(with: .move(edge: .bottom)),
            removal: .scale(scale: 1.1)
                .combined(with: .opacity)
        )
        .animation(.spring(response: 0.6, dampingFraction: 0.8))
    }
    
    static var dissolve: AnyTransition {
        AnyTransition.asymmetric(
            insertion: .opacity.animation(.easeIn(duration: 0.5)),
            removal: .opacity.animation(.easeOut(duration: 0.3))
        )
    }
    
    static var ascend: AnyTransition {
        AnyTransition.asymmetric(
            insertion: .move(edge: .bottom)
                .combined(with: .opacity),
            removal: .move(edge: .top)
                .combined(with: .opacity)
        )
    }
    
    static var ethereal: AnyTransition {
        AnyTransition.modifier(
            active: EtherealModifier(progress: 0),
            identity: EtherealModifier(progress: 1)
        )
    }
}

// MARK: - Ethereal Modifier (Mystical fade)
struct EtherealModifier: ViewModifier {
    let progress: Double
    
    func body(content: Content) -> some View {
        content
            .opacity(progress)
            .scaleEffect(0.8 + (0.2 * progress))
            .rotationEffect(.degrees((1 - progress) * 5))
            .blur(radius: (1 - progress) * 3)
    }
}

// MARK: - Navigation Transition View
struct NavigationTransition<Content: View>: View {
    @Binding var isPresented: Bool
    let content: () -> Content
    let transition: AnyTransition
    
    init(
        isPresented: Binding<Bool>,
        transition: AnyTransition = .sacredPortal,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self._isPresented = isPresented
        self.transition = transition
        self.content = content
    }
    
    var body: some View {
        ZStack {
            if isPresented {
                content()
                    .transition(transition)
            }
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isPresented)
    }
}

// MARK: - Path Transition Overlay
struct PathTransitionOverlay: View {
    @State private var showRipple = false
    let onComplete: () -> Void
    
    var body: some View {
        ZStack {
            // Background fade
            Color.black
                .opacity(showRipple ? 0.7 : 0)
                .ignoresSafeArea()
            
            // Ripple effect
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            DesignSystem.Colors.accentPrimary.opacity(0.3),
                            DesignSystem.Colors.accentPrimary.opacity(0.1),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
                .scaleEffect(showRipple ? 3 : 0)
                .opacity(showRipple ? 0 : 1)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                showRipple = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                onComplete()
            }
        }
    }
}

// MARK: - Screen Transition Manager
class ScreenTransitionManager: ObservableObject {
    @Published var currentScreen: ScreenType = .path
    @Published var isTransitioning = false
    
    enum ScreenType {
        case path
        case chat
        case convergence
        case integration
    }
    
    func transition(to screen: ScreenType, completion: (() -> Void)? = nil) {
        guard !isTransitioning else { return }
        
        isTransitioning = true
        
        // Play transition sound
        SoundManager.shared.play(.transitionWhoosh, volume: 0.3)
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            currentScreen = screen
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.isTransitioning = false
            completion?()
        }
    }
}

// MARK: - Custom Navigation Container
struct SacredNavigationView<Content: View>: View {
    @StateObject private var transitionManager = ScreenTransitionManager()
    let content: () -> Content
    
    var body: some View {
        ZStack {
            content()
                .environmentObject(transitionManager)
            
            // Transition overlay
            if transitionManager.isTransitioning {
                PathTransitionOverlay {
                    // Transition complete
                }
                .transition(.opacity)
            }
        }
    }
}

// MARK: - View Extensions for Easy Transitions
extension View {
    func veilTransition(isShowing: Bool) -> some View {
        self.modifier(VeilTransition(isShowing: isShowing))
    }
    
    func withSacredTransition() -> some View {
        self
            .transition(.sacredPortal)
            .zIndex(1)
    }
    
    func withEtherealTransition() -> some View {
        self
            .transition(.ethereal)
            .zIndex(1)
    }
    
    func withAscendTransition() -> some View {
        self
            .transition(.ascend)
            .zIndex(1)
    }
}

// MARK: - Animated Navigation Link
struct AnimatedNavigationLink<Label: View, Destination: View>: View {
    let destination: () -> Destination
    let label: () -> Label
    @State private var isActive = false
    @State private var showTransition = false
    
    var body: some View {
        Button(action: {
            // Start transition
            withAnimation(.easeOut(duration: 0.3)) {
                showTransition = true
            }
            
            // Navigate after transition starts
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isActive = true
                showTransition = false
            }
        }) {
            label()
        }
        .background(
            NavigationLink(
                destination: destination(),
                isActive: $isActive,
                label: { EmptyView() }
            )
            .opacity(0)
        )
        .overlay(
            Group {
                if showTransition {
                    Color.white
                        .opacity(0.3)
                        .ignoresSafeArea()
                        .transition(.opacity)
                }
            }
        )
    }
}

// MARK: - Connection Animation View
struct ConnectionAnimationView: View {
    @State private var pulseScale: CGFloat = 1
    @State private var innerRotation: Double = 0
    @State private var outerRotation: Double = 0
    
    var body: some View {
        ZStack {
            // Outer ring
            Circle()
                .stroke(
                    DesignSystem.Colors.twilightGradient,
                    lineWidth: 2
                )
                .frame(width: 150, height: 150)
                .rotationEffect(.degrees(outerRotation))
                .scaleEffect(pulseScale)
            
            // Inner ring
            Circle()
                .stroke(
                    DesignSystem.Colors.accentPrimary.opacity(0.5),
                    lineWidth: 3
                )
                .frame(width: 100, height: 100)
                .rotationEffect(.degrees(innerRotation))
            
            // Center icon
            Image(systemName: "infinity")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(DesignSystem.Colors.twilightGradient)
                .scaleEffect(pulseScale * 0.9)
        }
        .onAppear {
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                outerRotation = 360
            }
            
            withAnimation(.linear(duration: 15).repeatForever(autoreverses: false)) {
                innerRotation = -360
            }
            
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                pulseScale = 1.1
            }
        }
    }
}