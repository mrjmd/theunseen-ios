# Custom Fonts Setup

## Required Font Files

Please download and add the following font files to this directory:

### RobotoMono (Technical/Code Font)
Download from: https://fonts.google.com/specimen/Roboto+Mono

Required files:
- RobotoMono-Regular.ttf
- RobotoMono-Light.ttf
- RobotoMono-Medium.ttf
- RobotoMono-Bold.ttf

### Cinzel (Sacred/Mystical Font)
Download from: https://fonts.google.com/specimen/Cinzel

Required files:
- Cinzel-Regular.ttf
- Cinzel-Medium.ttf
- Cinzel-SemiBold.ttf
- Cinzel-Bold.ttf

## Installation Steps

### Method 1: Add via Xcode Project Navigator (Recommended)
1. Download the font files from Google Fonts
2. Place all .ttf files in this Fonts directory (already done!)
3. In Xcode, open your project
4. In the Project Navigator (left sidebar), find the TheUnseen folder
5. Drag the entire "Fonts" folder from Finder INTO the TheUnseen group in Xcode
6. In the dialog that appears:
   - UNCHECK "Copy items if needed" (files are already in place)
   - CHECK "Create folder references" or "Create groups"
   - CHECK "Add to targets: TheUnseen"
7. Click "Finish"

### Method 2: Add Individual Files
1. In Xcode, select the TheUnseen folder in Project Navigator
2. Go to File menu → Add Files to "TheUnseen"...
3. Navigate to: TheUnseen/TheUnseen/Fonts/
4. Select all .ttf files (Cmd+A to select all)
5. Make sure:
   - UNCHECK "Copy items if needed" (files already exist)
   - CHECK "Add to targets: TheUnseen"
6. Click "Add"

### Method 3: Manual Build Phase Addition
1. Select your project in Xcode
2. Select the TheUnseen target
3. Go to "Build Phases" tab
4. Expand "Copy Bundle Resources"
5. Click the "+" button
6. Click "Add Other..."
7. Navigate to the Fonts folder and select all .ttf files
8. Click "Open"

## Verification

The fonts are already configured in:
- Info.plist (UIAppFonts array)
- FontManager.swift (font loading logic)
- DesignSystem.swift (typography styles)

To verify fonts are loaded correctly:
1. Build and run the app
2. Check console for any font loading warnings
3. The app will use fallback fonts if custom fonts aren't found

## Font Usage in Code

```swift
// Sacred/mystical text (Cinzel)
Text("THE UNSEEN")
    .font(DesignSystem.Typography.sacred())

// Technical/monospaced text (RobotoMono)  
Text("3:45")
    .font(DesignSystem.Typography.technical())

// Regular UI text (System font)
Text("Regular text")
    .font(DesignSystem.Typography.body())
```

## Fallback Behavior

If custom fonts are not loaded:
- Cinzel → System Serif font
- RobotoMono → System Monospaced font
- This ensures the app works even without custom fonts