#!/bin/sh

# Xcode Cloud: runs after clone. Generates Flutter's Generated.xcconfig and installs Pods
# so shareextentionxcode / Runner can resolve FLUTTER_BUILD_* and CocoaPods file lists.
set -e

cd "$CI_PRIMARY_REPOSITORY_PATH"

# Install Flutter SDK (not present on Xcode Cloud by default).
git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$HOME/flutter"
export PATH="$PATH:$HOME/flutter/bin"

flutter precache --ios
flutter pub get

# Ensure ios/Flutter/Generated.xcconfig exists with FLUTTER_BUILD_NAME/NUMBER.
flutter build ios --config-only --release

# Install CocoaPods dependencies (creates Target Support Files/*.xcfilelist).
HOMEBREW_NO_AUTO_UPDATE=1
brew install cocoapods
cd ios
pod install

exit 0
