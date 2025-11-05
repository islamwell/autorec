# Voice Keyword Recorder kiro

A cross-platform mobile application (iOS and Android) that provides intelligent voice recording capabilities optimized for human speech. The app features keyword-triggered automatic recording, customizable auto-stop functionality, and comprehensive playback controls with sharing capabilities.

## Features

- **Keyword-triggered recording**: Record a custom keyword that automatically starts recording when detected
- **Auto-stop timer**: Configurable recording duration (1-60 minutes)
- **Playback controls**: Variable speed playback (0.5x to 2x) with seek functionality
- **File management**: Save, organize, and share recordings as MP3 files
- **Cross-platform**: Native iOS and Android support
- **Background processing**: Continuous keyword detection with battery optimization

## Project Structure

```
lib/
├── main.dart                 # App entry point with Material Design 3 theming
├── models/                   # Data models (Recording, AppSettings, KeywordProfile)
├── services/                 # Business logic services
│   ├── audio/               # Audio recording and playback
│   ├── storage/             # File management and persistence
│   ├── permissions/         # Platform permission handling
│   └── keyword_detection/   # ML-based keyword detection
├── providers/               # Riverpod state management
├── screens/                 # UI screens
│   ├── home/               # Main recording interface
│   ├── recordings/         # Recording list and playback
│   └── settings/           # App configuration
├── widgets/                # Reusable UI components
└── utils/                  # Helper functions and constants
```

## Dependencies

- **flutter_sound**: Audio recording and playback
- **permission_handler**: Platform permission management
- **flutter_riverpod**: State management
- **path_provider**: File system access

## Platform Configuration

### Android
- Microphone and storage permissions configured
- Foreground service support for background keyword detection
- Material Design 3 theming

### iOS
- Microphone usage description added
- Background audio modes configured
- Audio session optimization for voice recording

## Getting Started

1. Ensure Flutter is installed and configured
2. Clone the repository
3. Run `flutter pub get` to install dependencies
4. Run `flutter run` to start the app

## Development

This project follows the Flutter best practices with:
- Clean architecture with service-oriented design
- Riverpod for state management
- Material Design 3 with custom dark theme
- Platform-specific optimizations for iOS and Android

## Next Steps

The project structure is now ready for implementation. Refer to the tasks.md file in the spec for the detailed implementation plan.