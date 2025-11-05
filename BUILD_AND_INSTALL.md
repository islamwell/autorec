# Build and Install Guide

This guide shows you how to build and install the Voice Keyword Recorder app on your Android device.

## Prerequisites

Before building, ensure you have:

1. **Flutter SDK** installed (3.0 or higher)
   ```bash
   flutter --version
   ```

2. **Android SDK** configured
   ```bash
   flutter doctor
   ```

3. **Connected Android device** or **emulator running**
   ```bash
   flutter devices
   ```

---

## Quick Start (One Command)

### Option 1: Build and Install Directly
```bash
# This builds and installs in one step
flutter run --release
```

### Option 2: Build APK then Install
```bash
# Build the APK
flutter build apk --release

# Install to connected device
flutter install
```

---

## Detailed Instructions

### Step 1: Fetch Dependencies
```bash
# Navigate to project directory
cd /path/to/autorec

# Get all packages
flutter pub get
```

### Step 2: Build the APK

#### Option A: Standard APK (Recommended for Most Devices)
```bash
flutter build apk --release
```

**Output**: `build/app/outputs/flutter-apk/app-release.apk`
**Size**: ~40-60 MB (all architectures)

#### Option B: Split APKs by Architecture (Smaller Size)
```bash
flutter build apk --release --split-per-abi
```

**Output Files**:
- `app-armeabi-v7a-release.apk` (~20 MB) - For older 32-bit devices
- `app-arm64-v8a-release.apk` (~20 MB) - For modern 64-bit devices
- `app-x86_64-release.apk` (~20 MB) - For emulators

**Choose the right one**:
- Most modern phones (2019+): Use `arm64-v8a`
- Older phones: Use `armeabi-v7a`
- Emulator: Use `x86_64`

#### Option C: App Bundle (For Google Play Store)
```bash
flutter build appbundle --release
```

**Output**: `build/app/outputs/bundle/release/app-release.aab`

### Step 3: Install the APK

#### Method 1: Using Flutter CLI (Easiest)
```bash
# Install directly from build output
flutter install
```

#### Method 2: Using ADB (Android Debug Bridge)
```bash
# Install standard APK
adb install build/app/outputs/flutter-apk/app-release.apk

# Or install specific architecture
adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

#### Method 3: Manual Installation (No Computer Needed)

1. **Transfer APK to Phone**:
   - Email it to yourself
   - Upload to Google Drive/Dropbox
   - Transfer via USB cable

2. **Enable Unknown Sources**:
   - Go to: Settings → Security → Unknown Sources
   - Or: Settings → Apps → Special Access → Install Unknown Apps
   - Enable for your file manager/browser

3. **Install APK**:
   - Open the APK file on your phone
   - Tap "Install"
   - Wait for installation to complete
   - Tap "Open"

---

## Build Variants

### Debug Build (For Development)
```bash
# Larger file, includes debugging tools
flutter build apk --debug
```

### Profile Build (For Performance Testing)
```bash
# Optimized but with profiling enabled
flutter build apk --profile
```

### Release Build (For Production)
```bash
# Fully optimized, smallest size
flutter build apk --release
```

---

## Installation Commands Reference

### Check Connected Devices
```bash
# List all connected devices
flutter devices

# Or using ADB
adb devices
```

### Install to Specific Device
```bash
# If multiple devices connected
flutter install -d <device_id>

# Or with ADB
adb -s <device_id> install app-release.apk
```

### Uninstall Previous Version
```bash
# Uninstall using Flutter
flutter uninstall

# Or using ADB
adb uninstall com.example.voice_keyword_recorder
```

### Install and Launch
```bash
# Build, install, and run in one command
flutter run --release

# Or for debug version
flutter run
```

---

## Complete Build & Install Workflow

```bash
# 1. Navigate to project
cd /home/user/autorec

# 2. Clean previous builds (optional but recommended)
flutter clean

# 3. Get dependencies
flutter pub get

# 4. Check for issues
flutter analyze

# 5. Build release APK
flutter build apk --release --split-per-abi

# 6. Check connected devices
adb devices

# 7. Install to device
adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk

# 8. Launch the app
adb shell am start -n com.example.voice_keyword_recorder/.MainActivity
```

---

## Troubleshooting

### Issue: "flutter: command not found"
**Solution**: Install Flutter SDK and add to PATH
```bash
export PATH="$PATH:/path/to/flutter/bin"
```

### Issue: "No devices found"
**Solution**:
```bash
# Enable USB debugging on Android phone
# Settings → Developer Options → USB Debugging

# Check connection
adb devices
```

### Issue: "Gradle build failed"
**Solution**:
```bash
# Clear gradle cache
cd android
./gradlew clean

# Go back and rebuild
cd ..
flutter clean
flutter pub get
flutter build apk --release
```

### Issue: "APK won't install on phone"
**Solution**:
- Uninstall old version first
- Enable "Install from Unknown Sources"
- Check if APK architecture matches device (use standard APK if unsure)

### Issue: "App crashes on launch"
**Solution**:
```bash
# Check logs
adb logcat | grep flutter

# Or install debug version for better error messages
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

---

## APK Locations

After building, find your APK here:

**Standard APK**:
```
build/app/outputs/flutter-apk/app-release.apk
```

**Split APKs**:
```
build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
build/app/outputs/flutter-apk/app-x86_64-release.apk
```

**App Bundle**:
```
build/app/outputs/bundle/release/app-release.aab
```

---

## Permissions Required

The app will request these permissions on first launch:
- **Microphone** - For recording audio
- **Storage** - For saving recordings
- **Notifications** - For recording alerts

Make sure to **grant all permissions** for the app to work properly.

---

## Next Steps After Installation

1. **Grant Permissions**: Allow microphone, storage, and notification access
2. **Train Keyword**: Go to home screen → Tap "Train Keyword"
3. **Record Keyword**: Record yourself saying your keyword 2-3 times
4. **Start Listening**: Return to home → Tap "Start Listening"
5. **Test It**: Say your keyword and recording should start automatically!

---

## For Testing Without Device

Use an Android emulator:

```bash
# Create emulator (one time)
flutter emulators --create

# Or use Android Studio AVD Manager

# Run app on emulator
flutter run --release
```

---

## Advanced: Signing the APK (For Distribution)

If distributing to others, sign the APK:

### 1. Create keystore (one time)
```bash
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

### 2. Configure signing in `android/key.properties`:
```properties
storePassword=<password>
keyPassword=<password>
keyAlias=upload
storeFile=<path-to-keystore>
```

### 3. Update `android/app/build.gradle`:
```gradle
signingConfigs {
    release {
        keyAlias keystoreProperties['keyAlias']
        keyPassword keystoreProperties['keyPassword']
        storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
        storePassword keystoreProperties['storePassword']
    }
}
```

### 4. Build signed APK:
```bash
flutter build apk --release
```

---

## Summary Commands

**For most users (recommended)**:
```bash
cd /home/user/autorec
flutter pub get
flutter build apk --release
adb install build/app/outputs/flutter-apk/app-release.apk
```

**For smaller APK size**:
```bash
flutter build apk --release --split-per-abi
adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

**For direct run**:
```bash
flutter run --release
```

---

## Support

If you encounter issues:
1. Check `flutter doctor` for setup problems
2. Run `flutter clean && flutter pub get`
3. Check Android device logs: `adb logcat`
4. Ensure all permissions are granted in app settings

---

**Happy Recording!** 🎤
