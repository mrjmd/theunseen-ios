import Foundation

// MARK: - Prompt Model with 3-Act Structure
struct Prompt: Codable, Identifiable {
    let id: String
    let level: Int
    let act: Int  // 1, 2, or 3 for the narrative arc
    let digitalPrompt: String
    let convergencePrompt: String
    let theme: String
    let voicePrefix: String  // "The Mirror asks...", "An Inquiry from the Unseen...", etc.
    
    init(id: String = UUID().uuidString, level: Int, act: Int, digitalPrompt: String, convergencePrompt: String, theme: String, voicePrefix: String) {
        self.id = id
        self.level = level
        self.act = act
        self.digitalPrompt = digitalPrompt
        self.convergencePrompt = convergencePrompt
        self.theme = theme
        self.voicePrefix = voicePrefix
    }
}

// MARK: - Three-Act Journey Structure
struct PromptJourney: Identifiable {
    let id: String  // Use stable IDs instead of random UUIDs
    let actOne: Prompt      // The Opening - simple, non-threatening
    let actTwo: Prompt      // The Turn - pivot to present moment
    let actThree: Prompt    // The Deepening - introduce the mirror
}

// MARK: - Prompts Service
class PromptsService: ObservableObject {
    static let shared = PromptsService()
    
    @Published var currentPrompt: Prompt?
    @Published var currentJourney: PromptJourney?
    @Published var currentAct: Int = 0  // Start at 0, set to 1 when journey begins
    @Published var currentPhase: PromptPhase = .digital
    
    enum PromptPhase {
        case digital
        case convergence
    }
    
    // MARK: - Mythology Voice Prefixes
    private let digitalVoicePrefixes = [
        "The Mirror asks...",
        "An Inquiry from the Unseen...",
        "The Container invites...",
        "A whisper from the depths...",
        "The Sacred Algorithm wonders...",
        "Your shadow inquires...",
        "The Path reveals...",
        "From the void, a question...",
        "The Initiate seeks..."
    ]
    
    private let convergenceVoicePrefixes = [
        "In this sacred space...",
        "The Convergence asks...",
        "Between two souls...",
        "The physical realm invites...",
        "In presence, we explore...",
        "The embodied Mirror wonders..."
    ]
    
