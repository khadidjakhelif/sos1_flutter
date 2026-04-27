package com.example.sos1

import android.Manifest
import android.content.pm.PackageManager
import android.telephony.SmsManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.sos1.sms/send"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "sendSms" -> {
                        val phoneNumber = call.argument<String>("phone")
                        val message = call.argument<String>("message")

                        if (phoneNumber == null || message == null) {
                            result.error("INVALID_ARGS", "Phone and message required", null)
                            return@setMethodCallHandler
                        }

                        if (ContextCompat.checkSelfPermission(this, Manifest.permission.SEND_SMS)
                            != PackageManager.PERMISSION_GRANTED
                        ) {
                            result.error("PERMISSION_DENIED", "SMS permission not granted", null)
                            return@setMethodCallHandler
                        }

                        try {
                            val smsManager = SmsManager.getDefault()
                            val parts = smsManager.divideMessage(message)
                            smsManager.sendMultipartTextMessage(
                                phoneNumber, null, parts, null, null
                            )
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("SMS_FAILED", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
