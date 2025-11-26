package com.muscleup.muscleup

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.FieldValue
import com.google.firebase.firestore.SetOptions
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await

class MyFirebaseMessagingService : FirebaseMessagingService() {
    
    private val CHANNEL_ID = "fcm_notifications"
    private val CHANNEL_NAME = "FCM Notifications"
    private val CHANNEL_DESCRIPTION = "Firebase Cloud Messaging notifications"
    
    override fun onCreate() {
        super.onCreate()
        Log.d("MyFirebaseMessagingService", "🚀 FCM Service created")
        createNotificationChannel()
    }
    
    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)
        
        Log.d("MyFirebaseMessagingService", "📨 FCM Message received: ${remoteMessage.messageId}")
        
        // Handle data payload
        if (remoteMessage.data.isNotEmpty()) {
            Log.d("MyFirebaseMessagingService", "📊 Message data payload: ${remoteMessage.data}")
        }
        
        // Handle notification payload
        remoteMessage.notification?.let { notification ->
            Log.d("MyFirebaseMessagingService", "📱 Notification title: ${notification.title}")
            Log.d("MyFirebaseMessagingService", "📱 Notification body: ${notification.body}")
            
            // Show notification
            showNotification(
                title = notification.title ?: "New Notification",
                body = notification.body ?: "You have a new message",
                data = remoteMessage.data
            )
        }
        
        // Handle custom data-only messages
        if (remoteMessage.notification == null && remoteMessage.data.isNotEmpty()) {
            Log.d("MyFirebaseMessagingService", "📊 Data-only message received")
            
            val title = remoteMessage.data["title"] ?: "New Message"
            val body = remoteMessage.data["body"] ?: "You have a new message"
            
            showNotification(title, body, remoteMessage.data)
        }
    }
    
    override fun onNewToken(token: String) {
        super.onNewToken(token)
        
        Log.d(TAG, "🔄 FCM Token refreshed: $token")
        Log.d(TAG, "📱 Token length: ${token.length}")
        
        // Save token to Firestore
        saveFCMTokenToFirestore(token)
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Log.d("MyFirebaseMessagingService", "📱 Creating notification channel...")
            
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
            
            Log.d("MyFirebaseMessagingService", "✅ Notification channel created")
        }
    }
    
    private fun showNotification(title: String, body: String, data: Map<String, String> = emptyMap()) {
        try {
            Log.d("MyFirebaseMessagingService", "📱 Showing notification: $title")
            
            val builder = NotificationCompat.Builder(applicationContext, CHANNEL_ID)
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .setContentTitle(title)
                .setContentText(body)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setAutoCancel(true)
                .setDefaults(NotificationCompat.DEFAULT_ALL)
            
            val notification = builder.build()
            
            val notificationManager = applicationContext.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.notify(System.currentTimeMillis().toInt(), notification)
            
            Log.d("MyFirebaseMessagingService", "✅ Notification shown successfully")
            
        } catch (e: Exception) {
            Log.e("MyFirebaseMessagingService", "❌ Error showing notification: ${e.message}")
        }
    }
    
    private fun saveFCMTokenToFirestore(token: String) {
        val userId = FirebaseAuth.getInstance().currentUser?.uid
        
        if (userId == null) {
            Log.w(TAG, "⚠️ No authenticated user, skipping FCM token save")
            return
        }
        
        Log.d(TAG, "💾 Saving FCM token to Firestore for user: $userId")
        
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
                    
                    Log.d(TAG, "✅ FCM token updated in fcm_tokens collection")
                } else {
                    // Create new token document
                    db.collection("fcm_tokens")
                        .add(tokenData)
                        .await()
                    
                    Log.d(TAG, "✅ FCM token saved to fcm_tokens collection")
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
                    Log.d(TAG, "✅ FCM token saved to user document in users collection")
                } catch (e: Exception) {
                    // If update fails, try set with merge (in case document doesn't exist)
                    try {
                        db.collection("users").document(userId)
                            .set(userData, SetOptions.merge())
                            .await()
                        Log.d(TAG, "✅ FCM token saved to user document in users collection (via set)")
                    } catch (setError: Exception) {
                        Log.e(TAG, "❌ Error saving FCM token to user document: ${setError.message}")
                    }
                }
                
            } catch (e: Exception) {
                Log.e(TAG, "❌ Error saving FCM token to Firestore: ${e.message}")
            }
        }
    }
    
    companion object {
        private const val TAG = "MyFirebaseMessagingService"
    }
}