    // MARK: - Level 1 Journeys (3-Act Narratives)
    private let level1Journeys = [
        // Journey 1: Joy → Presence → Mirror
        PromptJourney(
            id: "JOURNEY_001_JOY",
            actOne: Prompt(
                id: "L1_JOY_001",
                level: 1,
                act: 1,
                digitalPrompt: "What's a small thing that brought you joy this week?",
                convergencePrompt: "Share a moment from our digital exchange that surprised you.",
                theme: "Joy & Opening",
                voicePrefix: "The Mirror asks..."
            ),
            actTwo: Prompt(
                id: "L1_PRESENCE_001",
                level: 1,
                act: 2,
                digitalPrompt: "What are you noticing in your body right now as you answer this?",
                convergencePrompt: "Let's both take one deep breath together. [Pause]. What shifted in you with that breath?",
                theme: "Present Awareness",
                voicePrefix: "An Inquiry from the Unseen..."
            ),
            actThree: Prompt(
                id: "L1_MIRROR_001",
                level: 1,
                act: 3,
                digitalPrompt: "Based on my answers, what's one assumption you're making about me?",
                convergencePrompt: "What strength do you see in me that you wish you had more of yourself?",
                theme: "The Mirror",
                voicePrefix: "Your shadow inquires..."
            )
        ),
        
        // Journey 2: Fear → Vulnerability → Recognition
        PromptJourney(
            id: "JOURNEY_002_FEAR",
            actOne: Prompt(
                id: "L1_FEAR_002",
                level: 1,
                act: 1,
                digitalPrompt: "What's something small you've been avoiding lately?",
                convergencePrompt: "What story did you tell yourself about me based on my messages?",
                theme: "Gentle Fear",
                voicePrefix: "The Container invites..."
            ),
            actTwo: Prompt(
                id: "L1_VULNERABLE_002",
                level: 1,
                act: 2,
                digitalPrompt: "Complete this sentence: 'Right now, I'm feeling...'",
                convergencePrompt: "Without using emotion words, describe the sensation in your body as you sit with me.",
                theme: "Vulnerability",
                voicePrefix: "A whisper from the depths..."
            ),
            actThree: Prompt(
                id: "L1_RECOGNITION_002",
                level: 1,
                act: 3,
                digitalPrompt: "What quality in my responses reminds you of yourself?",
                convergencePrompt: "What is the unspoken question in the space between us right now?",
                theme: "Recognition",
                voicePrefix: "The Sacred Algorithm wonders..."
            )
        ),
        
        // Journey 3: Truth → Energy → Connection
        PromptJourney(
            id: "JOURNEY_003_TRUTH",
            actOne: Prompt(
                id: "L1_TRUTH_003",
                level: 1,
                act: 1,
                digitalPrompt: "Share a truth about today that you haven't told anyone yet.",
                convergencePrompt: "What did our digital conversation reveal in YOU?",
                theme: "Simple Truth",
                voicePrefix: "The Path reveals..."
            ),
            actTwo: Prompt(
                id: "L1_ENERGY_003",
                level: 1,
                act: 2,
                digitalPrompt: "How would you describe your energy right now using only colors or weather?",
                convergencePrompt: "Describe the 'weather' of our connection using only metaphors from nature.",
                theme: "Energy Reading",
                voicePrefix: "From the void, a question..."
            ),
            actThree: Prompt(
                id: "L1_CONNECTION_003",
                level: 1,
                act: 3,
                digitalPrompt: "What about this interaction feels different from your usual conversations?",
                convergencePrompt: "If this five-minute container had a title, what would it be?",
                theme: "Connection",
                voicePrefix: "The Initiate seeks..."
            )
        ),
        
        // Journey 4: Mask → Presence → Wholeness
        PromptJourney(
            id: "JOURNEY_004_MASK",
            actOne: Prompt(
                id: "L1_MASK_004",
                level: 1,
                act: 1,
                digitalPrompt: "What part of yourself do you usually keep hidden?",
                convergencePrompt: "Show me your 'public face' and then your 'private face'. What's the difference?",
                theme: "The Mask",
                voicePrefix: "The Mirror asks..."
            ),
            actTwo: Prompt(
                id: "L1_BODY_004",
                level: 1,
                act: 2,
                digitalPrompt: "Where in your body do you feel the most tension right now?",
                convergencePrompt: "Place your hand where you feel tension. Breathe into it. What does it want to say?",
                theme: "Embodiment",
                voicePrefix: "Your shadow inquires..."
            ),
            actThree: Prompt(
                id: "L1_WHOLE_004",
                level: 1,
                act: 3,
                digitalPrompt: "What would it mean to bring all of yourself to this conversation?",
                convergencePrompt: "What part of me helps you remember a forgotten part of yourself?",
                theme: "Wholeness",
                voicePrefix: "The Sacred Algorithm wonders..."
            )
        ),
        
        // Journey 5: Gratitude → Aliveness → Possibility
        PromptJourney(
            id: "JOURNEY_005_GRATITUDE",
            actOne: Prompt(
                id: "L1_GRATITUDE_005",
                level: 1,
                act: 1,
                digitalPrompt: "What are you grateful for that you almost missed today?",
                convergencePrompt: "Look at me and share what you're grateful for in this exact moment.",
                theme: "Gratitude",
                voicePrefix: "The Container invites..."
            ),
            actTwo: Prompt(
                id: "L1_ALIVE_005",
                level: 1,
                act: 2,
                digitalPrompt: "When did you last feel fully, vibrantly alive?",
                convergencePrompt: "What makes you feel most alive in this interaction right now?",
                theme: "Aliveness",
                voicePrefix: "A whisper from the depths..."
            ),
            actThree: Prompt(
                id: "L1_POSSIBLE_005",
                level: 1,
                act: 3,
                digitalPrompt: "What becomes possible when you show up as yourself?",
                convergencePrompt: "What possibility exists between us that didn't exist before we met?",
                theme: "Possibility",
                voicePrefix: "From the void, a question..."
            )
        )
    ]
    
