import Foundation

// MARK: - Mythology Language System
// The lexicon of The Unseen - transforming technical language into mythological narrative

enum Mythology {
    
    // MARK: - Actions
    enum Actions {
        static let begin = "BEGIN THE PATH"
        static let send = "SEND"
        static let accept = "ACCEPT"
        static let decline = "DECLINE"
        static let proposeConvergence = "PROPOSE CONVERGENCE"
        static let confirmArrival = "CONFIRM ARRIVAL"
        static let sealOffering = "SEAL THE OFFERING"
        static let exitPath = "LEAVE THE PATH"
        static let blockInitiate = "BLOCK THIS INITIATE"
        static let reportInitiate = "REPORT CONCERN"
    }
    
    // MARK: - Status Messages
    enum Status {
        static let searching = "Seeking a fellow Initiate nearby..."
        static let connecting = "Forging connection..."
        static let connected = "Path established"
        static let handshakeComplete = "Sacred handshake complete"
        static let waitingForResponse = "The invitation has been sent. Awaiting a reply..."
        static let verifying = "Verifying Convergence... Bring your devices close"
        static let convergenceActive = "The Convergence is active"
        static let integrationReady = "The Integration awaits"
        static let pathClosed = "The path has closed"
    }
    
    // MARK: - Placeholders
    enum Placeholders {
        static let chatInput = "Speak your truth..."
        static let locationDescription = "Describe your location to your fellow Initiate"
        static let appearanceDescription = "Describe your appearance"
        static let artifact = "Create a shared artifact together..."
        static let reflection = "Your Offering: What did this interaction reveal in YOU?"
    }
    
    // MARK: - Titles
    enum Titles {
        static let theUnseen = "THE UNSEEN"
        static let thePath = "The Path"
        static let convergence = "The Convergence"
        static let integration = "The Integration"
        static let seekSafety = "Seek Safety"
        static let sacredSpace = "The Container"
        static let meetup = "Staring In The Mirror"
    }
    
    // MARK: - Prompts & Questions
    enum Prompts {
        static let convergenceInvitation = "%@ attempts The Convergence."
        static let confirmConvergence = "Do you accept this invitation to meet in person?"
        static let integrationPrompt1 = "What did this interaction reveal in YOU?"
        static let integrationPrompt2 = "What part of you were you most afraid to show? What happened when you did?"
        static let integrationPrompt3 = "Describe a moment where you felt most alive."
        static let presenceQuestion = "How present were you in the container?"
        static let courageQuestion = "How much courage did you bring?"
        static let resonanceQuestion = "How resonant did the connection feel?"
    }
    
    // MARK: - Notifications
    enum Notifications {
        static let integrationReminder = "Your Integration expires soon. Complete it to receive ANIMA."
        static let convergenceRequest = "%@ has proposed The Convergence"
        static let pathAvailable = "The Path is open. Begin when ready."
        static let animaAwarded = "You have received %d ANIMA"
    }
    
    // MARK: - Instructions
    enum Instructions {
        static let beginPath = "Tap to begin seeking a fellow Initiate"
        static let convergenceExplanation = "The Convergence is an invitation to meet in physical space. Only accept if you feel safe and ready."
        static let integrationExplanation = "The Integration is a private reflection on your shared experience. Both Initiates must complete it to receive ANIMA."
        static let animaExplanation = "ANIMA represents the soul energy exchanged in authentic connection"
        static let safetyReminder = "Trust your instincts. You can leave The Path at any time."
    }
    
    // MARK: - Act Names (for 3-act structure)
    enum Acts {
        static let arrival = "Act I: Arrival"
        static let exchange = "Act II: Exchange"
        static let closing = "Act III: Closing"
    }
    
    // MARK: - Error Messages
    enum Errors {
        static let connectionLost = "The path has been severed"
        static let convergenceFailed = "The Convergence could not be verified"
        static let integrationExpired = "This Integration has expired"
        static let permissionDenied = "Permission to walk this path has been denied"
    }
}