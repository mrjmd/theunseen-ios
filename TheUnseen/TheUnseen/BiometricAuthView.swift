import SwiftUI

struct BiometricAuthView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var biometricService = BiometricAuthService()
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isAuthenticating = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color.purple.opacity(0.3)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Minimal branding
                Spacer()
                
                // Biometric prompt with mythology
                VStack(spacing: 40) {
                    // Subtle icon
                    Image(systemName: biometricService.biometricIconName)
                        .font(.system(size: 50))
                        .foregroundColor(.white.opacity(0.8))
                        .symbolEffect(.pulse, options: .repeating.speed(0.5))
                    
                    VStack(spacing: 15) {
                        Text("To enter the Dojo,")
                            .font(.system(size: 18, weight: .light))
                            .foregroundColor(.white)
                        
                        Text("present your unique signature.")
                            .font(.system(size: 18, weight: .light))
                            .foregroundColor(.white)
                    }
                }
                
                Spacer()
                
                // Authenticate button
                Button(action: authenticate) {
                    HStack {
                        if isAuthenticating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.right.circle.fill")
                            Text("Begin")
                                .font(.headline)
                        }
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 50)
                    .padding(.vertical, 15)
                    .background(Color.white)
                    .cornerRadius(25)
                }
                .disabled(isAuthenticating)
                .opacity(isAuthenticating ? 0.6 : 1)
                
                Spacer()
            }
        }
        .alert("Authentication Failed", isPresented: $showError) {
            Button("Try Again", action: authenticate)
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            // Auto-prompt for biometric auth after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                authenticate()
            }
        }
    }
    
    private func authenticate() {
        isAuthenticating = true
        errorMessage = ""
        
        authService.signInWithBiometrics { success, error in
            isAuthenticating = false
            
            if !success {
                errorMessage = error ?? "Authentication failed"
                showError = true
            }
            // If successful, the authService will update and the main app will show
        }
    }
}

#Preview {
    BiometricAuthView()
        .environmentObject(AuthService())
}