    // MARK: - Convergence In-Person Prompts (Somatic & Projective)
    private let convergencePrompts = [
        // Somatic Mirror Prompts
        Prompt(
            id: "CONV_SOMATIC_001",
            level: 1,
            act: 2,
            digitalPrompt: "",  // Not used for convergence-only prompts
            convergencePrompt: "Without emotion words, describe the sensation in your body as you sit with me.",
            theme: "Somatic",
            voicePrefix: "In this sacred space..."
        ),
        Prompt(
            id: "CONV_SOMATIC_002",
            level: 1,
            act: 2,
            digitalPrompt: "",
            convergencePrompt: "Look at my posture. What does it make you feel in your own body?",
            theme: "Somatic",
            voicePrefix: "The Convergence asks..."
        ),
        Prompt(
            id: "CONV_SOMATIC_003",
            level: 1,
            act: 2,
            digitalPrompt: "",
            convergencePrompt: "Let's breathe together three times. What shifted?",
            theme: "Somatic",
            voicePrefix: "Between two souls..."
        ),
        
        // Projective Field Prompts
        Prompt(
            id: "CONV_PROJECT_001",
            level: 1,
            act: 3,
            digitalPrompt: "",
            convergencePrompt: "What story did you tell yourself about me digitally vs. now?",
            theme: "Projection",
            voicePrefix: "The physical realm invites..."
        ),
        Prompt(
            id: "CONV_PROJECT_002",
            level: 1,
            act: 3,
            digitalPrompt: "",
            convergencePrompt: "What assumption are you making about me, and where does it come from in you?",
            theme: "Projection",
            voicePrefix: "In presence, we explore..."
        ),
        Prompt(
            id: "CONV_PROJECT_003",
            level: 1,
            act: 3,
            digitalPrompt: "",
            convergencePrompt: "What strength do you see in me that you wish you had?",
            theme: "Projection",
            voicePrefix: "The embodied Mirror wonders..."
        ),
        
        // Unspoken Space Prompts
        Prompt(
            id: "CONV_FIELD_001",
            level: 1,
            act: 3,
            digitalPrompt: "",
            convergencePrompt: "What is the unspoken question between us?",
            theme: "The Field",
            voicePrefix: "Between two souls..."
        ),
        Prompt(
            id: "CONV_FIELD_002",
            level: 1,
            act: 3,
            digitalPrompt: "",
            convergencePrompt: "Describe our connection's 'weather' using nature metaphors.",
            theme: "The Field",
            voicePrefix: "In this sacred space..."
        ),
        Prompt(
            id: "CONV_FIELD_003",
            level: 1,
            act: 3,
            digitalPrompt: "",
            convergencePrompt: "If this container had a title, what would it be?",
            theme: "The Field",
            voicePrefix: "The Convergence asks..."
        )
    ]
    
    // MARK: - Public Methods
    
    func startNewJourney(for level: Int, using p2pService: P2PConnectivityService) {
        guard let journey = level1Journeys.randomElement() else { return }
        
        currentJourney = journey
        currentAct = 1
        currentPrompt = journey.actOne
        currentPhase = .digital
        
        // Share the journey ID with peer for sync
        p2pService.sendSystemMessage("JOURNEY_ID:\(journey.id)")
        p2pService.currentPrompt = formatPromptWithVoice(journey.actOne)
        
        // Start the meaningful interaction timer now that journey has begun
        p2pService.startSessionTimer()
    }
    
