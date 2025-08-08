# theunseen-ios
Project Unseen: MVP Technical Specification & Launch Roadmap
This document outlines the technical architecture, development plan, and launch sequence for The Unseen's Minimum Viable Product (MVP), corresponding to the "Crawl" phase of the strategic plan.
I. The Roundtable: Initial Reactions & Core Tenets
Before the specs, let's align on the core challenges and how we'll address them from day one.
Product Manager: "My focus is singular: solving the 'Empty Room' problem. Every decision in this spec must serve the goal of achieving hyper-density in our launch locations. If a feature doesn't directly contribute to making the first user's experience viable and compelling, it gets pushed to the 'Walk' phase. For the MVP, we are not building a platform; we are building a single, perfect, guided interaction."
Lead Engineer: "Agreed. This means our P2P layer has to be bulletproof but also power-efficient. Battery drain from a constant BLE scan is a non-starter. The architecture I'm proposing prioritizes a 'scan-on-demand' approach that activates intelligently. Stability over features. The foundation must be flawless before we build the cathedral."
Creative Director: "While we're simplifying the features, we cannot simplify the soul. The language is critical. From the very first screen, the user is an 'Initiate,' not a 'user.' The points they earn are 'Fragments of ANIMA.' We seed the mythology now. We can't bolt on the magic later. The MVP must feel like the first chapter of a great mystery, not a beta test."
Legal Expert (Crypto): "And I need to be unequivocally clear on this point, echoing the Creative Director. We will call them 'Fragments of ANIMA' in the lore, but in the UI and terms of service for the MVP, they are 'points.' They are non-transferable, have no cash value, and exist purely for in-game progression. This creates a legal firewall that gives us the time to navigate the regulatory maze for a true token in the 'Run' phase. Any ambiguity here puts the entire venture at risk before it even starts."
Behavioral Psychologist: "My concern is our Duty of Care. We're simplifying the game, but Levels 1 and 2 still involve real vulnerability. The MVP's 'Block/Report' feature can't be a simple button. We need to design the post-report user experience carefully. The user needs to feel heard and safe, ensuring a difficult interaction doesn't cause them to churn. We must validate that we can handle this core responsibility before we scale to more intense shadow work."
Designer: "From a design perspective, I'm fully on board with the 'Normie Mode' UI for the MVP. It's the right call for building initial trust. However, I want to ensure the underlying component system is built with the 'UI Exfoliation' in mind. We'll use a design token system from day one, so when we introduce dark mode and the 'Alchemical Glitch' aesthetic, it's a thematic reveal, not a full refactor."
II. MVP Technical Specification (Crawl Phase)
Objective: Build a stable, secure, and engaging iOS application that executes the core loop for Levels 1 & 2.
1. Core Technology Stack
iOS Application:
Language: Swift 5.10+
UI Framework: SwiftUI (for its modern, declarative approach, which will make the 'UI Exfoliation' easier to implement later).
Architecture: MVVM (Model-View-ViewModel) to ensure separation of concerns and testability.
Dependencies: We will use Swift Package Manager to manage all third-party libraries.
P2P Communication Layer:
Framework: Multipeer Connectivity Framework. Apple's native solution for discovering and communicating with nearby devices over Wi-Fi and Bluetooth.
Why? It abstracts away the complexities of BLE and Wi-Fi Direct, is optimized for battery life, and handles the session management we need for our "containers." It's the most robust and direct path for our MVP.
Encryption: The framework provides out-of-the-box encryption, but for our E2E security promise, we will layer the Noise Protocol Framework on top. We will use a well-vetted Swift implementation like NoiseKit to handle the cryptographic handshake and message encryption within the Multipeer session. The server will never have the session keys.
Server Layer (The "Blind" Gatekeeper):
Platform: Google Firebase.
Why? It's cost-effective at our scale and provides all the necessary tools in one managed platform, minimizing DevOps overhead.
Services:
Firebase Authentication: For user sign-up/sign-in using Apple's native biometrics (Face ID/Touch ID).
Firestore: A NoSQL database to act as our ANIMA Ledger and manage user state.
Cloud Functions for Firebase: To run server-side logic for validating Resonance Scores and updating the ANIMA ledger.
2. Core Game Loop & "The Convergence" Flow

