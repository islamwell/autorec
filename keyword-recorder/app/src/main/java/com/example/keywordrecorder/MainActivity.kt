package com.example.keywordrecorder

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.os.Build
import android.os.Bundle
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.core.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.scale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.compose.ui.unit.dp
import androidx.core.content.ContextCompat
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File
import java.text.SimpleDateFormat
import java.util.Locale
import java.util.concurrent.TimeUnit

class MainActivity : ComponentActivity() {

    private val hasMicPermission = mutableStateOf(false)

    private val requestPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { permissions ->
        hasMicPermission.value = permissions[Manifest.permission.RECORD_AUDIO]
            ?: (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED)
        if (hasMicPermission.value) {
            Log.i("MainActivity", "Permissions granted")
        } else {
            Log.e("MainActivity", "Permissions denied")
        }
    }

    private var mediaPlayer: MediaPlayer? = null
    private val currentlyPlayingFile = mutableStateOf<File?>(null)
    private val isAudioPlaying = mutableStateOf(false)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        checkAndRequestPermissions()

        setContent {
            MaterialTheme {
                Surface(modifier = Modifier.fillMaxSize()) {
                    KeywordRecorderApp(
                        startService = { startListeningService() },
                        stopService = { stopListeningService() },
                        togglePlay = { file -> togglePlay(file) },
                        deleteFile = { file, onDeleted -> deleteRecording(file, onDeleted) },
                        currentlyPlayingFile = currentlyPlayingFile.value,
                        isPlaying = isAudioPlaying.value,
                        hasMicPermission = hasMicPermission.value
                    )
                }
            }
        }
    }

    override fun onResume() {
        super.onResume()
        hasMicPermission.value = ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED
    }

    private fun checkAndRequestPermissions() {
        val permissionsToRequest = mutableListOf(Manifest.permission.RECORD_AUDIO)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            permissionsToRequest.add(Manifest.permission.POST_NOTIFICATIONS)
        }

        val needed = permissionsToRequest.filter {
            ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
        }

        if (needed.isNotEmpty()) {
            requestPermissionLauncher.launch(needed.toTypedArray())
        } else {
            hasMicPermission.value = true
        }
    }

    private fun startListeningService() {
        if (!hasMicPermission.value) {
            checkAndRequestPermissions()
            return
        }
        val serviceIntent = Intent(this, ListeningService::class.java)
        runCatching {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(serviceIntent)
            } else {
                startService(serviceIntent)
            }
        }.onFailure {
            Log.e("MainActivity", "Foreground service start blocked", it)
        }
    }

    private fun stopListeningService() {
        val serviceIntent = Intent(this, ListeningService::class.java)
        stopService(serviceIntent)
    }

    private fun releasePlayer() {
        mediaPlayer?.run {
            runCatching { if (isPlaying) stop() }
            release()
        }
        mediaPlayer = null
        isAudioPlaying.value = false
        currentlyPlayingFile.value = null
    }

    private fun togglePlay(file: File) {
        val mp = mediaPlayer
        if (currentlyPlayingFile.value == file && mp != null) {
            if (isAudioPlaying.value) {
                mp.pause()
                isAudioPlaying.value = false
            } else {
                mp.start()
                isAudioPlaying.value = true
            }
            return
        }
        releasePlayer()
        if (!file.exists()) return
        mediaPlayer = MediaPlayer().apply {
            setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_MEDIA)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                    .build()
            )
            setOnPreparedListener { mp ->
                mp.start()
                isAudioPlaying.value = true
                currentlyPlayingFile.value = file
            }
            setOnCompletionListener { releasePlayer() }
            setOnErrorListener { _, w, e ->
                Log.e("MainActivity", "MediaPlayer error: $w/$e")
                releasePlayer()
                true
            }
            runCatching {
                setDataSource(file.absolutePath)
                prepareAsync()
            }.onFailure {
                Log.e("MainActivity", "setDataSource failed", it)
                releasePlayer()
            }
        }
    }

    private fun deleteRecording(file: File, onDeleted: () -> Unit) {
        if (currentlyPlayingFile.value == file) releasePlayer()
        if (!file.delete()) {
            Log.w("MainActivity", "Delete failed: ${file.name}")
        }
        onDeleted()
    }

    override fun onStop() {
        super.onStop()
        if (isFinishing) releasePlayer()
    }

    override fun onDestroy() {
        super.onDestroy()
        releasePlayer()
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun KeywordRecorderApp(
    startService: () -> Unit,
    stopService: () -> Unit,
    togglePlay: (File) -> Unit,
    deleteFile: (File, () -> Unit) -> Unit,
    currentlyPlayingFile: File?,
    isPlaying: Boolean,
    hasMicPermission: Boolean
) {
    val context = LocalContext.current
    val state by KeywordManager.ui.collectAsState()
    val coroutineScope = rememberCoroutineScope()
    var recordings by remember { mutableStateOf(emptyList<File>()) }

    fun refreshFiles() {
        coroutineScope.launch {
            val files = withContext(Dispatchers.IO) {
                val dir = context.getExternalFilesDir(null)
                dir?.listFiles { file -> file.isFile && file.name.endsWith(".m4a") }?.toList().orEmpty()
            }
            recordings = files.sortedByDescending { it.lastModified() }
        }
    }

    val lifecycleOwner = LocalLifecycleOwner.current
    DisposableEffect(lifecycleOwner, state.lastFinishedAt) {
        val observer = LifecycleEventObserver { _, event ->
            if (event == Lifecycle.Event.ON_RESUME) {
                refreshFiles()
            }
        }
        lifecycleOwner.lifecycle.addObserver(observer)
        refreshFiles()
        onDispose {
            lifecycleOwner.lifecycle.removeObserver(observer)
        }
    }

    val infiniteTransition = rememberInfiniteTransition(label = "pulse")
    val pulseScale by infiniteTransition.animateFloat(
        initialValue = 0.98f,
        targetValue = 1.02f,
        animationSpec = infiniteRepeatable(animation = tween(1000, easing = FastOutSlowInEasing), repeatMode = RepeatMode.Reverse),
        label = "pulseScale"
    )
    val pulseAlpha by infiniteTransition.animateFloat(
        initialValue = 0.5f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(animation = tween(1000, easing = FastOutSlowInEasing), repeatMode = RepeatMode.Reverse),
        label = "pulseAlpha"
    )

    val sdfIn = remember { SimpleDateFormat("yyyy-MM-dd_HH-mm-ss", Locale.getDefault()) }
    val sdfOut = remember { SimpleDateFormat("MMM d, yyyy 'at' h:mm a", Locale.getDefault()) }

    Scaffold(
        topBar = {
            LargeTopAppBar(
                title = { Text("Acoustic Recorder", style = MaterialTheme.typography.headlineMedium) },
                colors = TopAppBarDefaults.largeTopAppBarColors(
                    containerColor = MaterialTheme.colorScheme.primaryContainer,
                    titleContentColor = MaterialTheme.colorScheme.onPrimaryContainer
                )
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .padding(paddingValues)
                .fillMaxSize()
                .padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Spacer(modifier = Modifier.height(8.dp))

            if (state.isListening) {
                ElevatedCard(
                    colors = CardDefaults.elevatedCardColors(containerColor = MaterialTheme.colorScheme.tertiaryContainer),
                    modifier = Modifier.fillMaxWidth().padding(horizontal = 8.dp, vertical = 4.dp).alpha(pulseAlpha)
                ) {
                    Column(modifier = Modifier.padding(16.dp).fillMaxWidth(), horizontalAlignment = Alignment.CenterHorizontally) {
                        Text(text = "🟢 ACTIVELY LISTENING", color = MaterialTheme.colorScheme.onTertiaryContainer, style = MaterialTheme.typography.titleMedium)
                    }
                }
            }

            if (state.isRecording) {
                val millis = state.remainingMs
                val minutes = TimeUnit.MILLISECONDS.toMinutes(millis)
                val seconds = TimeUnit.MILLISECONDS.toSeconds(millis) - TimeUnit.MINUTES.toSeconds(minutes)
                val timeString = String.format(Locale.US, "%02d:%02d", minutes, seconds)
                
                ElevatedCard(
                    colors = CardDefaults.elevatedCardColors(containerColor = MaterialTheme.colorScheme.errorContainer),
                    modifier = Modifier.fillMaxWidth().padding(8.dp).scale(pulseScale)
                ) {
                    Column(modifier = Modifier.padding(16.dp).fillMaxWidth(), horizontalAlignment = Alignment.CenterHorizontally) {
                        Text(text = "🔴 RECORDING IN PROGRESS", color = MaterialTheme.colorScheme.onErrorContainer, style = MaterialTheme.typography.titleMedium)
                        Text(text = timeString, color = MaterialTheme.colorScheme.onErrorContainer, style = MaterialTheme.typography.headlineLarge)
                    }
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            if (!state.hasTemplate) {
                Text("No keyword template set.")
            } else {
                Text("Keyword Template SET!", color = MaterialTheme.colorScheme.primary)
            }

            Spacer(modifier = Modifier.height(16.dp))

            Button(
                onClick = {
                    if (!state.isEnrolling) {
                        startService()
                        KeywordManager.startEnrollment()
                    } else {
                        KeywordManager.stopEnrollment()
                    }
                },
                enabled = hasMicPermission,
                colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.secondary)
            ) {
                Text(if (state.isEnrolling) "Stop Recording Keyword" else "Record Keyword Signature")
            }

            Spacer(modifier = Modifier.height(16.dp))

            Card(modifier = Modifier.fillMaxWidth().padding(8.dp)) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text(text = "Acoustic Sensitivity Calibration", style = MaterialTheme.typography.titleSmall)
                    Text(text = "Last Voice Distance: ${String.format(Locale.US, "%.2f", state.lastDistance)}", style = MaterialTheme.typography.bodyMedium)
                    Text(text = "Threshold: ${String.format(Locale.US, "%.1f", state.threshold)}", style = MaterialTheme.typography.bodyMedium)
                    Slider(
                        value = state.threshold,
                        onValueChange = { KeywordManager.currentThreshold = it },
                        valueRange = 5f..40f
                    )
                    Text(text = "Tip: Speak your word, look at 'Last Voice Distance', and set Threshold slightly above that number.", style = MaterialTheme.typography.bodySmall)
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            Button(
                onClick = { startService() },
                enabled = hasMicPermission && state.hasTemplate,
                colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.primary)
            ) {
                Text("Start Continuous Listening")
            }
            
            Spacer(modifier = Modifier.height(8.dp))

            Button(
                onClick = { stopService() },
                colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.error)
            ) {
                Text("Stop Continuous Listening")
            }

            Spacer(modifier = Modifier.height(16.dp))
            Text(text = "Recordings", style = MaterialTheme.typography.titleMedium)
            
            LazyColumn(modifier = Modifier.fillMaxWidth().weight(1f)) {
                items(recordings, key = { it.absolutePath }) { file ->
                    val isThisFilePlaying = (file == currentlyPlayingFile && isPlaying)
                    
                    val rawName = file.nameWithoutExtension.removePrefix("Recording_")
                    val displayDate = remember(file.absolutePath) {
                        runCatching {
                            sdfOut.format(sdfIn.parse(rawName)!!)
                        }.getOrDefault(file.name)
                    }

                    ElevatedCard(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 4.dp),
                        colors = CardDefaults.elevatedCardColors(
                            containerColor = if (isThisFilePlaying) MaterialTheme.colorScheme.primaryContainer else MaterialTheme.colorScheme.surface
                        )
                    ) {
                        Row(
                            modifier = Modifier.padding(16.dp).fillMaxWidth(),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            Text(
                                text = displayDate,
                                style = MaterialTheme.typography.bodyLarge,
                                color = if (isThisFilePlaying) MaterialTheme.colorScheme.onPrimaryContainer else MaterialTheme.colorScheme.onSurface,
                                modifier = Modifier.weight(1f)
                            )
                            Row {
                                IconButton(
                                    onClick = { togglePlay(file) },
                                    modifier = Modifier.scale(if (isThisFilePlaying) pulseScale else 1f)
                                ) {
                                    Text(
                                        text = if (isThisFilePlaying) "⏸" else "▶",
                                        style = MaterialTheme.typography.headlineSmall
                                    )
                                }
                                IconButton(onClick = {
                                    deleteFile(file) { refreshFiles() }
                                }) {
                                    Text(
                                        text = "🗑",
                                        color = MaterialTheme.colorScheme.error,
                                        style = MaterialTheme.typography.headlineSmall
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
