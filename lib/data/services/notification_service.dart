import 'dart:async';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:muscleup/firebase_options.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  
  bool _isInitialized = false;
  
  // Method channel for Android native communication
  static const MethodChannel _channel = MethodChannel('fcm_channel');
  
  // Stream controller for notification taps
  final StreamController<Map<String, dynamic>> _notificationTapController =
      StreamController<Map<String, dynamic>>.broadcast();
  
  Stream<Map<String, dynamic>> get onNotificationTap => _notificationTapController.stream;
  
  // Initialize the notification service (Local notifications + FCM)
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    print('🔔 Initializing Notification Service (Local + FCM)...');
    
    // Initialize timezone
    tz_data.initializeTimeZones();
    
    // Android initialization settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS initialization settings
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      requestCriticalPermission: false,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
    );
    
    // Combined initialization settings
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    // Initialize the plugin
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    // Request Android notification permissions (required for Android 13+)
    final androidPlugin = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      print('📱 Android notification permission: ${granted ?? false ? "Granted" : "Denied"}');
    }
    
    // Initialize FCM
    await _initializeFCM();
    
    _isInitialized = true;
    print('✅ Notification Service initialized successfully (Local + FCM)');
  }
  
  // Initialize Firebase Cloud Messaging
  Future<void> _initializeFCM() async {
    try {
      print('🔥 Initializing FCM...');
      
      // Request notification permissions
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      
      print('📱 FCM Permission status: ${settings.authorizationStatus}');
      
      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      
      // Handle notification taps when app is opened from terminated state
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
      
      // Check if app was opened from a notification (terminated state)
      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }
      
      // Handle token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        print('🔄 FCM token refreshed: $newToken');
        // Token is automatically saved by native code (AppDelegate/MainActivity)
      });
      
      // Get current FCM token
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        print('✅ FCM token obtained: ${token.substring(0, 20)}...');
      }
      
      print('✅ FCM initialized successfully');
    } catch (e) {
      print('❌ Error initializing FCM: $e');
    }
  }
  
  // Handle foreground FCM messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('📱 Foreground FCM message received: ${message.messageId}');
    print('📝 Title: ${message.notification?.title}');
    print('📝 Body: ${message.notification?.body}');
    print('📦 Data: ${message.data}');
    
    // Save notification to Firestore notifications collection for dashboard display
    await _saveNotificationToFirestore(message);
    
    // Check if this is a workout notification from trainer (more flexible detection)
    final data = message.data;
    final isTrainerWorkout = data['type'] == 'workout' || 
                            data['workout_id'] != null || 
                            data['from_trainer'] == 'true' ||
                            data['from_trainer'] == true ||
                            data.containsKey('workout_title') ||
                            data.containsKey('workout_type') ||
                            (message.notification?.title?.contains('אימון') ?? false) ||
                            (message.notification?.body?.contains('אימון') ?? false);
    
    if (isTrainerWorkout) {
      print('💪 Detected trainer workout notification, saving to workouts...');
      await _saveTrainerWorkoutFromNotification(message);
    }
    
    // Show local notification when app is in foreground
    if (message.notification != null) {
      await showNotification(
        title: message.notification!.title ?? 'Notification',
        body: message.notification!.body ?? '',
        data: message.data,
      );
    }
  }
  
  // Save notification to Firestore notifications collection
  Future<void> _saveNotificationToFirestore(RemoteMessage message) async {
    try {
      final auth = FirebaseAuth.instance;
      if (auth.currentUser == null) {
        print('⚠️ No authenticated user, cannot save notification');
        return;
      }
      
      final firestore = FirebaseFirestore.instance;
      final user = await firestore.collection('users').doc(auth.currentUser!.uid).get();
      if (!user.exists) {
        print('⚠️ User document not found');
        return;
      }
      
      final userData = user.data()!;
      final userEmail = userData['email'] ?? auth.currentUser!.email;
      
      if (userEmail == null) {
        print('⚠️ User email not found');
        return;
      }
      
      final notificationData = {
        'title': message.notification?.title ?? message.data['title'] ?? 'התראה',
        'body': message.notification?.body ?? message.data['body'] ?? '',
        'name': message.notification?.body ?? message.data['body'] ?? '',
        'type': message.data['type'] ?? 'general',
        'user_email': userEmail,
        'fcm_message_id': message.messageId,
        'data': message.data,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
        'source': message.data['source'] ?? message.data['sentFrom'] ?? 'fcm',
      };
      
      // Check if notification already exists (by FCM message ID)
      if (message.messageId != null) {
        final existing = await firestore
            .collection('notifications')
            .where('fcm_message_id', isEqualTo: message.messageId)
            .where('user_email', isEqualTo: userEmail)
            .limit(1)
            .get();
        
        if (existing.docs.isNotEmpty) {
          print('📱 Notification already exists, skipping save');
          return;
        }
      }
      
      await firestore.collection('notifications').add(notificationData);
      print('✅ Saved notification to Firestore: ${message.notification?.title}');
      
    } catch (e) {
      print('❌ Error saving notification to Firestore: $e');
    }
  }
  
  // Save workout from trainer notification
  Future<void> _saveTrainerWorkoutFromNotification(RemoteMessage message) async {
    try {
      print('💪 Saving workout from trainer notification...');
      
      final data = message.data;
      final firestore = FirebaseFirestore.instance;
      final auth = FirebaseAuth.instance;
      
      if (auth.currentUser == null) {
        print('⚠️ No authenticated user, cannot save workout');
        return;
      }
      
      final user = await firestore.collection('users').doc(auth.currentUser!.uid).get();
      if (!user.exists) {
        print('⚠️ User document not found');
        return;
      }
      
      final userData = user.data()!;
      final userEmail = userData['email'] ?? auth.currentUser!.email;
      
      if (userEmail == null) {
        print('⚠️ User email not found');
        return;
      }
      
      // Parse workout data from notification
      final now = DateTime.now();
      final dateString = data['workout_date'] ?? 
                        data['date'] ?? 
                        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      
      // Parse exercises if provided
      List<Map<String, dynamic>> exercises = [];
      if (data['exercises'] != null) {
        try {
          final exercisesData = data['exercises'];
          if (exercisesData is String) {
            // Try to parse JSON string
            exercises = List<Map<String, dynamic>>.from(
              (jsonDecode(exercisesData) as List).map((e) => Map<String, dynamic>.from(e))
            );
          } else if (exercisesData is List) {
            exercises = List<Map<String, dynamic>>.from(
              exercisesData.map((e) => Map<String, dynamic>.from(e))
            );
          }
        } catch (e) {
          print('⚠️ Error parsing exercises: $e');
        }
      }
      
      final workoutData = {
        'date': dateString,
        'workout_type': data['workout_type'] ?? 'אימון מאמן',
        'status': 'פעיל',
        'start_time': now.toIso8601String(),
        'warmup_description': data['warmup_description'] ?? 'חימום כללי - 10 דקות',
        'warmup_duration': int.tryParse(data['warmup_duration']?.toString() ?? '10') ?? 10,
        'warmup_completed': false,
        'exercises': exercises.isNotEmpty ? exercises : [],
        'notes': data['notes'] ?? data['workout_description'] ?? '',
        'total_duration': int.tryParse(data['total_duration']?.toString() ?? '60') ?? 60,
        'created_by': userEmail,
        'coach_workout_title': data['workout_title'] ?? 
                              data['title'] ?? 
                              message.notification?.title ?? 
                              'אימון מאמן',
        'coach_workout_description': data['workout_description'] ?? 
                                    data['body'] ?? 
                                    message.notification?.body ?? '',
        'from_trainer': true,
        'trainer_email': data['trainer_email'] ?? data['from_email'],
        'notification_id': message.messageId,
        'created_at': FieldValue.serverTimestamp(),
      };
      
      // Check if workout already exists (by notification_id or workout_id)
      QuerySnapshot? existingWorkout;
      if (data['workout_id'] != null) {
        existingWorkout = await firestore
            .collection('workouts')
            .where('workout_id', isEqualTo: data['workout_id'])
            .where('created_by', isEqualTo: userEmail)
            .limit(1)
            .get();
      }
      
      // Also check by notification_id
      if (existingWorkout == null || existingWorkout.docs.isEmpty) {
        final byNotificationId = await firestore
            .collection('workouts')
            .where('notification_id', isEqualTo: message.messageId)
            .where('created_by', isEqualTo: userEmail)
            .limit(1)
            .get();
        if (byNotificationId.docs.isNotEmpty) {
          existingWorkout = byNotificationId;
        }
      }
      
      if (existingWorkout != null && existingWorkout.docs.isNotEmpty) {
        // Update existing workout
        await firestore
            .collection('workouts')
            .doc(existingWorkout.docs.first.id)
            .update(workoutData);
        print('✅ Updated existing workout from trainer notification');
      } else {
        // Create new workout
        await firestore.collection('workouts').add(workoutData);
        print('✅ Saved new workout from trainer notification');
      }
      
    } catch (e) {
      print('❌ Error saving workout from notification: $e');
    }
  }
  
  // Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    print('🔔 Notification tapped: ${message.messageId}');
    print('📦 Data: ${message.data}');
    
    // Emit notification tap event
    _notificationTapController.add(message.data);
    
    // You can add navigation logic here based on message.data
    // For example, navigate to a specific screen based on notification type
  }

  // Request notification permissions (only when user explicitly wants to enable notifications)
  Future<bool> requestPermissions() async {
    try {
      print('🔔 Requesting notification permissions...');
      
      // Android permissions
      final androidPlugin = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final androidResult = await androidPlugin.requestNotificationsPermission();
        await androidPlugin.requestExactAlarmsPermission();
        print('📱 Android notification permission result: $androidResult');
      }
      
      // iOS permissions
      final iosPlugin = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (iosPlugin != null) {
        final iosResult = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        print('🍎 iOS notification permission result: $iosResult');
        return iosResult ?? false;
      }
      
      return true;
    } catch (e) {
      print('❌ Error requesting notification permissions: $e');
      return false;
    }
  }
  
  // Start the notification service (local notifications + FCM)
  Future<void> start() async {
    if (!_isInitialized) {
      await initialize();
    }
    print('🚀 Notification service started (Local + FCM)');
  }
  
  // Get FCM token
  Future<String?> getFCMToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      print('❌ Error getting FCM token: $e');
      return null;
    }
  }
  
  // Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('✅ Subscribed to topic: $topic');
    } catch (e) {
      print('❌ Error subscribing to topic: $e');
    }
  }
  
  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      print('❌ Error unsubscribing from topic: $e');
    }
  }
  
  // Show local notification
  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String? imageUrl,
  }) async {
    try {
      print('📱 Showing local notification: $title');
      
      // Android notification details
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'fcm_notifications',
        'FCM Notifications',
        channelDescription: 'Firebase Cloud Messaging notifications',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );
      
      // iOS notification details
      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        badgeNumber: 1,
        attachments: null,
      );
      
      // Combined notification details
      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );
      
      // Show the notification
      await _flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );
      
      print('✅ Local notification shown successfully');
      
    } catch (e) {
      print('❌ Error showing local notification: $e');
    }
  }
  
  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) async {
    print('🔔 Notification tapped: ${response.payload}');
    
    // Get user info for tracking
    String? userId;
    try {
      userId = FirebaseAuth.instance.currentUser?.uid;
    } catch (e) {
      print('Error getting user ID for notification tracking: $e');
    }
    
    // You can add navigation logic here based on the payload
    if (response.payload != null) {
      // Navigate to specific screen based on notification payload
      // This will be handled by the main app
    }
  }
  
  // Schedule a notification for later
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    try {
      print('⏰ Scheduling notification: $title for ${scheduledTime.toString()}');
      
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'fcm_notifications',
        'FCM Notifications',
        channelDescription: 'Firebase Cloud Messaging notifications',
        importance: Importance.high,
        priority: Priority.high,
      );
      
      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );
      
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        platformChannelSpecifics,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      
      print('✅ Notification scheduled successfully');
      
    } catch (e) {
      print('❌ Error scheduling notification: $e');
    }
  }
  
  // Cancel a scheduled notification
  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
    print('🗑️ Cancelled notification: $id');
  }
  
  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
    print('🗑️ Cancelled all notifications');
  }
  
  // Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
  }
  
  // Test local notification functionality
  Future<void> testLocalNotifications() async {
    try {
      print('🧪 Testing local notification functionality...');
      
      await _showLocalNotification(
        id: 999999,
        title: 'Local Notification Test',
        body: 'If you see this, local notifications are working!',
        payload: 'local_test',
      );
      
    } catch (e) {
      print('❌ Error testing local notifications: $e');
    }
  }
  
  // Debug notification service status
  Future<void> debugNotificationStatus() async {
    try {
      print('🔍 === NOTIFICATION SERVICE DEBUG ===');
      print('🔍 Service Initialized: $_isInitialized');
      
      if (!_isInitialized) {
        print('❌ Service not initialized - initializing now...');
        await initialize();
      }
      
      // Test local notification
      print('🧪 Testing local notification...');
      await _showLocalNotification(
        id: 888888,
        title: 'Debug Test',
        body: 'This is a debug notification test',
        payload: 'debug_test',
      );
      
    } catch (e) {
      print('❌ Error in debug: $e');
    }
  }
  
  // Show a notification (can be called from Swift/Kotlin)
  Future<void> showNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _showLocalNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: title,
        body: body,
        payload: data?.toString() ?? '',
      );
    } catch (e) {
      print('❌ Error showing notification: $e');
    }
  }
  
  // === ANDROID NATIVE FCM METHODS ===
  
  // Get FCM token from Android native code
  Future<String?> getAndroidFCMToken() async {
    try {
      print('📱 Requesting FCM token from Android native...');
      final String? token = await _channel.invokeMethod('getFCMToken');
      print('✅ Android FCM Token: $token');
      return token;
    } catch (e) {
      print('❌ Error getting Android FCM token: $e');
      return null;
    }
  }
  
  // Save FCM token to Firestore (Flutter implementation)
  Future<void> saveFCMTokenToFirestore() async {
    try {
      final auth = FirebaseAuth.instance;
      if (auth.currentUser == null) {
        print('⚠️ No authenticated user, cannot save FCM token');
        return;
      }

      final token = await _firebaseMessaging.getToken();
      if (token == null) {
        print('⚠️ FCM token is null, cannot save');
        return;
      }

      print('💾 Saving FCM token to Firestore for user: ${auth.currentUser!.uid}');

      final firestore = FirebaseFirestore.instance;
      final userId = auth.currentUser!.uid;

      // Get user document to get email
      final userDoc = await firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        print('⚠️ User document not found');
        return;
      }

      final userData = userDoc.data()!;
      final userEmail = userData['email'] ?? auth.currentUser!.email;

      // Get device info
      final deviceModel = 'Android Device'; // Can be enhanced with device_info_plus package
      final appVersion = '1.4.1'; // Can be enhanced with package_info_plus

      final tokenData = {
        'token': token,
        'userId': userId,
        'platform': 'android',
        'appVersion': appVersion,
        'deviceModel': deviceModel,
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastUsedAt': FieldValue.serverTimestamp(),
      };

      // Check if token already exists
      final querySnapshot = await firestore
          .collection('fcm_tokens')
          .where('token', isEqualTo: token)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Update existing token
        await firestore
            .collection('fcm_tokens')
            .doc(querySnapshot.docs.first.id)
            .update({
          'userId': userId,
          'active': true,
          'updatedAt': FieldValue.serverTimestamp(),
          'lastUsedAt': FieldValue.serverTimestamp(),
        });
        print('✅ FCM token updated in fcm_tokens collection');
      } else {
        // Create new token document
        await firestore.collection('fcm_tokens').add(tokenData);
        print('✅ FCM token saved to fcm_tokens collection');
      }

      // Also save FCM token to user's document
      final userUpdateData = {
        'fcm_token': token,
        'fcm_token_updated_at': FieldValue.serverTimestamp(),
        'fcm_token_platform': 'android',
        'updated_at': FieldValue.serverTimestamp(),
      };

      try {
        await firestore.collection('users').doc(userId).update(userUpdateData);
        print('✅ FCM token saved to user document in users collection');
      } catch (e) {
        // If update fails, try set with merge
        await firestore
            .collection('users')
            .doc(userId)
            .set(userUpdateData, SetOptions(merge: true));
        print('✅ FCM token saved to user document (via set with merge)');
      }
    } catch (e) {
      print('❌ Error saving FCM token to Firestore: $e');
    }
  }
  
  // Show local notification via Android native code
  Future<void> showAndroidNativeNotification({
    required String title,
    required String body,
  }) async {
    try {
      print('📱 Showing notification via Android native...');
      await _channel.invokeMethod('showLocalNotification', {
        'title': title,
        'body': body,
      });
      print('✅ Android native notification shown');
    } catch (e) {
      print('❌ Error showing Android native notification: $e');
    }
  }
  
  // Test Android FCM functionality
  Future<void> testAndroidFCM() async {
    try {
      await _channel.invokeMethod('testFCM');
    } catch (e) {
      print('❌ Error testing Android FCM: $e');
    }
  }
  
  // Comprehensive FCM test for both platforms
  Future<void> testFCMAllPlatforms() async {
    try {
      print('🧪 === TESTING FCM ON ALL PLATFORMS ===');
      
      // Test local notifications first
      await testLocalNotifications();
      
      // Test Android native FCM if on Android
      try {
        await testAndroidFCM();
      } catch (e) {
        print('⚠️ Android FCM test not available: $e');
      }
      
    } catch (e) {
      print('❌ Error testing FCM: $e');
    }
  }
  
  // Dispose resources
  void dispose() {
    _notificationTapController.close();
  }
}

