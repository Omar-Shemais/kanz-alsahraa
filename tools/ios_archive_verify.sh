#!/bin/sh
# Run in Codemagic after flutter build ipa and before TestFlight publishing.
set -eu
archive="${1:-build/ios/archive/Runner.xcarchive}"
app="$archive/Products/Applications/Runner.app"
plist="$app/Info.plist"
buddy=/usr/libexec/PlistBuddy
test -f "$plist" || { echo 'Runner archive not found; provide the actual xcarchive path.' >&2; exit 1; }
test "$("$buddy" -c 'Print :CFBundleIdentifier' "$plist")" = 'com.khtwah.kanzalsahra'
test "$("$buddy" -c 'Print :CFBundleVersion' "$plist")" = "${KANZ_BUILD_NUMBER:?Build number is required}"
test "$("$buddy" -c 'Print :PROJECT_ID' "$app/GoogleService-Info.plist")" = 'kanz-alsahra'
# No unresolved template strings may remain in compiled app metadata.
if /usr/bin/plutil -convert xml1 -o - "$plist" | /usr/bin/grep -q '\${'; then
    echo 'Unresolved env.props placeholder in compiled Info.plist.' >&2
    exit 1
fi
entitlements_file=$(/usr/bin/mktemp -t kanz-entitlements)
trap 'rm -f "$entitlements_file"' EXIT HUP INT TERM
/usr/bin/codesign -d --entitlements :- "$app" > "$entitlements_file" 2>/dev/null
test "$("$buddy" -c 'Print :com.apple.developer.team-identifier' "$entitlements_file")" = 'T5T28K7SSZ'
test "$("$buddy" -c 'Print :aps-environment' "$entitlements_file")" = 'production'
test "$("$buddy" -c 'Print :com.apple.developer.applesignin:0' "$entitlements_file")" = 'Default'
"$buddy" -c 'Print :com.apple.developer.associated-domains' "$entitlements_file" | /usr/bin/grep -q 'applinks:kanzalsahra.com'
/usr/bin/codesign --verify --deep --strict "$app"
test -d "$archive/dSYMs/Runner.app.dSYM" || { echo 'Runner dSYM is missing.' >&2; exit 1; }
echo 'Signed archive identity, push, Apple login, links and dSYM checks passed. Device testing remains required.'
