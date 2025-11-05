#!/bin/bash

# Quick Build Script for Voice Keyword Recorder
# This script helps you build the Flutter app with proper error checking

set -e  # Exit on error

echo "=========================================="
echo "Voice Keyword Recorder - Quick Build"
echo "=========================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}ERROR: Flutter is not installed or not in PATH${NC}"
    echo ""
    echo "Please install Flutter from: https://docs.flutter.dev/get-started/install"
    echo ""
    exit 1
fi

echo -e "${GREEN}✓${NC} Flutter found"
flutter --version
echo ""

# Check Flutter doctor
echo "Running Flutter doctor..."
flutter doctor
echo ""

# Clean previous builds
echo "Cleaning previous builds..."
flutter clean
echo -e "${GREEN}✓${NC} Clean complete"
echo ""

# Get dependencies
echo "Getting dependencies..."
flutter pub get
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Dependencies resolved"
else
    echo -e "${RED}✗${NC} Failed to get dependencies"
    exit 1
fi
echo ""

# Run analyzer
echo "Running Flutter analyzer..."
flutter analyze
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC} No analyzer issues"
else
    echo -e "${YELLOW}⚠${NC} Analyzer found issues (may still build)"
fi
echo ""

# Build debug APK
echo "Building debug APK..."
echo "This may take 2-5 minutes on first build..."
flutter build apk --debug

if [ $? -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo -e "${GREEN}✓ BUILD SUCCESSFUL!${NC}"
    echo "=========================================="
    echo ""
    echo "APK location:"
    echo "  build/app/outputs/flutter-apk/app-debug.apk"
    echo ""
    echo "APK size:"
    ls -lh build/app/outputs/flutter-apk/app-debug.apk | awk '{print "  " $5}'
    echo ""
    echo "To install on device:"
    echo "  adb install build/app/outputs/flutter-apk/app-debug.apk"
    echo ""
    echo "To build release APK:"
    echo "  flutter build apk --release --split-per-abi"
    echo ""
else
    echo ""
    echo "=========================================="
    echo -e "${RED}✗ BUILD FAILED${NC}"
    echo "=========================================="
    echo ""
    echo "Please:"
    echo "1. Copy the error message above"
    echo "2. Share it with the developer/AI assistant"
    echo "3. They will provide a fix"
    echo ""
    exit 1
fi
