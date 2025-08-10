import SwiftUI

struct FontTestView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                Text("Font Test View")
                    .font(.largeTitle)
                    .padding(.bottom)
                
                // Test Cinzel Fonts
                Group {
                    Text("Cinzel Fonts (Sacred/Mystical)")
                        .font(.headline)
                        .foregroundColor(.blue)
                    
                    Text("THE UNSEEN")
                        .font(DesignSystem.Typography.sacred(32))
                    
                    Text("The Convergence")
                        .font(DesignSystem.Typography.title())
                    
                    Text("Sacred Space")
                        .font(.sacred(20))
                }
                
                Divider()
                
                // Test RobotoMono Fonts  
                Group {
                    Text("RobotoMono Fonts (Technical)")
                        .font(.headline)
                        .foregroundColor(.blue)
                    
                    Text("ANIMA: 150")
                        .font(DesignSystem.Typography.technical(24))
                    
                    Text("3:45 remaining")
                        .font(.technical(18))
                    
                    Text("Session: abc123xyz")
                        .font(DesignSystem.Typography.monospaced())
                }
                
                Divider()
                
                // System Fonts (Fallback)
                Group {
                    Text("System Fonts (Normie Mode)")
                        .font(.headline)
                        .foregroundColor(.blue)
                    
                    Text("Regular body text")
                        .font(DesignSystem.Typography.body())
                    
                    Text("Caption text")
                        .font(DesignSystem.Typography.caption())
                }
                
                Divider()
                
                // Font Verification
                Group {
                    Text("Font Status")
                        .font(.headline)
                        .foregroundColor(.purple)
                    
                    if FontManager.verifyCustomFonts() {
                        Label("Custom fonts loaded successfully!", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Label("Custom fonts not found - using fallbacks", systemImage: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                    }
                }
            }
            .padding()
        }
        .onAppear {
            // Print available fonts in debug mode
            #if DEBUG
            FontManager.printAvailableFonts()
            #endif
        }
    }
}

#Preview {
    FontTestView()
}