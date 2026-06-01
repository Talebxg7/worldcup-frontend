#!/bin/bash

# Exit on any error
set -e

# Xcode Cloud clones the repository at the root. 
# The script is executed from within the ios/ci_scripts folder, 
# so we need to navigate 2 levels up to reach the root folder of the project.
cd ../..

echo "──────────────────────────────────────────────"
echo "🚀 Starting Xcode Cloud pre-build configuration..."
echo "──────────────────────────────────────────────"

# 1. Clone Flutter stable branch
echo "📥 Cloning Flutter stable SDK..."
git clone https://github.com/flutter/flutter.git --depth 1 -b stable $HOME/flutter

# Add Flutter to the PATH
export PATH="$PATH:$HOME/flutter/bin"

# 2. Pre-cache Flutter binaries
echo "⚡ Pre-caching Flutter binaries..."
flutter precache

# Print versions to confirm success
echo "📋 System info:"
flutter --version

# 3. Install dependencies
echo "📦 Getting pub dependencies..."
flutter pub get

# 4. Generate the necessary iOS config files (this builds Generated.xcconfig)
echo "🔧 Generating Xcode config files..."
flutter build ios --config-only

# 5. Install CocoaPods dependencies
cd ios
echo "⚙️ Running pod install..."
pod install

echo "──────────────────────────────────────────────"
echo "✅ Flutter Xcode Cloud preparation complete!"
echo "──────────────────────────────────────────────"
