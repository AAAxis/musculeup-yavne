import Flutter
import UIKit
import Firebase
import FirebaseMessaging
import FirebaseFirestore
import FirebaseAuth
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    print("🚀 AppDelegate: didFinishLaunchingWithOptions called")
    
    // Don't configure Firebase here - Flutter will do it
    // This prevents the "Firebase app has not yet been configured" warning
    print("🔥 Firebase will be initialized by Flutter")
    
    // Register plugins first
    GeneratedPluginRegistrant.register(with: self)
    
    // Configure FCM and notifications AFTER Flutter initializes Firebase
    // We'll do this in a delayed manner to ensure Firebase is ready
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      self.configureFCMAndNotifications()
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    return super.application(app, open: url, options: options)
  }
  
  private func configureFCMAndNotifications() {
    print("🔥 Configuring FCM and notifications after Flutter initialization")
    
    // Configure FCM delegate FIRST (before requesting permissions)
    Messaging.messaging().delegate = self
    print("📱 FCM delegate set")
    
    // Request notification permissions
    UNUserNotificationCenter.current().delegate = self
    print("🔔 UNUserNotificationCenter delegate set")
    
    let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
    UNUserNotificationCenter.current().requestAuthorization(
      options: authOptions,
      completionHandler: { granted, error in
        print("📱 Notification permission granted: \(granted)")
        if let error = error {
          print("❌ Notification permission error: \(error)")
          return
        }
        
        if granted {
          DispatchQueue.main.async {
            // Check if running on simulator
            #if targetEnvironment(simulator)
            print("⚠️ WARNING: Running on iOS Simulator")
            print("⚠️ Push notifications (APNS) do NOT work on simulator!")
            print("⚠️ You MUST test on a real iOS device for push notifications to work")
            print("⚠️ APNS token registration will fail silently on simulator")
            #else
            print("✅ Running on real device - APNS should work")
            #endif
            
            // Register for remote notifications - this will trigger APNS token registration
            print("📱 Attempting to register for remote notifications...")
            UIApplication.shared.registerForRemoteNotifications()
            print("📱 registerForRemoteNotifications() called - waiting for APNS token...")
            print("💡 If APNS token doesn't arrive, check:")
            print("   1. Running on REAL DEVICE (not simulator)")
            print("   2. Push Notifications capability is enabled in Xcode")
            print("   3. aps-environment is set in Runner.entitlements")
            print("   4. App is signed with a valid provisioning profile")
            print("   5. Clean build folder and rebuild after enabling capability")
            
            // Set a timeout to detect if APNS token never arrives
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
              // This will help detect if the callback never fired
              print("⏰ 5 seconds passed - checking if APNS token was received...")
            }
          }
        } else {
          print("⚠️ Notification permission denied")
        }
      }
    )
  }
  
  // Handle APNs token registration
  override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
    let token = tokenParts.joined()
    print("📱 APNs token registered successfully!")
    print("📱 APNs token (first 20 chars): \(token.prefix(20))...")
    
    // Set APNS token on Messaging - this is REQUIRED before FCM can generate a token
    Messaging.messaging().apnsToken = deviceToken
    print("✅ APNS token set on Firebase Messaging")
    
    // Now that APNS token is set, FCM will automatically generate the token
    // The MessagingDelegate.messaging(_:didReceiveRegistrationToken:) will be called
    // But we can also explicitly request it if needed
    requestFCMTokenAfterAPNS()
  }
  
  private func requestFCMTokenAfterAPNS() {
    print("🔥 Requesting FCM token after APNS token is set...")
    
    // Add a small delay to ensure APNS token is fully processed by Firebase
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      Messaging.messaging().token { token, error in
        if let error = error {
          print("❌ Error fetching FCM registration token: \(error)")
          print("❌ Error details: \(error.localizedDescription)")
        } else if let token = token {
          print("🔥 FCM registration token received: \(token)")
          print("✅ FCM Token: \(token)")
          print("📱 Token length: \(token.count)")
          
          // Save FCM token to Firestore
          self.saveFCMTokenToFirestore(token: token)
        } else {
          print("❌ FCM token is nil")
        }
      }
    }
  }
  
  // Handle APNs registration failure
  override func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    let nsError = error as NSError
    print("❌ Failed to register for remote notifications: \(error)")
    print("❌ Error code: \(nsError.code)")
    print("❌ Error domain: \(nsError.domain)")
    print("❌ Error description: \(error.localizedDescription)")
    print("⚠️ FCM token cannot be generated without APNS token")
    print("💡 Troubleshooting steps:")
    print("   1. Open Xcode: open ios/Runner.xcworkspace")
    print("   2. Select Runner target → Signing & Capabilities")
    print("   3. Click '+ Capability' and add 'Push Notifications'")
    print("   4. Verify aps-environment is in Runner.entitlements")
    print("   5. Clean build folder (Cmd+Shift+K) and rebuild")
  }
}

