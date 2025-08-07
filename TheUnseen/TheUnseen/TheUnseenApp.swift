import SwiftUI
import FirebaseCore
import FirebaseAuth

// By using an AppDelegate, we guarantee that Firebase is configured
// before any other part of our app tries to use it.
class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    print("Application is launching. Configuring Firebase...")
    FirebaseApp.configure()
    return true
  }
}

@main
struct TheUnseenApp: App {
    // Register the app delegate to run on launch.
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    // Create our services as StateObjects so they persist.
    @StateObject private var authService = AuthService()
    @StateObject private var firestoreService = FirestoreService()
    @StateObject private var p2pService = P2PConnectivityService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                // Provide all services to the environment.
                .environmentObject(p2pService)
                .environmentObject(authService)
                .environmentObject(firestoreService)
                .onReceive(authService.$user) { user in
                    // When the user signs in, create their Firestore document.
                    if let user = user {
                        firestoreService.createUserIfNeeded(uid: user.uid)
                    }
                }
                // ANIMA is now awarded in P2PConnectivityService after meaningful interaction
        }
    }
}
