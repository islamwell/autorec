#!/bin/bash

# Build Verification Script
# This script verifies that the Flutter project is properly configured for building

echo "=========================================="
echo "Flutter Build Configuration Verification"
echo "=========================================="
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Track status
ALL_CHECKS_PASSED=true

# Function to check if file/directory exists
check_exists() {
    if [ -e "$1" ]; then
        echo -e "${GREEN}✓${NC} $2"
        return 0
    else
        echo -e "${RED}✗${NC} $2 - NOT FOUND"
        ALL_CHECKS_PASSED=false
        return 1
    fi
}

# Function to check file content
check_content() {
    if grep -q "$2" "$1" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} $3"
        return 0
    else
        echo -e "${RED}✗${NC} $3 - NOT FOUND"
        ALL_CHECKS_PASSED=false
        return 1
    fi
}

echo "1. Checking Flutter Project Structure:"
echo "--------------------------------------"
check_exists "pubspec.yaml" "pubspec.yaml (Flutter project file)"
check_exists "lib/main.dart" "lib/main.dart (Main app entry point)"
check_exists "android/" "android/ (Android configuration)"
check_exists "ios/" "ios/ (iOS configuration)"
check_exists ".metadata" ".metadata (Flutter metadata)"
echo ""

echo "2. Checking Android Build Configuration:"
echo "----------------------------------------"
check_exists "android/app/build.gradle.kts" "android/app/build.gradle.kts"
check_exists "android/build.gradle.kts" "android/build.gradle.kts"
check_exists "android/settings.gradle.kts" "android/settings.gradle.kts"
check_exists "android/app/src/main/AndroidManifest.xml" "AndroidManifest.xml"
echo ""

echo "3. Checking Build Configuration Details:"
echo "----------------------------------------"
check_content "android/app/build.gradle.kts" "com.android.application" "Android application plugin configured"
check_content "android/app/build.gradle.kts" "dev.flutter.flutter-gradle-plugin" "Flutter Gradle plugin configured"
check_content "android/app/build.gradle.kts" "applicationId" "Application ID set"
echo ""

echo "4. Checking Key Directories:"
echo "----------------------------"
check_exists "lib/providers/" "lib/providers/ (State management)"
check_exists "lib/screens/" "lib/screens/ (UI screens)"
check_exists "lib/services/" "lib/services/ (Business logic)"
check_exists "lib/models/" "lib/models/ (Data models)"
check_exists "lib/widgets/" "lib/widgets/ (Reusable widgets)"
check_exists "lib/theme/" "lib/theme/ (App theme)"
echo ""

echo "5. Checking Dependencies:"
echo "------------------------"
check_content "pubspec.yaml" "flutter:" "Flutter SDK dependency"
check_content "pubspec.yaml" "flutter_riverpod:" "Riverpod state management"
check_content "pubspec.yaml" "flutter_sound:" "Flutter Sound for recording"
check_content "pubspec.yaml" "permission_handler:" "Permission handler"
echo ""

echo "6. Checking Source Files:"
echo "------------------------"
check_exists "lib/main.dart" "Main app file"
check_exists "lib/screens/home/improved_home_screen.dart" "Improved home screen"
check_exists "lib/providers/keyword_triggered_recording_provider.dart" "Keyword recording provider"
check_exists "lib/theme/app_theme.dart" "Material Design 3 theme"
echo ""

echo "7. Checking Documentation:"
echo "-------------------------"
check_exists "README.md" "README.md"
check_exists "BUILD_AND_INSTALL.md" "BUILD_AND_INSTALL.md"
check_exists "REFACTORING_CHANGES.md" "REFACTORING_CHANGES.md"
echo ""

echo "8. Build Output Information:"
echo "---------------------------"
echo -e "${YELLOW}ℹ${NC} Expected build outputs:"
echo "   - Standard APK: build/app/outputs/flutter-apk/app-debug.apk"
echo "   - Split APKs: build/app/outputs/flutter-apk/app-{arch}-debug.apk"
echo "   - Size: ~50-70 MB (debug), ~40-60 MB (release)"
echo ""

echo "9. Required Commands to Build:"
echo "------------------------------"
if command -v flutter &> /dev/null; then
    echo -e "${GREEN}✓${NC} Flutter is installed"
    flutter --version | head -1
    echo ""
    echo "Run these commands to build:"
    echo "  1. flutter pub get"
    echo "  2. flutter build apk --debug"
else
    echo -e "${RED}✗${NC} Flutter is NOT installed in this environment"
    echo ""
    echo -e "${YELLOW}⚠${NC}  To build the APK, you need:"
    echo "  1. Install Flutter SDK from https://flutter.dev"
    echo "  2. Run: flutter pub get"
    echo "  3. Run: flutter build apk --debug"
fi
echo ""

echo "=========================================="
if [ "$ALL_CHECKS_PASSED" = true ]; then
    echo -e "${GREEN}✓ PROJECT IS READY FOR BUILDING!${NC}"
    echo ""
    echo "The project structure is complete and properly configured."
    echo "All necessary files and configurations are in place."
else
    echo -e "${RED}✗ SOME CHECKS FAILED${NC}"
    echo ""
    echo "Please fix the issues above before building."
fi
echo "=========================================="
