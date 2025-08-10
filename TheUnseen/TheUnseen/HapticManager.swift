import UIKit

/// Centralized haptic feedback manager for consistent tactile responses
class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    // MARK: - Impact Haptics
    
    /// Light tap for subtle interactions
    func lightImpact() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.prepare()
        impact.impactOccurred()
    }
    
    /// Medium tap for standard button presses
    func mediumImpact() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.prepare()
        impact.impactOccurred()
    }
    
    /// Heavy tap for significant actions
    func heavyImpact() {
        let impact = UIImpactFeedbackGenerator(style: .heavy)
        impact.prepare()
        impact.impactOccurred()
    }
    
    /// Soft tap for iOS 13+
    func softImpact() {
        if #available(iOS 13.0, *) {
            let impact = UIImpactFeedbackGenerator(style: .soft)
            impact.prepare()
            impact.impactOccurred()
        } else {
            lightImpact()
        }
    }
    
    /// Rigid tap for iOS 13+
    func rigidImpact() {
        if #available(iOS 13.0, *) {
            let impact = UIImpactFeedbackGenerator(style: .rigid)
            impact.prepare()
            impact.impactOccurred()
        } else {
            mediumImpact()
        }
    }
    
    // MARK: - Notification Haptics
    
    /// Success feedback for completed actions
    func success() {
        let notification = UINotificationFeedbackGenerator()
        notification.prepare()
        notification.notificationOccurred(.success)
    }
    
    /// Warning feedback for important notices
    func warning() {
        let notification = UINotificationFeedbackGenerator()
        notification.prepare()
        notification.notificationOccurred(.warning)
    }
    
    /// Error feedback for failures
    func error() {
        let notification = UINotificationFeedbackGenerator()
        notification.prepare()
        notification.notificationOccurred(.error)
    }
    
    // MARK: - Selection Haptics
    
    /// Selection changed feedback
    func selectionChanged() {
        let selection = UISelectionFeedbackGenerator()
        selection.prepare()
        selection.selectionChanged()
    }
    
    // MARK: - Custom Patterns
    
    /// Connection established pattern
    func connectionEstablished() {
        DispatchQueue.main.async {
            self.lightImpact()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.mediumImpact()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.success()
                }
            }
        }
    }
    
    /// ANIMA award celebration
    func animaAwarded() {
        DispatchQueue.main.async {
            self.softImpact()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                self.mediumImpact()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    self.success()
                }
            }
        }
    }
    
    /// Sacred space entered
    func sacredSpaceEntered() {
        DispatchQueue.main.async {
            self.softImpact()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.softImpact()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.softImpact()
                }
            }
        }
    }
    
    /// Message sent pattern
    func messageSent() {
        softImpact()
    }
    
    /// Message received pattern
    func messageReceived() {
        lightImpact()
    }
    
    /// Integration completed
    func integrationCompleted() {
        DispatchQueue.main.async {
            self.mediumImpact()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.success()
            }
        }
    }
    
    /// Path begun
    func pathBegun() {
        rigidImpact()
    }
    
    /// Convergence initiated
    func convergenceInitiated() {
        DispatchQueue.main.async {
            self.mediumImpact()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.lightImpact()
            }
        }
    }
}