package com.muscleup.muscleup

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.SharedPreferences
import android.os.Build
import android.os.Bundle
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.google.firebase.messaging.FirebaseMessaging
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.FieldValue
import com.google.firebase.firestore.SetOptions
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL_ID = "fcm_notifications"
    private val CHANNEL_NAME = "FCM Notifications"
    private val CHANNEL_DESCRIPTION = "Firebase Cloud Messaging notifications"
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        Log.d("MainActivity", "🚀 MainActivity: onCreate called")
        
        // Initialize FCM
        initializeFCM()
        
        // Create notification channel
        createNotificationChannel()
    }
    
    override fun onPostResume() {
        super.onPostResume()
        
        // Try to save pending FCM token if user is now authenticated
        savePendingFCMToken()
        
        // Also try to save current token if user is authenticated
        FirebaseMessaging.getInstance().token.addOnCompleteListener { task ->
            if (task.isSuccessful) {
                task.result?.let { token ->
                    val userId = FirebaseAuth.getInstance().currentUser?.uid
                    if (userId != null) {
                        Log.d("MainActivity", "💾 User authenticated, saving FCM token...")
                        saveFCMTokenToFirestore(token)
                    }
                }
            }
        }
        
        // Set up method channel for Flutter communication after Flutter engine is ready
        setupMethodChannel()
    }
    
    private fun initializeFCM() {
        try {
            Log.d("MainActivity", "🔥 Initializing FCM...")
            
            // Get FCM token
            FirebaseMessaging.getInstance().token.addOnCompleteListener { task ->
                if (!task.isSuccessful) {
                    Log.e("MainActivity", "❌ Failed to get FCM token: ${task.exception}")
                    return@addOnCompleteListener
                }
                
                // Get new FCM registration token
                val token = task.result
                Log.d("MainActivity", "✅ FCM Token: $token")
                Log.d("MainActivity", "📱 Token length: ${token?.length}")
                
                // Save token to Firestore
                token?.let { saveFCMTokenToFirestore(it) }
                
                // Send token to Flutter if needed
                sendTokenToFlutter(token)
            }
            
            Log.d("MainActivity", "✅ FCM initialized successfully")
            
        } catch (e: Exception) {
            Log.e("MainActivity", "❌ Error initializing FCM: ${e.message}")
        }
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Log.d("MainActivity", "📱 Creating notification channel...")
            
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = CHANNEL_DESCRIPTION
                enableLights(true)
                enableVibration(true)
                setShowBadge(true)
            }
            
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
            
            Log.d("MainActivity", "✅ Notification channel created")
        }
    }
    
    private fun setupMethodChannel() {
        val flutterEngine = flutterEngine
        if (flutterEngine == null) {
            Log.w("MainActivity", "⚠️ Flutter engine not ready, skipping method channel setup")
            return
        }
        
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "fcm_channel")
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getFCMToken" -> {
                    FirebaseMessaging.getInstance().token.addOnCompleteListener { task ->
                        if (task.isSuccessful) {
                            result.success(task.result)
                        } else {
                            result.error("TOKEN_ERROR", "Failed to get FCM token", task.exception)
                        }
                    }
                }
                "saveFCMToken" -> {
                    // Save FCM token to Firestore (called from Flutter after login)
                    FirebaseMessaging.getInstance().token.addOnCompleteListener { task ->
                        if (task.isSuccessful) {
                            task.result?.let { token ->
                                saveFCMTokenToFirestore(token)
                                result.success("Token save initiated")
                            } ?: run {
                                result.error("TOKEN_ERROR", "Token is null", null)
                            }
                        } else {
                            result.error("TOKEN_ERROR", "Failed to get FCM token", task.exception)
                        }
                    }
                }
                "showLocalNotification" -> {
                    val title = call.argument<String>("title") ?: "Notification"
                    val body = call.argument<String>("body") ?: "You have a new message"
                    showLocalNotification(title, body)
                    result.success("Notification shown")
                }
                "testFCM" -> {
                    testFCMFunctionality()
                    result.success("FCM test completed")
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    private fun sendTokenToFlutter(token: String?) {
        // You can send the token to Flutter via method channel if needed
        Log.d("MainActivity", "📤 Sending FCM token to Flutter: $token")
    }
    
    private fun showLocalNotification(title: String, body: String) {
        try {
            Log.d("MainActivity", "📱 Showing local notification: $title")
            
            val notification = NotificationCompat.Builder(this, CHANNEL_ID)
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .setContentTitle(title)
                .setContentText(body)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setAutoCancel(true)
                .build()
            
            with(NotificationManagerCompat.from(this)) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    if (androidx.core.app.ActivityCompat.checkSelfPermission(
                            this@MainActivity,
                            android.Manifest.permission.POST_NOTIFICATIONS
                        ) != android.content.pm.PackageManager.PERMISSION_GRANTED
                    ) {
                        Log.e("MainActivity", "❌ Notification permission not granted")
                        return
                    }
                }
                notify(1, notification)
            }
            
            Log.d("MainActivity", "✅ Local notification shown successfully")
            
        } catch (e: Exception) {
            Log.e("MainActivity", "❌ Error showing local notification: ${e.message}")
        }
    }
    
    private fun saveFCMTokenToFirestore(token: String) {
        val userId = FirebaseAuth.getInstance().currentUser?.uid
        
        if (userId == null) {
            Log.w("MainActivity", "⚠️ No authenticated user, skipping FCM token save")
            Log.d("MainActivity", "💾 Storing FCM token locally for later save")
            // Store token in SharedPreferences so we can save it later when user logs in
            val prefs = getSharedPreferences("fcm_prefs", Context.MODE_PRIVATE)
            prefs.edit().putString("pending_fcm_token", token).apply()
            return
        }
        
        Log.d("MainActivity", "💾 Saving FCM token to Firestore for user: $userId")
        
        val db = FirebaseFirestore.getInstance()
        
        // Use coroutine scope for async operations
        CoroutineScope(Dispatchers.IO).launch {
            try {
                // Get device info
                val deviceModel = "${Build.MANUFACTURER} ${Build.MODEL}"
                val appVersion = try {
                    val packageInfo = applicationContext.packageManager.getPackageInfo(applicationContext.packageName, 0)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        packageInfo.longVersionCode.toString()
                    } else {
                        @Suppress("DEPRECATION")
                        packageInfo.versionCode.toString()
                    }
                } catch (e: Exception) {
                    "unknown"
                }
                
                val tokenData = hashMapOf(
                    "token" to token,
                    "userId" to userId,
                    "platform" to "android",
                    "appVersion" to appVersion,
                    "deviceModel" to deviceModel,
                    "androidVersion" to Build.VERSION.SDK_INT.toString(),
                    "active" to true,
                    "createdAt" to FieldValue.serverTimestamp(),
                    "updatedAt" to FieldValue.serverTimestamp(),
                    "lastUsedAt" to FieldValue.serverTimestamp()
                )
                
                // Check if token already exists
                val querySnapshot = db.collection("fcm_tokens")
                    .whereEqualTo("token", token)
                    .get()
                    .await()
                
                if (!querySnapshot.isEmpty) {
                    // Update existing token
                    val docId = querySnapshot.documents.first().id
                    db.collection("fcm_tokens").document(docId)
                        .update(
                            mapOf(
                                "userId" to userId,
                                "active" to true,
                                "updatedAt" to FieldValue.serverTimestamp(),
                                "lastUsedAt" to FieldValue.serverTimestamp()
                            )
                        )
                        .await()
                    
                    Log.d("MainActivity", "✅ FCM token updated in fcm_tokens collection")
                } else {
                    // Create new token document
                    db.collection("fcm_tokens")
                        .add(tokenData)
                        .await()
                    
                    Log.d("MainActivity", "✅ FCM token saved to fcm_tokens collection")
                }
                
                // Also save FCM token to user's document in users collection
                val userData = hashMapOf(
                    "fcm_token" to token,
                    "fcm_token_updated_at" to FieldValue.serverTimestamp(),
                    "fcm_token_platform" to "android",
                    "updated_at" to FieldValue.serverTimestamp()
                )
                
                try {
                    db.collection("users").document(userId)
                        .update(userData)
                        .await()
                    Log.d("MainActivity", "✅ FCM token saved to user document in users collection")
                } catch (e: Exception) {
                    // If update fails, try set with merge (in case document doesn't exist)
                    try {
                        db.collection("users").document(userId)
                            .set(userData, SetOptions.merge())
                            .await()
                        Log.d("MainActivity", "✅ FCM token saved to user document in users collection (via set)")
                    } catch (setError: Exception) {
                        Log.e("MainActivity", "❌ Error saving FCM token to user document: ${setError.message}")
                    }
                }
                
                // Clear pending token from SharedPreferences if it exists
                val prefs = getSharedPreferences("fcm_prefs", Context.MODE_PRIVATE)
                if (prefs.contains("pending_fcm_token")) {
                    prefs.edit().remove("pending_fcm_token").apply()
                    Log.d("MainActivity", "✅ Cleared pending FCM token from local storage")
                }
                
            } catch (e: Exception) {
                Log.e("MainActivity", "❌ Error saving FCM token to Firestore: ${e.message}")
                e.printStackTrace()
            }
        }
    }
    
    // Method to save pending token when user logs in
    fun savePendingFCMToken() {
        val prefs = getSharedPreferences("fcm_prefs", Context.MODE_PRIVATE)
        val pendingToken = prefs.getString("pending_fcm_token", null)
        if (pendingToken != null) {
            Log.d("MainActivity", "💾 Found pending FCM token, saving now...")
            saveFCMTokenToFirestore(pendingToken)
        }
    }
    
    private fun testFCMFunctionality() {
        Log.d("MainActivity", "🧪 Testing FCM functionality...")
        
        // Test local notification
        showLocalNotification(
            "FCM Test - Android",
            "If you see this, Android FCM is working!"
        )
        
        // Get and log FCM token
        FirebaseMessaging.getInstance().token.addOnCompleteListener { task ->
            if (task.isSuccessful) {
                val token = task.result
                Log.d("MainActivity", "✅ FCM Test - Token: $token")
            } else {
                Log.e("MainActivity", "❌ FCM Test - Failed to get token: ${task.exception}")
            }
        }
        
        Log.d("MainActivity", "✅ FCM functionality test completed")
    }
}
