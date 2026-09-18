# Kanz App Control — local prototype, not deployed

Version 0.2.0. Preserve MStore API for account/commerce integration. Import the
current 11-section design into this editor before publication. Once the new
endpoint is tested, switch the app source ONCE and rebuild the control-aware
app; subsequent supported layout edits do not require rebuilding the app.
Do not keep editing both MStore's static upload and this independent endpoint:
choose one authoritative configuration source during rollout.

Local tests: 192 Flutter tests passed; 20 PHP checks and simulated DOM editor
checks passed. These do not verify a real WordPress installation or delivery.

## Implemented locally

- Arabic RTL WordPress admin UI, restricted to `manage_options`.
- Local JSON import; no remote fetching, no overwriting existing media files.
- Banner images chosen using WordPress media; banner/category item ordering.
- Add/remove/reorder home sections; edit category IDs and section names.
- Full JSON editor preserves unknown fields and prevents silently discarding unsaved JSON edits.
- Nonce-checked publication; revision conflict checks plus database publication lock.
- Last 20 prior publications retained; manual reviewed rollback through JSON import.
- Independent public GET `/wp-json/kanz/v1/config/ar`; no admin identity/history returned.
- Rejects recognized secret fields and executable script/javascript strings.
- Public configuration never substitutes for authenticated order/payment endpoints.

## Not implemented / not verified

- Notification delivery is NOT verified. A local FCM v1 sender, capability/nonce-checked form, broadcast acknowledgement, one-minute rate limit, publication lock and last-50-attempt history are implemented. Actual sending stays disabled until `KANZ_FCM_SERVICE_ACCOUNT_FILE` is configured by hosting staff to a service account OUTSIDE the public document root. No secret-upload form is provided. Google accepting a message does not prove device delivery. Private order notifications are NOT implemented.
- Forced updates are implemented locally using `KanzControl.updates.android/ios.enabled` and `minimumBuild` (integer, not version name). A startup gate compares the installed build and opens only the verified Kanz store listings. It captures the first startup config and deliberately ignores later changes in-session so home refresh cannot interrupt payment. Fresh remotely fetched policy therefore becomes effective on the next cold launch after caching. Test a minimum equal to the current build and then a higher build; never publish a requirement for a build unavailable in the store. Real Android/iOS device/store QA is pending.
- Preview on a real app and WordPress integration tests. Category selectors read WooCommerce categories when available, with an ID fallback and preservation of missing category IDs.
- WordPress deployment, backup verification, cache/CDN behaviour, and binding to the user's actual uploaded JSON URL.
- Full schema checks for every FluxStore layout; the current validation checks core shape and obvious dangerous content only.
- Crash-safe handling of a process killed while holding publication lock; do not auto-steal a lock. Diagnose before manually removing the lock option.

## Safe deployment sequence — do not install on live yet

1. Obtain the uploaded config URL, current MStore configuration and a verified recoverable backup.
2. Test against an isolated WordPress copy with the actual MStore/WooCommerce versions.
3. Install this folder as a plugin on that copy. Import the current `config_ar.json` locally, review, publish.
4. Test unauthorized access, nonce rejection, two-admin conflicts, malformed JSON, backups and rollback.
5. Configure the app's remote source to the NEW endpoint only after approval; retain packaged Arabic fallback.
6. Test startup online/offline, background refresh and ongoing checkout stability.
7. After approval and a recoverable backup, deploy on production. The existing uploaded file remains unchanged.

No app source URL has been changed to this unpublished endpoint.

## Firebase setup (hosting staff, not the client)

Keep the service account outside the public document root and out of this repo,
media uploads, the public JSON and the mobile app. Configure the absolute private
path using `KANZ_FCM_SERVICE_ACCOUNT_FILE` in the server's private configuration.
Enable the Firebase Cloud Messaging HTTP v1 API in the owner's existing app
project with least required sender permissions. Never paste credentials in chat.
Start with a separate test Firebase project/devices before broadcasting on live.
Only general marketing is sent to `all-notifications`; device notification
permissions, topic subscriptions and delivery still require real-device testing.

References: [FCM v1](https://firebase.google.com/docs/cloud-messaging/send/v1-api),
[WordPress permission callbacks](https://developer.wordpress.org/reference/functions/register_rest_route/).

## Confirmed existing source (2026-09-18)

The user's uploaded file is `https://kanzalsahra.com/wp-content/uploads/flutter_config_files/config_ar.json`.
A read-only GET returned HTTP 200, 11 home sections and four tabs. The app source
now points to this existing file in local code; the plugin endpoint remains
unpublished and is NOT used. Do not switch to the plugin endpoint until tested.
