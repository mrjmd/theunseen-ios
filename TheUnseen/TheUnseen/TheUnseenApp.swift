import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseCrashlytics
import FirebasePerformance
import UserNotifications

// By using an AppDelegate, we guarantee that Firebase is configured
// before any other part of our app tries to use it.
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    print("Application is launching. Configuring Firebase...")
    FirebaseApp.configure()
    
    // Configure Crashlytics settings
    configureCrashlytics()
    
    // Configure Performance Monitoring
    configurePerformanceMonitoring()
    
    // Set notification delegate to handle foreground notifications
    UNUserNotificationCenter.current().delegate = self
    
    // Request notification permissions
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
        if granted {
            print("Notification permissions granted")
        } else if let error = error {
            print("Error requesting notifications: \(error)")
        }
    }
    
    return true
  }
  
  // Handle notifications when app is in foreground
  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
      // Show notification even when app is in foreground
      completionHandler([.banner, .sound])
  }
  
  // Handle notification tap
  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler: @escaping () -> Void) {
      // Check if this is an Integration notification
      if response.notification.request.identifier.starts(with: "integration-ready-") {
          // Post notification to open Integration view
          NotificationCenter.default.post(name: NSNotification.Name("OpenPendingIntegration"), object: nil)
      }
      completionHandler()
  }
  
  private func configureCrashlytics() {
      // Set anonymous user properties for better crash segmentation
      Crashlytics.crashlytics().setCustomValue(DeveloperSettings.shared.isDeveloperModeEnabled, forKey: "developer_mode")
      Crashlytics.crashlytics().setCustomValue(UIDevice.current.systemVersion, forKey: "ios_version")
      Crashlytics.crashlytics().setCustomValue(UIDevice.current.userInterfaceIdiom == .pad ? "iPad" : "iPhone", forKey: "device_type")
      
      // Log app launch
      Crashlytics.crashlytics().log("App launched successfully")
      
      print("✅ Crashlytics configured with privacy-preserving settings")
  }
  
  private func configurePerformanceMonitoring() {
      // Performance Monitoring is automatically started
      // We can disable it in debug builds if needed
      #if DEBUG
      Performance.sharedInstance().isInstrumentationEnabled = false
      Performance.sharedInstance().isDataCollectionEnabled = false
      print("⚠️ Performance Monitoring disabled in DEBUG builds")
      #else
      Performance.sharedInstance().isInstrumentationEnabled = true
      Performance.sharedInstance().isDataCollectionEnabled = true
      print("✅ Performance Monitoring enabled")
      #endif
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
