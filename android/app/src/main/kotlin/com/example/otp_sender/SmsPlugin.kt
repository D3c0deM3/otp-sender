package com.example.otp_sender

import android.content.Context
import android.telephony.SmsManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class SmsPlugin : FlutterPlugin {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "com.example.otp_sender/sms")
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "sendSms" -> {
                    val phoneNumber = call.argument<String>("phoneNumber")
                    val message = call.argument<String>("message")
                    if (phoneNumber != null && message != null) {
                        if (phoneNumber.isEmpty()) {
                            result.error("INVALID_PHONE", "Phone number is empty", null)
                            return@setMethodCallHandler
                        }
                        // Basic validation: ensure number starts with + and has digits
                        if (!phoneNumber.startsWith("+") || !phoneNumber.drop(1).all { it.isDigit() }) {
                            result.error("INVALID_PHONE", "Phone number must start with + and contain only digits", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val smsManager = SmsManager.getDefault()
                            smsManager.sendTextMessage(phoneNumber, null, message, null, null)
                            result.success(true)
                        } catch (e: IllegalArgumentException) {
                            result.error("SMS_ERROR", "Invalid phone number format: ${e.message}", null)
                        } catch (e: SecurityException) {
                            result.error("SMS_ERROR", "SMS permission not granted: ${e.message}", null)
                        } catch (e: Exception) {
                            result.error("SMS_ERROR", "Failed to send SMS: ${e.message}", null)
                        }
                    } else {
                        result.error("INVALID_ARGS", "Phone number or message is null", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}