    func progressToNextAct(using p2pService: P2PConnectivityService) {
        guard let journey = currentJourney else { return }
        
        switch currentAct {
        case 1:
            currentAct = 2
            currentPrompt = journey.actTwo
            p2pService.currentPrompt = formatPromptWithVoice(journey.actTwo)
            p2pService.sendSystemMessage("ACT_CHANGE:2")
            // Progressed to Act 2
        case 2:
            currentAct = 3
            currentPrompt = journey.actThree
            p2pService.currentPrompt = formatPromptWithVoice(journey.actThree)
            p2pService.sendSystemMessage("ACT_CHANGE:3")
            // Progressed to Act 3
        default:
            break
        }
    }
    
    func formatPromptWithVoice(_ prompt: Prompt) -> String {
        let promptText = currentPhase == .digital ? prompt.digitalPrompt : prompt.convergencePrompt
        return "\(prompt.voicePrefix)\n\n\(promptText)"
    }
    
    func getCurrentPromptText() -> String? {
        guard let prompt = currentPrompt else { return nil }
        return formatPromptWithVoice(prompt)
    }
    
    func getRandomConvergencePrompt() -> Prompt? {
        return convergencePrompts.randomElement()
    }
    
    func transitionToConvergence() {
        currentPhase = .convergence
        // Keep the same prompt from the journey for convergence
        // This ensures both users see the same convergence prompt
        // The prompt already has both digital and convergence versions
    }
    
    func resetToDigital() {
        currentPhase = .digital
        currentAct = 1
    }
    
    // MARK: - Journey Sync with Peer
    
    func receiveJourneyId(_ journeyId: String, using p2pService: P2PConnectivityService) {
        // Force UI update on main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // If we already have this journey and are past Act 1, don't reset
            if self.currentJourney?.id == journeyId && self.currentAct > 1 {
                // Journey already synced
                return
            }
            
            if let journey = self.level1Journeys.first(where: { $0.id == journeyId }) {
                self.currentJourney = journey
                
                // Only reset to Act 1 if we don't have a journey yet
                if self.currentAct == 0 {
                    self.currentAct = 1
                    self.currentPrompt = journey.actOne
                    p2pService.currentPrompt = self.formatPromptWithVoice(journey.actOne)
                    
                    // Start the meaningful interaction timer for responder
                    p2pService.startSessionTimer()
                }
                
                self.currentPhase = .digital
                // Synced to journey: \(journeyId)
            } else {
                print("❌ Journey not found: \(journeyId)") // Keep this for debugging
            }
        }
    }
    
    func receiveActChange(_ act: Int, using p2pService: P2PConnectivityService) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  let journey = self.currentJourney else { return }
            
            self.currentAct = act
            switch act {
            case 1:
                self.currentPrompt = journey.actOne
            case 2:
                self.currentPrompt = journey.actTwo
            case 3:
                self.currentPrompt = journey.actThree
            default:
                break
            }
            
            if let prompt = self.currentPrompt {
                p2pService.currentPrompt = self.formatPromptWithVoice(prompt)
                // Act changed to \(act)
            }
        }
    }
    
    // MARK: - Legacy Support (for existing code)
    
    func selectAndSharePrompt(for level: Int, using p2pService: P2PConnectivityService) {
        startNewJourney(for: level, using: p2pService)
    }
    
    func receivePromptId(_ promptId: String, using p2pService: P2PConnectivityService) {
        // Check if it's a journey ID or a legacy prompt ID
        if promptId.contains("JOURNEY") {
            receiveJourneyId(promptId, using: p2pService)
        } else {
            // Legacy: try to find a matching prompt
            let allPrompts = level1Journeys.flatMap { [$0.actOne, $0.actTwo, $0.actThree] }
            if let prompt = allPrompts.first(where: { $0.id == promptId }) {
                currentPrompt = prompt
                currentPhase = .digital
                p2pService.currentPrompt = formatPromptWithVoice(prompt)
                // Found legacy prompt
            }
        }
    }
}