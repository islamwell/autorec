package com.example.voice_keyword_recorder

import android.app.*
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import androidx.core.app.NotificationCompat
import io.flutter.plugin.common.MethodChannel

class KeywordDetectionService : Service() {
    companion object {
        private const val NOTIFICATION_ID = 1001
        private const val CHANNEL_ID = "keyword_detection"
        var isRunning = false
            private set
        
        fun updateNotification(context: Context, title: String, text: String, action: String?) {
            if (!isRunning) return
            
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val notification = createNotification(context, title, text, action)
            notificationManager.notify(NOTIFICATION_ID, notification)
        }
        
        private fun createNotification(context: Context, title: String, text: String, action: String?): Notification {
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            }
            val pendingIntent = PendingIntent.getActivity(
                context, 0, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            
            val builder = NotificationCompat.Builder(context, CHANNEL_ID)
                .setContentTitle(title)
                .setContentText(text)
                .setSmallIcon(android.R.drawable.ic_media_play)
                .setContentIntent(pendingIntent)
                .setOngoing(true)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .setCategory(NotificationCompat.CATEGORY_SERVICE)
            
            action?.let {
                builder.setSubText(it)
            }
            
            return builder.build()
        }
    }
    
    private var wakeLock: PowerManager.WakeLock? = null
    private var notificationTitle = "Voice Keyword Recorder"
    private var notificationText = "Listening for your keyword..."
    
    override fun onCreate() {
        super.onCreate()
        isRunning = true
        
        // Acquire wake lock for background processing
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "VoiceKeywordRecorder::KeywordDetectionWakeLock"
        )
        wakeLock?.acquire(10*60*1000L /*10 minutes*/)
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        intent?.let {
            notificationTitle = it.getStringExtra("notificationTitle") ?: notificationTitle
            notificationText = it.getStringExtra("notificationText") ?: notificationText
        }
        
        val notification = createNotification(this, notificationTitle, notificationText, null)
        startForeground(NOTIFICATION_ID, notification)
        
        // Start keyword detection logic here
        startKeywordDetection()
        
        return START_STICKY // Restart service if killed by system
    }
    
    override fun onDestroy() {
        super.onDestroy()
        isRunning = false
        
        // Release wake lock
        wakeLock?.let {
            if (it.isHeld) {
                it.release()
            }
        }
        
        // Stop keyword detection
        stopKeywordDetection()
        
        // Stop foreground service
        stopForeground(STOP_FOREGROUND_REMOVE)
    }
    
    override fun onBind(intent: Intent?): IBinder? {
        return null
    }
    
    private fun startKeywordDetection() {
        // This would integrate with the Flutter keyword detection service
        // For now, we'll just update the notification to show it's active
        updateNotification(this, notificationTitle, "Active - Listening for keywords", "Monitoring")
        
        // In a real implementation, this would:
        // 1. Set up audio recording in background
        // 2. Process audio for keyword detection
        // 3. Communicate with Flutter app when keyword is detected
    }
    
    private fun stopKeywordDetection() {
        // Stop any ongoing keyword detection processes
        updateNotification(this, notificationTitle, "Stopping...", "Shutting down")
    }
    
    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)
        // Keep service running even when app is removed from recent apps
        val restartServiceIntent = Intent(applicationContext, KeywordDetectionService::class.java).also {
            it.setPackage(packageName)
        }
        val restartServicePendingIntent = PendingIntent.getService(
            this, 1, restartServiceIntent,
            PendingIntent.FLAG_ONE_SHOT or PendingIntent.FLAG_IMMUTABLE
        )
        
        val alarmService = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmService.set(
            AlarmManager.ELAPSED_REALTIME,
            android.os.SystemClock.elapsedRealtime() + 1000,
            restartServicePendingIntent
        )
    }
}