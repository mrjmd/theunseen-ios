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
2. Data Flow & Architecture
MVP User Journey: "The Path"
Authentication:
User opens the app for the first time.
Prompted to create an account using Face ID/Touch ID.
The app uses Firebase Auth to create a new user, returning a unique Firebase UID. This UID is the user's Private ID. It is stored securely in the device's Keychain.
Discovery & Session Initiation:
User taps "Begin the Path."
The app activates the Multipeer Connectivity advertiser/browser, searching for other Initiates. To conserve battery, this scan will have a 2-minute timeout before prompting the user to try again.
When another device is discovered, the apps automatically establish a Multipeer connection.
The Handshake:
The clients perform a Noise Protocol XX handshake over the established connection. This generates ephemeral session keys.
The clients then make a single, brief call to a Firebase Cloud Function, sending their UIDs and the Session ID. The function validates that both UIDs are active, legitimate users and logs the session start time for abuse prevention. This is the only server interaction during the session.
A secure, E2E encrypted "container" is now active.
The Interaction:
The app serves the Level 1 prompts.
All messages are encrypted with the session keys and sent directly device-to-device. The server is completely blind.
Session End & ANIMA Update:
The session concludes. The connection is terminated, and the ephemeral session keys are destroyed.
Each user is presented with the private feedback screen ("What did you notice in yourself?" and the "Resonance Score" slider).
Each user's client independently sends their UID, the Session ID, and their Resonance Score to a Firebase Cloud Function.
The Cloud Function waits for both reports for that Session ID. If both scores are above a certain threshold (e.g., 80%), it applies the ANIMA multiplier and updates both users' balances in the Firestore ledger.
3. Firestore Database Schema (MVP)
/users/{userId}
  - privateId: "Firebase_UID"
  - level: 1
  - animaPoints: 150
  - createdAt: Timestamp
  - lastSessionAt: Timestamp

/sessions/{sessionId}
  - userA_Id: "Firebase_UID"
  - userB_Id: "Firebase_UID"
  - userA_Resonance: 8.5
  - userB_Resonance: 9.0
  - status: "completed"
  - createdAt: Timestamp


III. Development & Launch Roadmap (9-Month Plan)
This is a phased plan focused on iterative development, testing, and risk mitigation.
Phase 0: Foundation (Weeks 1-2)
[ ] DevOps/SRE: Set up Firebase project (Auth, Firestore, Functions).
[ ] DevOps/SRE: Configure CI/CD pipeline using GitHub Actions and Fastlane for automated builds, testing, and deployment to TestFlight.
[ ] Lead Engineer: Establish Git repository with a clear branching strategy (e.g., GitFlow).
[ ] Lead Engineer: Create the initial Xcode project, configure dependencies (NoiseKit, Firebase SDKs), and set up the MVVM architecture shell.
[ ] Designer: Finalize the Design System Tokens for the "Normie Mode" UI in Figma.
Phase 1: The Core Container (Weeks 3-8)
[ ] Lead Engineer: Implement device discovery and session management using the Multipeer Connectivity framework.
[ ] Lead Engineer: Integrate the Noise Protocol for the E2E encrypted handshake and message transport.
[ ] QA Lead: Develop a test harness to simulate two devices interacting to validate the P2P connection and encryption without needing two physical devices for every test run.
[ ] Designer/Engineer: Build the basic, functional UI for the chat interface ("The Path").
Phase 2: The Blind Gatekeeper (Weeks 9-12)
[ ] Lead Engineer: Integrate Firebase Authentication with Face ID/Touch ID.
[ ] Lead Engineer: Build the Firestore ledger and the Cloud Functions for initiating sessions and calculating ANIMA points.
[ ] Behavioral Psychologist/Designer: Design and implement the user flow for the Block/Report feature. This includes the in-app reporting interface and the confirmation/support messages the user receives post-submission.
[ ] QA Lead: Write unit and integration tests for all server interactions.
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
