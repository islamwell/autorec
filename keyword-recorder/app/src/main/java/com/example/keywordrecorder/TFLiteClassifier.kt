package com.example.keywordrecorder

import android.content.Context
import android.content.res.AssetFileDescriptor
import android.util.Log
import org.tensorflow.lite.Interpreter
import java.io.FileInputStream
import java.nio.MappedByteBuffer
import java.nio.channels.FileChannel
import java.util.Locale

class TFLiteClassifier(private val context: Context) {
    private var interpreter: Interpreter? = null
    val isModelLoaded: Boolean
        get() = interpreter != null

    init {
        try {
            val modelBuffer = loadModelFile("straight_row.tflite")
            if (modelBuffer != null) {
                val options = Interpreter.Options().apply {
                    numThreads = 2
                }
                interpreter = Interpreter(modelBuffer, options)
                Log.i("TFLiteClassifier", "✅ Successfully loaded straight_row.tflite neural network!")
            } else {
                Log.w("TFLiteClassifier", "⚠️ straight_row.tflite not found in assets. Using DTW fallback until model is trained and added.")
            }
        } catch (e: Exception) {
            Log.e("TFLiteClassifier", "Error initializing TFLite interpreter", e)
        }
    }

    private fun loadModelFile(modelName: String): MappedByteBuffer? {
        return try {
            val fileDescriptor: AssetFileDescriptor = context.assets.openFd(modelName)
            val inputStream = FileInputStream(fileDescriptor.fileDescriptor)
            val fileChannel = inputStream.channel
            val startOffset = fileDescriptor.startOffset
            val declaredLength = fileDescriptor.declaredLength
            fileChannel.map(FileChannel.MapMode.READ_ONLY, startOffset, declaredLength)
        } catch (e: Exception) {
            null
        }
    }

    /**
     * Runs neural network classification over a sequence of 40-band MFCC frames.
     * @param mfccFrames List of FloatArrays, where each FloatArray has 40 MFCC coefficients.
     * @return True if "straight_row" confidence is >= threshold probability (default 0.70f).
     */
    fun classify(mfccFrames: List<FloatArray>, probabilityThreshold: Float = 0.70f): Boolean {
        val interp = interpreter ?: return false
        if (mfccFrames.isEmpty()) return false

        try {
            // In train_model.py, we extract 40 MFCC bands over 1.5s (~47 frames)
            // The input tensor expects shape [1, time_steps, 40, 1]
            val timeSteps = mfccFrames.size
            val inputTensor = Array(1) { Array(timeSteps) { Array(40) { FloatArray(1) } } }

            for (t in 0 until timeSteps) {
                val frame = mfccFrames[t]
                val bandsToCopy = minOf(frame.size, 40)
                for (b in 0 until bandsToCopy) {
                    inputTensor[0][t][b][0] = frame[b]
                }
            }

            // Output tensor is [1, 2] -> [noise_prob, keyword_prob]
            val outputTensor = Array(1) { FloatArray(2) }

            interp.run(inputTensor, outputTensor)

            val noiseProb = outputTensor[0][0]
            val keywordProb = outputTensor[0][1]

            Log.d("TFLiteClassifier", "KWS Inference -> Noise: ${String.format(Locale.US, "%.2f", noiseProb)}, Keyword: ${String.format(Locale.US, "%.2f", keywordProb)}")

            return keywordProb >= probabilityThreshold
        } catch (e: Exception) {
            Log.e("TFLiteClassifier", "Error running TFLite inference", e)
            return false
        }
    }

    fun close() {
        try {
            interpreter?.close()
            interpreter = null
        } catch (e: Exception) {
            Log.e("TFLiteClassifier", "Error closing interpreter", e)
        }
    }
}
