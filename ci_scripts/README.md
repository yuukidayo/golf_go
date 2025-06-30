# CI Scripts for Golf Go

## Overview

This directory contains scripts used for Continuous Integration (CI) processes.

## Scripts

### ci_post_clone.sh

This script runs after the repository is cloned in CI environments like Xcode Cloud. It performs the following tasks:

1. Sets up Flutter environment
2. Runs `flutter pub get` to download dependencies
3. Sets up CocoaPods and runs `pod install --repo-update` for iOS

## Usage with Xcode Cloud

### Option 1: Use Pre-built Scripts

In your Xcode Cloud workflow settings:

1. Navigate to the workflow configuration
2. Add a custom build script in the "Pre-build" phase
3. Reference this script: `./ci_scripts/ci_post_clone.sh`

### Option 2: Use CI Environment Profile

If you can't add custom pre-build scripts, Xcode Cloud will automatically run `ci_scripts/ci_post_clone.sh` if it exists in your repository.

### Important Notes

- Make sure to update the Flutter path in the script to match your CI environment
- The script assumes your iOS project is in the standard 'ios' directory
- You may need to adjust paths or commands based on your specific project structure
