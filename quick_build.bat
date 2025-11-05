@echo off
REM Quick Build Script for Voice Keyword Recorder (Windows)
REM This script helps you build the Flutter app with proper error checking

echo ==========================================
echo Voice Keyword Recorder - Quick Build
echo ==========================================
echo.

REM Check if Flutter is installed
where flutter >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Flutter is not installed or not in PATH
    echo.
    echo Please install Flutter from: https://docs.flutter.dev/get-started/install/windows
    echo.
    pause
    exit /b 1
)

echo [OK] Flutter found
flutter --version
echo.

REM Check Flutter doctor
echo Running Flutter doctor...
flutter doctor
echo.

REM Clean previous builds
echo Cleaning previous builds...
flutter clean
echo [OK] Clean complete
echo.

REM Get dependencies
echo Getting dependencies...
flutter pub get
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Failed to get dependencies
    pause
    exit /b 1
)
echo [OK] Dependencies resolved
echo.

REM Run analyzer
echo Running Flutter analyzer...
flutter analyze
if %ERRORLEVEL% NEQ 0 (
    echo [WARNING] Analyzer found issues (may still build)
)
echo.

REM Build debug APK
echo Building debug APK...
echo This may take 2-5 minutes on first build...
flutter build apk --debug

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ==========================================
    echo [SUCCESS] BUILD SUCCESSFUL!
    echo ==========================================
    echo.
    echo APK location:
    echo   build\app\outputs\flutter-apk\app-debug.apk
    echo.
    dir build\app\outputs\flutter-apk\app-debug.apk | findstr "apk"
    echo.
    echo To install on device:
    echo   adb install build\app\outputs\flutter-apk\app-debug.apk
    echo.
    echo To build release APK:
    echo   flutter build apk --release --split-per-abi
    echo.
) else (
    echo.
    echo ==========================================
    echo [FAILED] BUILD FAILED
    echo ==========================================
    echo.
    echo Please:
    echo 1. Copy the error message above
    echo 2. Share it with the developer/AI assistant
    echo 3. They will provide a fix
    echo.
    pause
    exit /b 1
)

pause