// MARK: - MessagingDelegate
extension AppDelegate: MessagingDelegate {
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    print("🔥 FCM registration token received via delegate: \(String(describing: fcmToken))")
    
    if let token = fcmToken {
      print("✅ FCM Token: \(token)")
      print("📱 Token length: \(token.count)")
      
      // Save FCM token to Firestore (only if user is authenticated)
      // If user is not authenticated yet, the token will be saved when they log in
      saveFCMTokenToFirestore(token: token)
    } else {
      print("❌ FCM Token is nil")
    }
    
    // Post notification for Flutter to listen to if needed
    let dataDict: [String: String] = ["token": fcmToken ?? ""]
    NotificationCenter.default.post(
      name: Notification.Name("FCMToken"),
      object: nil,
      userInfo: dataDict
    )
  }
  
  // Save FCM token to Firestore
  func saveFCMTokenToFirestore(token: String) {
    guard let userId = Auth.auth().currentUser?.uid else {
      print("⚠️ No authenticated user, skipping FCM token save to Firestore")
      print("💡 Token will be saved when user logs in")
      // Store token locally or in UserDefaults so we can save it later when user logs in
      UserDefaults.standard.set(token, forKey: "pending_fcm_token")
      return
    }
    
    print("💾 Saving FCM token to Firestore for user: \(userId)")
    
    let db = Firestore.firestore()
    let tokenData: [String: Any] = [
      "token": token,
      "userId": userId,
      "platform": "ios",
      "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
      "deviceModel": UIDevice.current.model,
      "deviceName": UIDevice.current.name,
      "active": true,
      "createdAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),
      "lastUsedAt": FieldValue.serverTimestamp()
    ]
    
    // Save to fcm_tokens collection
    db.collection("fcm_tokens")
      .whereField("token", isEqualTo: token)
      .getDocuments { (querySnapshot, error) in
        if let error = error {
          print("❌ Error checking existing token: \(error)")
          return
        }
        
        if let documents = querySnapshot?.documents, !documents.isEmpty {
          // Update existing token
          let docId = documents[0].documentID
          db.collection("fcm_tokens").document(docId).updateData([
            "userId": userId,
            "active": true,
            "updatedAt": FieldValue.serverTimestamp(),
            "lastUsedAt": FieldValue.serverTimestamp()
          ]) { error in
            if let error = error {
              print("❌ Error updating FCM token: \(error)")
            } else {
              print("✅ FCM token updated in fcm_tokens collection")
            }
          }
        } else {
          // Create new token document
          db.collection("fcm_tokens").addDocument(data: tokenData) { error in
            if let error = error {
              print("❌ Error saving FCM token: \(error)")
            } else {
              print("✅ FCM token saved to fcm_tokens collection")
            }
          }
        }
      }
    
    // Also save FCM token to user's document in users collection
    let userData: [String: Any] = [
      "fcm_token": token,
      "fcm_token_updated_at": FieldValue.serverTimestamp(),
      "fcm_token_platform": "ios",
      "updated_at": FieldValue.serverTimestamp()
    ]
    
    db.collection("users").document(userId).updateData(userData) { error in
      if let error = error {
        // If update fails, try set with merge (in case document doesn't exist)
        db.collection("users").document(userId).setData(userData, merge: true) { setError in
          if let setError = setError {
            print("❌ Error saving FCM token to user document: \(setError)")
          } else {
            print("✅ FCM token saved to user document in users collection")
          }
        }
      } else {
        print("✅ FCM token saved to user document in users collection")
      }
    }
  }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate {
  // Handle notifications when app is in foreground
  override func userNotificationCenter(_ center: UNUserNotificationCenter,
                            willPresent notification: UNNotification,
                            withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    let userInfo = notification.request.content.userInfo
    print("📱 Foreground notification received: \(userInfo)")
    
    // Show notification even when app is in foreground
    completionHandler([[.alert, .badge, .sound]])
  }
  
  // Handle notification tap
  override func userNotificationCenter(_ center: UNUserNotificationCenter,
                            didReceive response: UNNotificationResponse,
                            withCompletionHandler completionHandler: @escaping () -> Void) {
    let userInfo = response.notification.request.content.userInfo
    print("📱 Notification tapped: \(userInfo)")
    
    // Handle notification tap - you can add navigation logic here
    completionHandler()
  }
}