// Top-level function for handling background messages
// This must be a top-level function, not a class method
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase in background isolate if needed
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('🔥 Firebase initialized in background handler');
    }
  } catch (e) {
    print('⚠️ Firebase already initialized or error: $e');
  }
  
  print('📱 Background FCM message received: ${message.messageId}');
  print('📝 Title: ${message.notification?.title}');
  print('📝 Body: ${message.notification?.body}');
  print('📦 Data: ${message.data}');
  
  // Check if this is a workout notification from trainer
  final data = message.data;
  final isTrainerWorkout = data['type'] == 'workout' || 
                          data['workout_id'] != null || 
                          data['from_trainer'] == 'true' ||
                          data['from_trainer'] == true ||
                          data.containsKey('workout_title') ||
                          data.containsKey('workout_type') ||
                          (message.notification?.title?.contains('אימון') ?? false) ||
                          (message.notification?.body?.contains('אימון') ?? false);
  
  // Save notification to Firestore notifications collection for dashboard display
  await _saveNotificationToFirestoreBackground(message);
  
  if (isTrainerWorkout) {
    print('💪 Detected trainer workout notification, saving to workouts...');
    await _saveTrainerWorkoutFromNotificationBackground(message);
  }
}

// Save notification to Firestore (background handler version)
Future<void> _saveNotificationToFirestoreBackground(RemoteMessage message) async {
  try {
    final auth = FirebaseAuth.instance;
    
    // Wait a bit for auth to be ready
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (auth.currentUser == null) {
      print('⚠️ No authenticated user, cannot save notification');
      return;
    }
    
    final firestore = FirebaseFirestore.instance;
    final user = await firestore.collection('users').doc(auth.currentUser!.uid).get();
    if (!user.exists) {
      print('⚠️ User document not found');
      return;
    }
    
    final userData = user.data()!;
    final userEmail = userData['email'] ?? auth.currentUser!.email;
    
    if (userEmail == null) {
      print('⚠️ User email not found');
      return;
    }
    
    final notificationData = {
      'title': message.notification?.title ?? message.data['title'] ?? 'התראה',
      'body': message.notification?.body ?? message.data['body'] ?? '',
      'name': message.notification?.body ?? message.data['body'] ?? '',
      'type': message.data['type'] ?? 'general',
      'user_email': userEmail,
      'fcm_message_id': message.messageId,
      'data': message.data,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
      'source': message.data['source'] ?? message.data['sentFrom'] ?? 'fcm',
    };
    
    // Check if notification already exists (by FCM message ID)
    if (message.messageId != null) {
      final existing = await firestore
          .collection('notifications')
          .where('fcm_message_id', isEqualTo: message.messageId)
          .where('user_email', isEqualTo: userEmail)
          .limit(1)
          .get();
      
      if (existing.docs.isNotEmpty) {
        print('📱 Notification already exists, skipping save');
        return;
      }
    }
    
    await firestore.collection('notifications').add(notificationData);
    print('✅ Saved notification to Firestore (background): ${message.notification?.title}');
    
  } catch (e) {
    print('❌ Error saving notification to Firestore (background): $e');
  }
}

