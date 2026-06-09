#!/bin/bash

# Exit on any error
set -e

# Navigate to the root of the project using Xcode Cloud's default env variable
cd "$CI_PRIMARY_REPOSITORY_PATH"

echo "──────────────────────────────────────────────"
echo "🚀 Starting Xcode Cloud pre-build configuration..."
echo "──────────────────────────────────────────────"

# 1. Clean and Clone Flutter stable branch
echo "📥 Setting up Flutter SDK..."
rm -rf "$HOME/flutter"
git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$HOME/flutter"

# Add Flutter to the PATH
export PATH="$PATH:$HOME/flutter/bin"

# 2. Pre-cache Flutter binaries
echo "⚡ Pre-caching Flutter binaries..."
flutter precache --ios

# Print versions to confirm success
echo "📋 System info:"
flutter --version

# 3. Install dependencies
echo "📦 Getting pub dependencies..."
flutter pub get

# 4. Generate the necessary iOS config files (this builds Generated.xcconfig)
echo "🔧 Generating Xcode config files..."
flutter build ios --config-only

# 5. Install CocoaPods
echo "🍺 Installing CocoaPods..."
HOMEBREW_NO_AUTO_UPDATE=1 brew install cocoapods

# 6. Install CocoaPods dependencies
cd ios
echo "⚙️ Running pod install..."
pod install

echo "──────────────────────────────────────────────"
echo "✅ Flutter Xcode Cloud preparation complete!"
echo "──────────────────────────────────────────────"
