package com.example.keywordrecorder

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import java.util.Collections

object KeywordManager {
    data class UiState(
        val isListening: Boolean = false,
        val isRecording: Boolean = false,
        val remainingMs: Long = 0L,
        val lastDistance: Float = 0f,
        val threshold: Float = 15f,
        val hasTemplate: Boolean = false,
        val isEnrolling: Boolean = false,
        val lastFinishedAt: Long = 0L
    )

    private val _ui = MutableStateFlow(UiState())
    val ui: StateFlow<UiState> = _ui.asStateFlow()

    fun update(transform: (UiState) -> UiState) {
        _ui.update(transform)
    }

    var isCurrentlyRecording: Boolean
        get() = _ui.value.isRecording
        set(value) = update { it.copy(isRecording = value) }

    var recordingTimeRemainingMs: Long
        get() = _ui.value.remainingMs
        set(value) = update { it.copy(remainingMs = value) }

    var isListening: Boolean
        get() = _ui.value.isListening
        set(value) = update { it.copy(isListening = value) }

    var currentThreshold: Float
        get() = _ui.value.threshold
        set(value) = update { it.copy(threshold = value) }

    var lastDtwDistance: Float
        get() = _ui.value.lastDistance
        set(value) = update { it.copy(lastDistance = value) }

    var lastRecordingFinishedAt: Long
        get() = _ui.value.lastFinishedAt
        set(value) = update { it.copy(lastFinishedAt = value) }

    var isEnrolling: Boolean
        get() = _ui.value.isEnrolling
        set(value) = update { it.copy(isEnrolling = value) }

    val tempEnrollmentFrames: MutableList<FloatArray> = Collections.synchronizedList(mutableListOf())
    
    var keywordTemplate: Array<FloatArray>? = null
        set(value) {
            field = value
            update { it.copy(hasTemplate = value != null) }
        }

    fun startEnrollment() {
        tempEnrollmentFrames.clear()
        isEnrolling = true
    }

    fun stopEnrollment() {
        isEnrolling = false
        if (tempEnrollmentFrames.isNotEmpty()) {
            keywordTemplate = tempEnrollmentFrames.toTypedArray()
        }
    }
}