// Save workout from trainer notification (background handler version)
Future<void> _saveTrainerWorkoutFromNotificationBackground(RemoteMessage message) async {
  try {
    print('💪 Saving workout from trainer notification (background)...');
    
    final data = message.data;
    final firestore = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;
    
    // Wait a bit for auth to be ready
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (auth.currentUser == null) {
      print('⚠️ No authenticated user, cannot save workout');
      return;
    }
    
    final user = await firestore.collection('users').doc(auth.currentUser!.uid).get();
    if (!user.exists) {
      print('⚠️ User document not found');
      return;
    }
    
    final userData = user.data()!;
    final userEmail = userData['email'] ?? auth.currentUser!.email;
    
    if (userEmail == null) {
      print('⚠️ User email not found');
      return;
    }
    
    // Parse workout data from notification
    final now = DateTime.now();
    final dateString = data['workout_date'] ?? 
                      data['date'] ?? 
                      '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    
    // Parse exercises if provided
    List<Map<String, dynamic>> exercises = [];
    if (data['exercises'] != null) {
      try {
        final exercisesData = data['exercises'];
        if (exercisesData is String) {
          exercises = List<Map<String, dynamic>>.from(
            (jsonDecode(exercisesData) as List).map((e) => Map<String, dynamic>.from(e))
          );
        } else if (exercisesData is List) {
          exercises = List<Map<String, dynamic>>.from(
            exercisesData.map((e) => Map<String, dynamic>.from(e))
          );
        }
      } catch (e) {
        print('⚠️ Error parsing exercises: $e');
      }
    }
    
    final workoutData = {
      'date': dateString,
      'workout_type': data['workout_type'] ?? 'אימון מאמן',
      'status': 'פעיל',
      'start_time': now.toIso8601String(),
      'warmup_description': data['warmup_description'] ?? 'חימום כללי - 10 דקות',
      'warmup_duration': int.tryParse(data['warmup_duration']?.toString() ?? '10') ?? 10,
      'warmup_completed': false,
      'exercises': exercises.isNotEmpty ? exercises : [],
      'notes': data['notes'] ?? data['workout_description'] ?? '',
      'total_duration': int.tryParse(data['total_duration']?.toString() ?? '60') ?? 60,
      'created_by': userEmail,
      'coach_workout_title': data['workout_title'] ?? 
                            data['title'] ?? 
                            message.notification?.title ?? 
                            'אימון מאמן',
      'coach_workout_description': data['workout_description'] ?? 
                                  data['body'] ?? 
                                  message.notification?.body ?? '',
      'from_trainer': true,
      'trainer_email': data['trainer_email'] ?? data['from_email'],
      'notification_id': message.messageId,
      'created_at': FieldValue.serverTimestamp(),
    };
    
    // Check if workout already exists
    QuerySnapshot? existingWorkout;
    if (data['workout_id'] != null) {
      existingWorkout = await firestore
          .collection('workouts')
          .where('workout_id', isEqualTo: data['workout_id'])
          .where('created_by', isEqualTo: userEmail)
          .limit(1)
          .get();
    }
    
    // Also check by notification_id
    if (existingWorkout == null || existingWorkout.docs.isEmpty) {
      final byNotificationId = await firestore
          .collection('workouts')
          .where('notification_id', isEqualTo: message.messageId)
          .where('created_by', isEqualTo: userEmail)
          .limit(1)
          .get();
      if (byNotificationId.docs.isNotEmpty) {
        existingWorkout = byNotificationId;
      }
    }
    
    if (existingWorkout != null && existingWorkout.docs.isNotEmpty) {
      await firestore
          .collection('workouts')
          .doc(existingWorkout.docs.first.id)
          .update(workoutData);
      print('✅ Updated existing workout from trainer notification (background)');
    } else {
      await firestore.collection('workouts').add(workoutData);
      print('✅ Saved new workout from trainer notification (background)');
    }
    
  } catch (e) {
    print('❌ Error saving workout from notification (background): $e');
    print('❌ Stack trace: ${StackTrace.current}');
  }
}

