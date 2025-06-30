#!/bin/bash

# Flutterのセットアップ
echo "Setting up Flutter..."
export PATH="$PATH:/path/to/flutter/bin"
flutter --version
flutter pub get

# CocoaPodsのセットアップ
echo "Setting up CocoaPods..."
cd ios
pod install --repo-update
