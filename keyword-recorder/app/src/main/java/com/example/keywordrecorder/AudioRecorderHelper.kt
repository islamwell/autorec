package com.example.keywordrecorder

import android.content.Context
import android.media.MediaRecorder
import android.os.Build
import android.util.Log
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class AudioRecorderHelper(private val context: Context) {

    private var mediaRecorder: MediaRecorder? = null
    private var countdownTimer: android.os.CountDownTimer? = null
    var isRecording = false
        private set
    var currentRecordingFile: String? = null
        private set

    fun startRecording(durationMs: Long, onFinished: () -> Unit) {
        if (isRecording) return

        try {
            val timestamp = SimpleDateFormat("yyyy-MM-dd_HH-mm-ss", Locale.getDefault()).format(Date())
            val outputFile = File(context.getExternalFilesDir(null), "Recording_$timestamp.m4a")
            currentRecordingFile = outputFile.absolutePath
            
            mediaRecorder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                MediaRecorder(context)
            } else {
                @Suppress("DEPRECATION")
                MediaRecorder()
            }.apply {
                setAudioSource(MediaRecorder.AudioSource.MIC)
                setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
                setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
                setOutputFile(outputFile.absolutePath)
                prepare()
                start()
            }
            
            isRecording = true
            KeywordManager.isCurrentlyRecording = true
            KeywordManager.recordingTimeRemainingMs = durationMs
            Log.d("AudioRecorder", "Started recording to ${outputFile.absolutePath}")

            countdownTimer = object : android.os.CountDownTimer(durationMs, 1000) {
                override fun onTick(millisUntilFinished: Long) {
                    KeywordManager.recordingTimeRemainingMs = millisUntilFinished
                }

                override fun onFinish() {
                    stopRecording()
                    onFinished()
                }
            }.start()
            
        } catch (e: Exception) {
            Log.e("AudioRecorder", "Failed to start recording", e)
            isRecording = false
            KeywordManager.isCurrentlyRecording = false
            mediaRecorder?.release()
            mediaRecorder = null
            onFinished()
        }
    }

    fun stopRecording() {
        if (!isRecording) return
        try {
            mediaRecorder?.stop()
            mediaRecorder?.release()
        } catch (e: Exception) {
            Log.e("AudioRecorder", "Error stopping recorder", e)
        } finally {
            mediaRecorder = null
            countdownTimer?.cancel()
            countdownTimer = null
            isRecording = false
            KeywordManager.isCurrentlyRecording = false
            Log.d("AudioRecorder", "Stopped recording")
        }
    }
}
