package com.example.voice_keyword_recorder

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "android_foreground_service"
    private lateinit var methodChannel: MethodChannel
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "startKeywordDetection" -> {
                    startKeywordDetectionService(call.arguments as Map<String, Any>, result)
                }
                "stopKeywordDetection" -> {
                    stopKeywordDetectionService(result)
                }
                "updateNotification" -> {
                    updateNotification(call.arguments as Map<String, Any>, result)
                }
                "isServiceRunning" -> {
                    result.success(KeywordDetectionService.isRunning)
                }
                "requestBatteryOptimization" -> {
                    requestBatteryOptimizationExclusion(result)
                }
                "isBatteryOptimizationIgnored" -> {
                    result.success(isBatteryOptimizationIgnored())
                }
                "configurePowerManagement" -> {
                    configurePowerManagement(call.arguments as Map<String, Any>, result)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // Create notification channel
        createNotificationChannel()
    }
    
    private fun startKeywordDetectionService(arguments: Map<String, Any>, result: MethodChannel.Result) {
        try {
            val intent = Intent(this, KeywordDetectionService::class.java).apply {
                putExtra("notificationTitle", arguments["notificationTitle"] as String)
                putExtra("notificationText", arguments["notificationText"] as String)
                putExtra("channelId", arguments["channelId"] as String)
            }
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(intent)
            } else {
                startService(intent)
            }
            
            result.success(true)
        } catch (e: Exception) {
            result.error("SERVICE_ERROR", "Failed to start service: ${e.message}", null)
        }
    }
    
    private fun stopKeywordDetectionService(result: MethodChannel.Result) {
        try {
            val intent = Intent(this, KeywordDetectionService::class.java)
            stopService(intent)
            result.success(true)
        } catch (e: Exception) {
            result.error("SERVICE_ERROR", "Failed to stop service: ${e.message}", null)
        }
    }
    
    private fun updateNotification(arguments: Map<String, Any>, result: MethodChannel.Result) {
        try {
            KeywordDetectionService.updateNotification(
                this,
                arguments["title"] as String,
                arguments["text"] as String,
                arguments["action"] as String?
            )
            result.success(null)
        } catch (e: Exception) {
            result.error("NOTIFICATION_ERROR", "Failed to update notification: ${e.message}", null)
        }
    }
    
    private fun requestBatteryOptimizationExclusion(result: MethodChannel.Result) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
                if (!powerManager.isIgnoringBatteryOptimizations(packageName)) {
                    val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                        data = Uri.parse("package:$packageName")
                    }
                    startActivity(intent)
                }
            }
            result.success(true)
        } catch (e: Exception) {
            result.error("BATTERY_ERROR", "Failed to request battery optimization: ${e.message}", null)
        }
    }
    
    private fun isBatteryOptimizationIgnored(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
            powerManager.isIgnoringBatteryOptimizations(packageName)
        } else {
            true
        }
    }
    
    private fun configurePowerManagement(arguments: Map<String, Any>, result: MethodChannel.Result) {
        try {
            // Power management configuration is handled in the service
            result.success(null)
        } catch (e: Exception) {
            result.error("POWER_ERROR", "Failed to configure power management: ${e.message}", null)
        }
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "keyword_detection",
                "Keyword Detection",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Continuous keyword detection service"
                setShowBadge(false)
            }
            
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
}
