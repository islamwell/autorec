package com.example.keywordrecorder

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.content.pm.PackageManager
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import be.tarsos.dsp.mfcc.MFCC

class ListeningService : Service() {

    private var audioRecord: AudioRecord? = null
    private var isListening = false
    private var recordingThread: Thread? = null

    private val slidingWindow = mutableListOf<FloatArray>()
    private val MAX_WINDOW_FRAMES = 300
    private val dtwMatcher = DTWMatcher()
    private lateinit var audioRecorderHelper: AudioRecorderHelper
    private var tfliteClassifier: TFLiteClassifier? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        audioRecorderHelper = AudioRecorderHelper(this)
        tfliteClassifier = TFLiteClassifier(this)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val notificationIntent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, notificationIntent, PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(this, "ListeningChannel")
            .setContentTitle("Keyword Recorder")
            .setContentText("Listening for your acoustic keyword...")
            .setSmallIcon(android.R.drawable.ic_btn_speak_now)
            .setContentIntent(pendingIntent)
            .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(1, notification, android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE)
        } else {
            startForeground(1, notification)
        }

        startListening()

        return START_STICKY
    }

    private fun startListening() {
        if (isListening || audioRecorderHelper.isRecording) return

        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            Log.e("ListeningService", "No RECORD_AUDIO permission")
            return
        }

        val sampleRate = 16000
        val bufferSize = 1024
        val channelConfig = AudioFormat.CHANNEL_IN_MONO
        val audioFormat = AudioFormat.ENCODING_PCM_16BIT
        val minBufferSize = AudioRecord.getMinBufferSize(sampleRate, channelConfig, audioFormat)

        audioRecord = AudioRecord(
            MediaRecorder.AudioSource.MIC,
            sampleRate,
            channelConfig,
            audioFormat,
            maxOf(minBufferSize, bufferSize * 2)
        )

        if (audioRecord?.state != AudioRecord.STATE_INITIALIZED) {
            Log.e("ListeningService", "AudioRecord failed to initialize!")
            audioRecord?.release()
            audioRecord = null
            return
        }

        audioRecord?.startRecording()
        isListening = true
        KeywordManager.isListening = true

        recordingThread = Thread {
            val shortBuffer = ShortArray(bufferSize)
            val floatBuffer = FloatArray(bufferSize)
            // 40 cepstrum coefficients extracted from 40 mel filters (matches TFLite neural network input)
            val mfcc = MFCC(bufferSize, sampleRate.toFloat(), 40, 40, 133f, 8000f)
            var frameCount = 0

            // Hoist AudioEvent and format allocation outside the loop to eliminate GC pauses
            val tarsosFormat = be.tarsos.dsp.io.TarsosDSPAudioFormat(sampleRate.toFloat(), 16, 1, true, false)
            val audioEvent = be.tarsos.dsp.AudioEvent(tarsosFormat)

            while (isListening) {
                val readSize = audioRecord?.read(shortBuffer, 0, bufferSize) ?: 0
                if (readSize > 0) {
                    var sumSquares = 0f
                    // Convert 16-bit PCM to Float [-1.0, 1.0]
                    for (i in 0 until readSize) {
                        val sample = shortBuffer[i] / 32768.0f
                        floatBuffer[i] = sample
                        sumSquares += sample * sample
                    }

                    // Zero out remaining buffer tail if readSize was smaller than bufferSize
                    if (readSize < bufferSize) {
                        java.util.Arrays.fill(floatBuffer, readSize, bufferSize, 0f)
                    }

                    val rms = kotlin.math.sqrt((sumSquares / readSize).toDouble()).toFloat()

                    // VAD: If audio is silent, reset window to prevent stitching non-adjacent speech frames
                    if (rms < 0.005f) {
                        synchronized(slidingWindow) {
                            slidingWindow.clear()
                        }
                        frameCount = 0
                        continue
                    }

                    audioEvent.floatBuffer = floatBuffer
                    mfcc.process(audioEvent)
                    
                    val features = mfcc.mfcc
                    val featureCopy = features.copyOf()

                    if (KeywordManager.isEnrolling) {
                        KeywordManager.tempEnrollmentFrames.add(featureCopy)
                    } else if (!audioRecorderHelper.isRecording) {
                        synchronized(slidingWindow) {
                            slidingWindow.add(featureCopy)
                            if (slidingWindow.size > MAX_WINDOW_FRAMES) {
                                slidingWindow.removeAt(0)
                            }

                            frameCount++
                            if (frameCount % 5 == 0) {
                                val isTFLiteReady = tfliteClassifier?.isModelLoaded == true
                                if (isTFLiteReady && slidingWindow.size >= 30) {
                                    val windowCopy = slidingWindow.toList()
                                    val matched = tfliteClassifier?.classify(windowCopy, 0.75f) == true
                                    if (matched) {
                                        Log.i("ListeningService", "🧠 TFLite Neural Network Matched Keyword 'straight row'!")
                                        triggerRecording()
                                    }
                                } else if (KeywordManager.keywordTemplate != null && slidingWindow.size > KeywordManager.keywordTemplate!!.size / 2) {
                                    val matched = dtwMatcher.match(slidingWindow.toTypedArray(), KeywordManager.keywordTemplate!!)
                                    if (matched) {
                                        Log.i("ListeningService", "📈 Classical DTW Matched Keyword!")
                                        triggerRecording()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }.apply { start() }
    }

    private fun triggerRecording() {
        stopListening()
        
        // Add a 500ms delay to allow the OS to completely free the microphone hardware
        // before we attempt to start the MediaRecorder, preventing an IllegalStateException crash.
        android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
            // 15 minutes = 900000L ms
            audioRecorderHelper.startRecording(900_000L) {
                KeywordManager.lastRecordingFinishedAt = System.currentTimeMillis()
                startListening()
            }
        }, 500)
    }

    private fun stopListening() {
        isListening = false
        KeywordManager.isListening = false
        val thread = recordingThread
        recordingThread = null
        try {
            if (thread != null && Thread.currentThread() != thread) {
                thread.join(1000)
            }
        } catch (e: Exception) {
            Log.e("ListeningService", "Error joining thread", e)
        }
        
        try {
            audioRecord?.stop()
            audioRecord?.release()
        } catch (e: Exception) {
            Log.e("ListeningService", "Error stopping audioRecord", e)
        } finally {
            audioRecord = null
            synchronized(slidingWindow) {
                slidingWindow.clear()
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        stopListening()
        audioRecorderHelper.stopRecording()
        tfliteClassifier?.close()
    }


    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "ListeningChannel",
                "Listening Service",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
        }
    }
}
