import SwiftUI

// MARK: - Font Manager
// Manages custom font loading and provides easy access to font families

enum FontManager {
    
    // MARK: - Font Families
    enum FontFamily: String {
        case robotoMono = "RobotoMono"
        case cinzel = "Cinzel"
        case system = "System" // Fallback to system fonts
    }
    
    // MARK: - Font Weights for Custom Fonts
    enum RobotoMonoWeight: String {
        case light = "RobotoMono-Light"
        case regular = "RobotoMono-Regular"
        case medium = "RobotoMono-Medium"
        case bold = "RobotoMono-Bold"
    }
    
    enum CinzelWeight: String {
        case regular = "Cinzel-Regular"
        case medium = "Cinzel-Medium"
        case semiBold = "Cinzel-SemiBold"
        case bold = "Cinzel-Bold"
    }
    
    // MARK: - Font Loading
    static func customFont(_ family: FontFamily, size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch family {
        case .robotoMono:
            return robotoMonoFont(size: size, weight: weight)
        case .cinzel:
            return cinzelFont(size: size, weight: weight)
        case .system:
            return Font.system(size: size, weight: weight)
        }
    }
    
    private static func robotoMonoFont(size: CGFloat, weight: Font.Weight) -> Font {
        let fontName: String
        switch weight {
        case .light, .thin, .ultraLight:
            fontName = RobotoMonoWeight.light.rawValue
        case .regular:
            fontName = RobotoMonoWeight.regular.rawValue
        case .medium, .semibold:
            fontName = RobotoMonoWeight.medium.rawValue
        case .bold, .heavy, .black:
            fontName = RobotoMonoWeight.bold.rawValue
        default:
            fontName = RobotoMonoWeight.regular.rawValue
        }
        
        // Try to load custom font, fall back to system monospaced if not available
        if UIFont(name: fontName, size: size) != nil {
            return Font.custom(fontName, size: size)
        } else {
            print("⚠️ Font \(fontName) not found, using system monospaced")
            return Font.system(size: size, weight: weight, design: .monospaced)
        }
    }
    
    private static func cinzelFont(size: CGFloat, weight: Font.Weight) -> Font {
        let fontName: String
        switch weight {
        case .light, .thin, .ultraLight, .regular:
            fontName = CinzelWeight.regular.rawValue
        case .medium:
            fontName = CinzelWeight.medium.rawValue
        case .semibold:
            fontName = CinzelWeight.semiBold.rawValue
        case .bold, .heavy, .black:
            fontName = CinzelWeight.bold.rawValue
        default:
            fontName = CinzelWeight.regular.rawValue
        }
        
        // Try to load custom font, fall back to system serif if not available
        if UIFont(name: fontName, size: size) != nil {
            return Font.custom(fontName, size: size)
        } else {
            print("⚠️ Font \(fontName) not found, using system serif")
            return Font.system(size: size, weight: weight, design: .serif)
        }
    }
    
    // MARK: - Utility Functions
    
    /// Lists all available fonts (useful for debugging)
    static func printAvailableFonts() {
        #if DEBUG
        for family in UIFont.familyNames.sorted() {
            print("Font Family: \(family)")
            for name in UIFont.fontNames(forFamilyName: family) {
                print("  - \(name)")
            }
        }
        #endif
    }
    
    /// Check if custom fonts are properly loaded
    static func verifyCustomFonts() -> Bool {
        let robotoLoaded = UIFont(name: RobotoMonoWeight.regular.rawValue, size: 16) != nil
        let cinzelLoaded = UIFont(name: CinzelWeight.regular.rawValue, size: 16) != nil
        
        if !robotoLoaded {
            print("❌ RobotoMono font family not loaded")
        }
        if !cinzelLoaded {
            print("❌ Cinzel font family not loaded")
        }
        
        return robotoLoaded && cinzelLoaded
    }
}

// MARK: - Font Extension for Easy Access
extension Font {
    
    // Technical/Modern font (RobotoMono)
    static func technical(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        FontManager.customFont(.robotoMono, size: size, weight: weight)
    }
    
    // Sacred/Mystical font (Cinzel)
    static func sacred(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        FontManager.customFont(.cinzel, size: size, weight: weight)
    }
    
    // Keep system font as fallback
    static func normie(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        Font.system(size: size, weight: weight)
    }
}

// MARK: - Preview Helpers
struct FontPreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Sacred Font Examples
            Group {
                Text("THE UNSEEN")
                    .font(.sacred(32, weight: .bold))
                Text("The Convergence")
                    .font(.sacred(24, weight: .medium))
                Text("Sacred Space")
                    .font(.sacred(18))
            }
            
            Divider()
            
            // Technical Font Examples
            Group {
                Text("ANIMA: 150")
                    .font(.technical(20, weight: .bold))
                Text("Session ID: abc123")
                    .font(.technical(14, weight: .medium))
                Text("3:45 remaining")
                    .font(.technical(16))
            }
            
            Divider()
            
            // Normie Font Examples
            Group {
                Text("Regular Interface Text")
                    .font(.normie(16))
                Text("Button Label")
                    .font(.normie(14, weight: .medium))
            }
        }
        .padding()
        .onAppear {
            FontManager.printAvailableFonts()
            _ = FontManager.verifyCustomFonts()
        }
    }
}

#Preview {
    FontPreview()
}