import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: AuthService
    @State private var showTestMenu = false
    @State private var showVeiledLoading = true
    @State private var showBiometricAuth = false
    
    var body: some View {
        ZStack {
            if showVeiledLoading {
                // Step 1: Veiled loading screen
                VeiledLoadingView()
                    .transition(.opacity)
                    .onAppear {
                        // Show for 8 seconds total to allow time to read both texts
                        DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
                            withAnimation(.easeOut(duration: 0.5)) {
                                showVeiledLoading = false
                                showBiometricAuth = true
                            }
                        }
                    }
            } else if showBiometricAuth && authService.user == nil {
                // Step 2: Biometric authentication
                BiometricAuthView()
                    .transition(.opacity)
            } else if authService.user != nil {
                // Step 3: Main app (Normie Mode)
                PathLaunchView()
                    .transition(.opacity)
                    .sheet(isPresented: $showTestMenu) {
                        TestMenuView()
                    }
                    .onAppear {
                        // Hide biometric auth once authenticated
                        showBiometricAuth = false
                    }
            }
        }
        .animation(.easeInOut(duration: 0.5), value: showVeiledLoading)
        .animation(.easeInOut(duration: 0.5), value: showBiometricAuth)
        .animation(.easeInOut(duration: 0.5), value: authService.user != nil)
    }
}

#Preview {
    ContentView()
}
