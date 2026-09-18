#!/bin/sh
# Run from the repository root in Codemagic's pre-build phase.
set -eu
test -f pubspec.yaml || { echo 'Run from the Flutter project root.' >&2; exit 1; }
: "${KANZ_WOO_CONSUMER_KEY:?Add the encrypted Woo key in Codemagic}"
: "${KANZ_WOO_CONSUMER_SECRET:?Add the encrypted Woo secret in Codemagic}"
: "${KANZ_BUILD_NUMBER:?Set a build number greater than the latest uploaded build}"
case "$KANZ_BUILD_NUMBER" in ''|*[!0-9]*) echo 'Build number must be an integer.' >&2; exit 1;; esac
test "$KANZ_BUILD_NUMBER" -gt 22 || { echo 'Build number must exceed repository build 22 and the latest uploaded build.' >&2; exit 1; }
flutter pub get
dart run tools/prepare_build_dependencies.dart
dart run tools/shorebird_config_guard.dart
dart run tools/release_security.dart
flutter test --no-pub test/ios_release_configuration_test.dart test/release_security_test.dart test/notification_destination_test.dart test/build_dependency_compatibility_test.dart test/shorebird_configuration_test.dart
for file in ios/Runner/Info.plist ios/Runner/Runner.entitlements ios/GoogleService-Info.plist ios/PrivacyInfo.xcprivacy; do
    /usr/bin/plutil -lint "$file"
done
/bin/sh -n ios/pre-actions.sh
echo 'iOS source preflight passed. Signing, archive and device acceptance remain required.'
