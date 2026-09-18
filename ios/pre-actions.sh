#!/bin/sh
set -eu
: "${PROJECT_DIR:?Xcode PROJECT_DIR is required}"
config_file="$PROJECT_DIR/../configs/GoogleService-Info.plist"
test -f "$config_file" || { echo 'Missing Firebase iOS configuration.' >&2; exit 1; }
test -f "$PROJECT_DIR/../configs/env.props" || { echo 'Missing env.props.' >&2; exit 1; }
/usr/bin/plutil -lint "$config_file" >/dev/null
if ! /usr/bin/cmp -s "$config_file" "$PROJECT_DIR/GoogleService-Info.plist"; then
    /bin/cp "$config_file" "$PROJECT_DIR/GoogleService-Info.plist"
fi
# Config.xcconfig uses a committed relative include. Never overwrite reviewed code.
if [ -d "$PROJECT_DIR/../configs/customized/assets" ]; then
    /bin/cp -R "$PROJECT_DIR/../configs/customized/assets/." "$PROJECT_DIR/../assets/"
fi
