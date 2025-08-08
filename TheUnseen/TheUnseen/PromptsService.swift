import Foundation

// MARK: - Prompt Model
struct Prompt: Codable, Identifiable {
    let id: String
    let level: Int
    let digitalPrompt: String  // For the initial digital container
    let convergencePrompt: String  // For the in-person meeting
    let theme: String  // e.g., "vulnerability", "authenticity", "shadow", "dreams"
    
    init(id: String = UUID().uuidString, level: Int, digitalPrompt: String, convergencePrompt: String, theme: String = "general") {
        self.id = id
        self.level = level
        self.digitalPrompt = digitalPrompt
        self.convergencePrompt = convergencePrompt
        self.theme = theme
    }
}

// MARK: - Prompts Service
class PromptsService: ObservableObject {
    static let shared = PromptsService()
    
    @Published var currentPrompt: Prompt?
    @Published var currentPhase: PromptPhase = .digital
    
    enum PromptPhase {
        case digital
        case convergence
    }
    
    // MARK: - Level 1 Prompts (The Path - Simple Vulnerability)
    private let level1Prompts = [
        Prompt(
            level: 1,
            digitalPrompt: "Share something you're grateful for today.",
            convergencePrompt: "Look into each other's eyes and share what you see that reminds you of your own gratitude.",
            theme: "gratitude"
        ),
        Prompt(
            level: 1,
            digitalPrompt: "What's one thing you wish people knew about you?",
            convergencePrompt: "Without words, show each other something about yourselves through a gesture or expression. Then explain what you saw.",
            theme: "recognition"
        ),
        Prompt(
            level: 1,
            digitalPrompt: "Describe a moment when you felt truly alive.",
            convergencePrompt: "Share the physical sensations you experienced in that moment of aliveness. Where in your body do you feel most alive right now?",
            theme: "aliveness"
        ),
        Prompt(
            level: 1,
            digitalPrompt: "What's a fear you're ready to release?",
            convergencePrompt: "Stand together and take three deep breaths. On the exhale, imagine releasing that fear. Share what you noticed.",
            theme: "release"
        ),
        Prompt(
            level: 1,
            digitalPrompt: "Share a dream you haven't told anyone.",
            convergencePrompt: "Close your eyes and describe your dream as if it's happening right now. Your partner will witness without judgment.",
            theme: "dreams"
        ),
        Prompt(
            level: 1,
            digitalPrompt: "What mask do you wear most often?",
            convergencePrompt: "Show each other your 'mask face' and your 'real face.' Notice the difference in how each feels.",
            theme: "authenticity"
        ),
        Prompt(
            level: 1,
            digitalPrompt: "When do you feel most like yourself?",
            convergencePrompt: "Share a small action or movement that makes you feel like yourself. Invite your partner to mirror it.",
            theme: "authenticity"
        ),
        Prompt(
            level: 1,
            digitalPrompt: "What's a truth you've been avoiding?",
            convergencePrompt: "Speak your avoided truth while maintaining eye contact. Notice what changes when it's witnessed.",
            theme: "truth"
        ),
        Prompt(
            level: 1,
            digitalPrompt: "Share a moment of unexpected kindness.",
            convergencePrompt: "Offer each other a small, genuine compliment about something you've noticed during your interaction.",
            theme: "kindness"
        ),
        Prompt(
            level: 1,
            digitalPrompt: "What would you do if you knew you couldn't fail?",
            convergencePrompt: "Take turns sharing your answer while the other person responds with only 'Yes, and...' to build on the vision.",
            theme: "possibility"
        )
    ]
    
    // MARK: - Level 2 Prompts (The Shadow - Deeper Vulnerability)
    // These can be added as the app progresses
    private let level2Prompts: [Prompt] = [
        // Placeholder for Level 2 prompts
        // These will explore shadow work, deeper patterns, etc.
    ]
    
    // MARK: - Public Methods
    
    func getRandomPrompt(for level: Int) -> Prompt? {
        switch level {
        case 1:
            return level1Prompts.randomElement()
        case 2:
            return level2Prompts.randomElement()
        default:
            return level1Prompts.randomElement()
        }
    }
    
    func getPrompt(by id: String) -> Prompt? {
        let allPrompts = level1Prompts + level2Prompts
        return allPrompts.first { $0.id == id }
    }
    
    func getPromptsForLevel(_ level: Int) -> [Prompt] {
        switch level {
        case 1:
            return level1Prompts
        case 2:
            return level2Prompts
        default:
            return []
        }
    }
    
    func getCurrentPromptText() -> String? {
        guard let prompt = currentPrompt else { return nil }
        
        switch currentPhase {
        case .digital:
            return prompt.digitalPrompt
        case .convergence:
            return prompt.convergencePrompt
        }
    }
    
    func transitionToConvergence() {
        currentPhase = .convergence
    }
    
    func resetToDigital() {
        currentPhase = .digital
    }
    
    // MARK: - Prompt Selection with P2P Sync
    
    func selectAndSharePrompt(for level: Int, using p2pService: P2PConnectivityService) {
        guard let prompt = getRandomPrompt(for: level) else { return }
        
        currentPrompt = prompt
        currentPhase = .digital
        
        // Share the prompt ID with peer for sync
        p2pService.sendSystemMessage("PROMPT_ID:\(prompt.id)")
        p2pService.currentPrompt = prompt.digitalPrompt
    }
    
    func receivePromptId(_ promptId: String, using p2pService: P2PConnectivityService) {
        guard let prompt = getPrompt(by: promptId) else { return }
        
        currentPrompt = prompt
        currentPhase = .digital
        p2pService.currentPrompt = prompt.digitalPrompt
    }
}

// MARK: - Future Enhancement: Load from JSON
extension PromptsService {
    
    func loadPromptsFromJSON() {
        // Future implementation to load prompts from a JSON file
        // This allows for easier updates without code changes
        
        /* Example JSON structure:
        {
            "prompts": [
                {
                    "id": "uuid",
                    "level": 1,
                    "digitalPrompt": "...",
                    "convergencePrompt": "...",
                    "theme": "vulnerability"
                }
            ]
        }
        */
    }
    
    func saveCustomPrompts(_ prompts: [Prompt]) {
        // Future implementation to save user-created or downloaded prompts
    }
}