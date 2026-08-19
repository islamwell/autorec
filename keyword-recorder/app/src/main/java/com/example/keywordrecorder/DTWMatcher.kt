package com.example.keywordrecorder

import android.util.Log
import kotlin.math.sqrt

class DTWMatcher {

    /**
     * Calculates the Dynamic Time Warping (DTW) distance between two MFCC sequences.
     */
    fun calculateDTWDistance(seq1: Array<FloatArray>, seq2: Array<FloatArray>): Float {
        val n = seq1.size
        val m = seq2.size

        if (n == 0 || m == 0) return Float.MAX_VALUE

        val dtw = Array(n + 1) { FloatArray(m + 1) { Float.MAX_VALUE } }
        for (i in 0..n) {
            dtw[i][0] = 0f
        }

        for (i in 1..n) {
            for (j in 1..m) {
                val cost = euclideanDistance(seq1[i - 1], seq2[j - 1])
                val minPrev = minOf(
                    dtw[i - 1][j],    // insertion
                    dtw[i][j - 1],    // deletion
                    dtw[i - 1][j - 1] // match
                )
                dtw[i][j] = cost + minPrev
            }
        }
        
        // Find minimum distance to match the full template (m) ending at any frame (i) in the window
        var minDistance = Float.MAX_VALUE
        for (i in 1..n) {
            if (dtw[i][m] < minDistance) {
                minDistance = dtw[i][m]
            }
        }
        
        // Normalize distance by template length
        return minDistance / m
    }

    private fun euclideanDistance(f1: FloatArray, f2: FloatArray): Float {
        var sum = 0f
        val len = minOf(f1.size, f2.size)
        // Usually we skip the first MFCC coefficient (0th) as it represents energy/volume
        for (i in 1 until len) {
            val diff = f1[i] - f2[i]
            sum += diff * diff
        }
        return sqrt(sum.toDouble()).toFloat()
    }

    /**
     * Finds if the template exists in the sliding window.
     */
    fun match(window: Array<FloatArray>, template: Array<FloatArray>): Boolean {
        if (template.isEmpty() || window.size < template.size / 2) return false

        // A true subsequence DTW would not force start/end alignment on the window
        // But for simplicity, we can just compare the most recent N frames where N is template size + margin
        val windowToMatch = if (window.size > template.size * 1.5) {
            window.copyOfRange(window.size - (template.size * 1.5).toInt(), window.size)
        } else {
            window
        }

        val distance = calculateDTWDistance(windowToMatch, template)
        Log.d("DTWMatcher", "DTW Distance: $distance")
        KeywordManager.lastDtwDistance = distance
        return distance < KeywordManager.currentThreshold
    }
}
