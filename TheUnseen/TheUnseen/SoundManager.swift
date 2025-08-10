import AVFoundation
import UIKit

// MARK: - Sound Manager
// Manages audio playback for The Unseen's mystical sound effects

class SoundManager: NSObject {
    static let shared = SoundManager()
    
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    private var isEnabled = true
    
    // Sound file names (without extension)
    enum Sound: String {
        // Connection sounds
        case connectionSealed = "connection_sealed"
        case messageReceived = "message_received"
        case messageSent = "message_sent"
        
        // ANIMA sounds
        case animaAwarded = "anima_awarded"
        case animaCelebration = "anima_celebration"
        
        // Convergence sounds
        case convergenceBegin = "convergence_begin"
        case convergenceWarning = "convergence_warning"
        case convergenceComplete = "convergence_complete"
        
        // Integration sounds
        case integrationSeal = "integration_seal"
        case offeringComplete = "offering_complete"
        
        // UI sounds
        case buttonTap = "button_tap"
        case transitionWhoosh = "transition_whoosh"
        case sacredChime = "sacred_chime"
        
        // Warning/Error sounds
        case warningBell = "warning_bell"
        case errorTone = "error_tone"
        
        // Ambient sounds
        case heartbeat = "heartbeat"
        case breathing = "breathing"
    }
    
    private override init() {
        super.init()
        setupAudioSession()
        preloadSounds()
    }
    
    // MARK: - Setup
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("❌ Failed to setup audio session: \(error)")
        }
    }
    
    private func preloadSounds() {
        // Preload critical sounds for instant playback
        let criticalSounds: [Sound] = [
            .connectionSealed,
            .messageReceived,
            .animaAwarded,
            .integrationSeal
        ]
        
        for sound in criticalSounds {
            _ = prepareSound(sound)
        }
    }
    
    // MARK: - Public Methods
    
    /// Play a sound effect
    func play(_ sound: Sound, volume: Float = 1.0) {
        guard isEnabled else { return }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            if let player = self?.prepareSound(sound) {
                DispatchQueue.main.async {
                    player.volume = volume
                    player.play()
                }
            }
        }
    }
    
    /// Play a sound with custom file name
    func playCustom(_ fileName: String, fileExtension: String = "mp3", volume: Float = 1.0) {
        guard isEnabled else { return }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            if let url = Bundle.main.url(forResource: fileName, withExtension: fileExtension),
               let player = try? AVAudioPlayer(contentsOf: url) {
                player.prepareToPlay()
                DispatchQueue.main.async {
                    player.volume = volume
                    player.play()
                }
            }
        }
    }
    
    /// Loop a sound (for ambient effects)
    func loop(_ sound: Sound, volume: Float = 0.5) {
        guard isEnabled else { return }
        
        if let player = prepareSound(sound) {
            player.numberOfLoops = -1 // Infinite loop
            player.volume = volume
            player.play()
        }
    }
    
    /// Stop a looping sound
    func stopLoop(_ sound: Sound) {
        audioPlayers[sound.rawValue]?.stop()
    }
    
    /// Stop all sounds
    func stopAll() {
        audioPlayers.values.forEach { $0.stop() }
    }
    
    /// Toggle sound effects on/off
    func setSoundEnabled(_ enabled: Bool) {
        isEnabled = enabled
        if !enabled {
            stopAll()
        }
    }
    
    // MARK: - Private Methods
    
    private func prepareSound(_ sound: Sound) -> AVAudioPlayer? {
        // Check cache first
        if let existingPlayer = audioPlayers[sound.rawValue] {
            return existingPlayer
        }
        
        // Try to load the sound file
        // First try .m4a (better for iOS), then .mp3, then .wav
        let extensions = ["m4a", "mp3", "wav", "aiff", "caf"]
        
        for ext in extensions {
            if let url = Bundle.main.url(forResource: sound.rawValue, withExtension: ext) {
                do {
                    let player = try AVAudioPlayer(contentsOf: url)
                    player.prepareToPlay()
                    audioPlayers[sound.rawValue] = player
                    return player
                } catch {
                    print("⚠️ Failed to load sound \(sound.rawValue).\(ext): \(error)")
                }
            }
        }
        
        // Sound file not found - this is okay for MVP
        print("ℹ️ Sound file not found: \(sound.rawValue)")
        return nil
    }
    
    // MARK: - Special Effects
    
    /// Play heartbeat pattern for countdown
    func startHeartbeat(volume: Float = 0.3) {
        loop(.heartbeat, volume: volume)
    }
    
    func stopHeartbeat() {
        stopLoop(.heartbeat)
    }
    
    /// Play ANIMA celebration sequence
    func playAnimaCelebration(amount: Int) {
        play(.animaAwarded)
        
        // Add extra chimes for larger amounts
        if amount >= 100 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.play(.sacredChime, volume: 0.7)
            }
        }
    }
    
    /// Play connection sequence
    func playConnectionSequence() {
        play(.connectionSealed)
    }
    
    /// Play warning sequence for countdown
    func playCountdownWarning() {
        play(.convergenceWarning, volume: 0.6)
    }
}

// MARK: - Sound Settings
extension SoundManager {
    
    /// Check if device has silent mode on
    var isDeviceSilent: Bool {
        // This is a simplified check - in production you'd want more robust detection
        return AVAudioSession.sharedInstance().outputVolume == 0
    }
    
    /// Get user's sound preference from UserDefaults
    var isSoundEnabledInSettings: Bool {
        get {
            UserDefaults.standard.object(forKey: "soundEffectsEnabled") as? Bool ?? true
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "soundEffectsEnabled")
            setSoundEnabled(newValue)
        }
    }
}

// MARK: - Placeholder Sound Generator
// For MVP, we can generate simple tones programmatically
extension SoundManager {
    
    /// Generate a simple tone (for MVP when sound files aren't available)
    func generateTone(frequency: Float = 440, duration: TimeInterval = 0.2, volume: Float = 0.5) {
        // This would require AudioUnit or AVAudioEngine for tone generation
        // For now, just trigger a haptic as fallback
        HapticManager.shared.lightImpact()
    }
    
    /// Fallback to haptics when sounds aren't available
    func playWithHapticFallback(_ sound: Sound) {
        play(sound)
        
        // Also trigger appropriate haptic
        switch sound {
        case .connectionSealed:
            HapticManager.shared.connectionEstablished()
        case .messageReceived:
            HapticManager.shared.lightImpact()
        case .animaAwarded:
            HapticManager.shared.animaAwarded()
        case .integrationSeal:
            HapticManager.shared.mediumImpact()
        case .convergenceWarning:
            HapticManager.shared.warning()
        default:
            break
        }
    }
}