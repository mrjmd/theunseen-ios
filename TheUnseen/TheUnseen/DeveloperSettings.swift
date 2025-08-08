import Foundation
import SwiftUI

// MARK: - Developer Settings Manager
class DeveloperSettings: ObservableObject {
    static let shared = DeveloperSettings()
    
    @Published var isDeveloperModeEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isDeveloperModeEnabled, forKey: "developerModeEnabled")
            print("🔧 Developer Mode: \(isDeveloperModeEnabled ? "ENABLED" : "DISABLED")")
        }
    }
    
    private init() {
        // Check if we have a saved preference
        if UserDefaults.standard.object(forKey: "developerModeEnabled") != nil {
            // Use saved preference
            self.isDeveloperModeEnabled = UserDefaults.standard.bool(forKey: "developerModeEnabled")
        } else {
            // First launch - default to developer mode ON for testing
            // TODO: Change to false before production release
            self.isDeveloperModeEnabled = true
            UserDefaults.standard.set(true, forKey: "developerModeEnabled")
        }
    }
    
    // MARK: - Timing Configuration
    
    // Meaningful interaction requirements
    var minimumSessionDuration: TimeInterval {
        isDeveloperModeEnabled ? 30 : 150  // 30s dev / 2.5 min prod
    }
    
    // Convergence timer
    var convergenceDuration: TimeInterval {
        isDeveloperModeEnabled ? 60 : 300  // 1 min dev / 5 min prod
    }
    
    // Integration cooldown
    var integrationCooldown: TimeInterval {
        isDeveloperModeEnabled ? 60 : 300  // 1 min dev / 5 min prod
    }
    
    // Re-match cooldown
    var rematchCooldown: TimeInterval {
        isDeveloperModeEnabled ? 10 : 3600  // 10s dev / 1 hour prod
    }
    
    // Messages per act for 3-act structure
    var messagesPerAct: Int {
        isDeveloperModeEnabled ? 2 : 4  // 2 dev / 4 prod
    }
    
    // Connection timeout
    var connectionTimeout: TimeInterval {
        isDeveloperModeEnabled ? 10 : 30  // 10s dev / 30s prod
    }
    
    // MARK: - Feature Flags
    
    var showDebugInfo: Bool {
        isDeveloperModeEnabled
    }
    
    var skipHandshake: Bool {
        false  // Can enable for ultra-quick testing
    }
    
    var autoProgressPrompts: Bool {
        false  // Can enable to auto-advance through acts
    }
    
    // MARK: - Helper Methods
    
    func resetAllCooldowns() {
        // Clear all cooldown-related UserDefaults
        let defaults = UserDefaults.standard
        let keys = defaults.dictionaryRepresentation().keys.filter { $0.hasPrefix("lastSession_") }
        keys.forEach { defaults.removeObject(forKey: $0) }
        print("🔧 All cooldowns reset")
    }
    
    func clearSessionData() {
        // Clear all session-related data for fresh testing
        resetAllCooldowns()
        UserDefaults.standard.removeObject(forKey: "currentSessionId")
        print("🔧 Session data cleared")
    }
}

// MARK: - Developer Menu View
struct DeveloperMenuView: View {
    @StateObject private var settings = DeveloperSettings.shared
    @Environment(\.dismiss) var dismiss
    @State private var showingResetConfirmation = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Developer Mode", isOn: $settings.isDeveloperModeEnabled)
                        .tint(.purple)
                    
                    if settings.isDeveloperModeEnabled {
                        Label("Dev mode active", systemImage: "wrench.and.screwdriver")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                } header: {
                    Text("Main Toggle")
                } footer: {
                    Text("Enables shorter timers and cooldowns for testing")
                }
                
                if settings.isDeveloperModeEnabled {
                    Section("Current Settings") {
                        SettingRow(label: "Session Duration", 
                                  value: "\(Int(settings.minimumSessionDuration))s")
                        SettingRow(label: "Convergence Timer", 
                                  value: "\(Int(settings.convergenceDuration))s")
                        SettingRow(label: "Integration Cooldown", 
                                  value: "\(Int(settings.integrationCooldown))s")
                        SettingRow(label: "Re-match Cooldown", 
                                  value: "\(Int(settings.rematchCooldown))s")
                        SettingRow(label: "Messages per Act", 
                                  value: "\(settings.messagesPerAct)")
                    }
                    
                    Section("Quick Actions") {
                        Button(action: {
                            settings.resetAllCooldowns()
                        }) {
                            Label("Reset All Cooldowns", systemImage: "clock.arrow.circlepath")
                                .foregroundColor(.blue)
                        }
                        
                        Button(action: {
                            settings.clearSessionData()
                        }) {
                            Label("Clear Session Data", systemImage: "trash")
                                .foregroundColor(.orange)
                        }
                        
                        Button(action: {
                            showingResetConfirmation = true
                        }) {
                            Label("Reset Everything", systemImage: "exclamationmark.triangle")
                                .foregroundColor(.red)
                        }
                    }
                    
                    Section("Debug Info") {
                        SettingRow(label: "Bundle ID", 
                                  value: Bundle.main.bundleIdentifier ?? "Unknown")
                        SettingRow(label: "Version", 
                                  value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")
                        SettingRow(label: "Device ID", 
                                  value: String(UIDevice.current.identifierForVendor?.uuidString.prefix(8) ?? "Unknown"))
                    }
                }
            }
            .navigationTitle("Developer Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Reset Everything?", isPresented: $showingResetConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    settings.resetAllCooldowns()
                    settings.clearSessionData()
                    settings.isDeveloperModeEnabled = false
                }
            } message: {
                Text("This will clear all data and disable developer mode")
            }
        }
    }
}

struct SettingRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(.gray)
        }
    }
}

#Preview {
    DeveloperMenuView()
}