This section details the end-to-end user journey for a complete Level 1 interaction.

    Initiation & Onboarding:

        The user opens the app to a "Veiled Loading Screen" featuring our alchemical logo and mythological text.

        The user is prompted for Face ID / Touch ID to "present their unique signature." This silently creates their secure, anonymous Firebase account.

        The user enters the "PathLaunchView," the simple "Normie Mode" screen to begin seeking another Initiate.

    The Digital Container:

        Upon finding a peer, a secure, E2E encrypted P2P session is established.

        The ChatView appears, and the first Level 1 prompt is served to both users.

    Meaningful Interaction Threshold:

        The app's P2PConnectivityService will monitor the session.

        A "Meaningful Interaction" is achieved when two conditions are met:

            Duration: The session has been active for at least 2.5 minutes (150 seconds).

            Reciprocity: Each participant has sent at least three messages.

        Until this threshold is met, no ANIMA is awarded beyond the initial connection bonus.

    "The Convergence" - The In-Person Invitation:

        Once the threshold is met, a new button appears in the ChatView for both users: "Propose the Convergence."

        When one user taps this button, the other user receives a full-screen alert: [User's Anonymous ID] is attempting The Convergence. Do you accept?

        A 30-second countdown timer is displayed. The user must accept before the timer expires.

        If declined or timed out: The initiator is notified. The app presents them with a solo reflection prompt to gamify the rejection experience and awards a small amount of ANIMA for their courage. The digital chat can continue.

        If accepted: Both users proceed to the next step.

    The Meetup:

        The user who initiated "The Convergence" is prompted to describe their location and appearance (e.g., "I'm by the fountain, wearing a red scarf"). This description is sent to the other user.

        The app's UI shifts to a "Convergence" screen, showing the description and a single button: "Confirm Arrival."

    The Digital Handshake - Proving the Meetup:

        When both users are in close physical proximity and have tapped "Confirm Arrival," their phones will perform a quick, automatic, low-range P2P handshake.

        This successful handshake verifies the in-person meetup.

    The In-Person Container:

        Upon successful verification, the app presents both users with a new, deeper prompt designed for in-person interaction.

        A 5-minute shared timer starts, creating a safe, time-boxed container for the conversation.

    Closing the Container:

        When the timer ends, the session is complete. The P2P connection is terminated.

        Users are prompted to mutually agree on a single quote or takeaway from their interaction to save as a shared "artifact." For the MVP, this artifact is private. A future update will allow users to share these artifacts publicly (e.g., to social media) with mutual consent, providing a mechanism for viral growth.

        After a 5-minute cooldown period (to allow users to physically separate), both will receive a push notification to provide private feedback on the interaction (the "Resonance Score"). This score will determine the final ANIMA multiplier for the session.
Each user is presented with the private feedback screen ("What did you notice in yourself?" and the "Resonance Score" slider).
Each user's client independently sends their UID, the Session ID, and their Resonance Score to a Firebase Cloud Function.
The Cloud Function waits for both reports for that Session ID. If both scores are above a certain threshold (e.g., 80%), it applies the ANIMA multiplier and updates both users' balances in the Firestore ledger.
3. Firestore Database Schema (MVP)
/users/{userId}
  - uid: "Firebase_UID"
  - level: 1
  - animaPoints: 100
  - createdAt: Timestamp
  - blockedUsers: ["UID_of_Blocked_User_1", "UID_of_Blocked_User_2"] // For the Block/Report feature

/sessions/{sessionId}
  // This can be simplified for the MVP, as most logic is client-side.
  // We may only need to log metadata for analytics and safety.
  - participants: ["UID_1", "UID_2"]
  - initiatedAt: Timestamp
  - convergenceCompleted: true/false
  - resonanceScoreA: 8.5 // Submitted after cooldown
  - resonanceScoreB: 9.0 // Submitted after cooldown


III. Development & Launch Roadmap
This is a phased plan focused on iterative development, testing, and risk mitigation.
Phase 0: Foundation
[x] DevOps/SRE: Set up Firebase project (Auth, Firestore, Functions).
[x] DevOps/SRE: Configure CI/CD pipeline using GitHub Actions and Fastlane for automated builds, testing, and deployment to TestFlight.
[x] Lead Engineer: Establish Git repository with a clear branching strategy (e.g., GitFlow).
[x] Lead Engineer: Create the initial Xcode project, configure dependencies (NoiseKit, Firebase SDKs), and set up the MVVM architecture shell.
[x] Designer: Finalize the Design System Tokens for the "Normie Mode" UI in Figma.
Phase 1: The Core Container
[x] Lead Engineer: Implement device discovery and session management using the Multipeer Connectivity framework.
[x] Lead Engineer: Integrate the Noise Protocol for the E2E encrypted handshake and message transport.
[x] QA Lead: Develop a test harness to simulate two devices interacting to validate the P2P connection and encryption without needing two physical devices for every test run.
[x] Designer/Engineer: Build the basic, functional UI for the chat interface ("The Path").
Phase 2: The Blind Gatekeeper & Core Loop (Weeks 9-14)
[x] Lead Engineer: Integrate Firebase Anonymous Authentication.
[x] Lead Engineer: Integrate Biometric Authentication (Face ID/Touch ID) to secure the anonymous user account.
[x] Lead Engineer: Build the initial Firestore ledger.
[ ] Game Designer/Engineer: Implement the Level 1 prompt system.
[ ] Lead Engineer/Game Designer: Implement the "Meaningful Interaction" timer and message count logic.
[ ] Designer/Engineer: Build the UI for "The Convergence" invitation flow, including the 30-second timer.
[ ] Lead Engineer: Implement the close-range "Digital Handshake" for meetup verification.
[ ] Behavioral Psychologist/Designer: Design and implement the user flow for the Block/Report feature.
Phase 3: Polish & Internal Alpha (Weeks 13-16)
[ ] Entire Team: Dogfooding. We become the first Initiates. Daily mandatory sessions.
[ ] Designer/Engineer: Refine all UI/UX elements, animations, and transitions based on feedback.
[ ] Game Designer: Fine-tune the ANIMA point values for session completion and resonance bonuses to ensure the reward loop feels meaningful.
[ ] QA Lead: Conduct extensive testing on battery life, connection stability, and edge cases (e.g., connection loss mid-session, one user going into airplane mode).
[ ] DevOps/SRE: Implement observability tools (Firebase Crashlytics, custom logging) to monitor performance and errors during our Alpha.
Phase 4: App Store Submission & Launch Prep (Weeks 17-18)
[ ] Product Manager: Set up the App Store Connect profile, including all required legal and banking information.
[ ] Brand Strategist/Creative Director: Write all App Store copy, prepare screenshots, and create the preview video. The language must be compelling and hint at the deeper experience without revealing the Trojan Horse.
[- ]Legal Expert: Final review of the Terms of Service and Privacy Policy, ensuring the language around "points" is airtight.
[ ] Lead Engineer: Prepare and submit the final build to the App Store for review.
[ ] Product Manager/Brand Strategist: Finalize the launch plan and partnerships for our first hyper-dense location (e.g., SXSW Interactive).
By the end of this 18-week (approx. 4.5 months) cycle, we will have a high-quality, secure, and deeply tested MVP ready for our "Crawl" phase launch. This aggressive but realistic timeline prioritizes solving the right problems in the right order.
