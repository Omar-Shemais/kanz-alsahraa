#!/bin/sh
# macOS only. This command builds but does NOT upload app code to Shorebird.
set -eu
: "${SHOREBIRD_TOKEN:?Configure the encrypted Shorebird API key in CI}"
: "${KANZ_WOO_CONSUMER_KEY:?Configure the encrypted Woo key}"
: "${KANZ_WOO_CONSUMER_SECRET:?Configure the encrypted Woo secret}"
: "${KANZ_BUILD_NUMBER:?Specify the new store build number}"
: "${KANZ_FLUTTER_VERSION:=3.38.4}"
dart run tools/shorebird_config_guard.dart
test -f /Users/builder/export_options.plist || { echo 'Codemagic export options were not generated.' >&2; exit 1; }
shorebird release ios --dry-run \
    --flutter-version="$KANZ_FLUTTER_VERSION" \
    --build-number="$KANZ_BUILD_NUMBER" \
    --export-options-plist=/Users/builder/export_options.plist \
    --dart-define=KANZ_WOO_CONSUMER_KEY="$KANZ_WOO_CONSUMER_KEY" \
    --dart-define=KANZ_WOO_CONSUMER_SECRET="$KANZ_WOO_CONSUMER_SECRET"
