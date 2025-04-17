package com.example.otp_sender

import android.app.ActivityManager
import android.content.Context
import android.telephony.SmsManager
import android.util.Log
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

class MyFirebaseMessagingService : FirebaseMessagingService() {

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        if (isAppInForeground()) {
            Log.d("FCMService", "App is in foreground, skipping SMS")
            return // ✅ Skip sending if app is already handling it in Dart
        }

        val phoneNumber = remoteMessage.data["phone_number"]
        val otp = remoteMessage.data["otp"]
        if (phoneNumber != null && otp != null) {
            val message = "Your verification code is $otp"
            try {
                val smsManager = SmsManager.getDefault()
                smsManager.sendTextMessage(phoneNumber, null, message, null, null)
                Log.d("FCMService", "SMS sent to $phoneNumber: $message")
            } catch (e: Exception) {
                Log.e("FCMService", "Failed to send SMS: ${e.message}")
            }
        }
    }

    private fun isAppInForeground(): Boolean {
        val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val appProcesses = activityManager.runningAppProcesses ?: return false
        val packageName = packageName

        for (appProcess in appProcesses) {
            if (appProcess.importance == ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND &&
                appProcess.processName == packageName) {
                return true
            }
        }
        return false
    }
}
