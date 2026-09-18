# Spec: Kanz Al-Sahraa Mobile Remediation & Production Readiness

**Document Status:** Approved & Active  
**Standard:** Spec-Driven Development (Spec Kit)  
**Target Application:** Kanz Al-Sahraa Flutter Client (`com.khtwah.kanzalsahra`)  
**Target Platform:** iOS & Android  
**Source Audit:** `output/pdf/تقرير_مشكلات_تطبيق_كنز_الصحراء_للعميل.pdf` (38 Audit Findings)  

---

## 1. Executive Summary & Context

The Kanz Al-Sahraa mobile application was derived from a generic multi-vendor e-commerce template (InspireUI FluxStore). An exhaustive audit revealed 38 distinct technical, architectural, operational, and user experience issues.

The primary operational constraint is that **backend WordPress credentials are not yet available to the development team**. Therefore, this specification strictly segregates:
1. **Client-Side (Flutter App) Remediations:** Architecture decoupling, payment gateway cleanup, security hardening, offline resilience, Saudi localized defaults, RTL ergonomics, and permission pruning. These can and must be executed immediately.
2. **Backend-Side (WordPress / WooCommerce) Integrations:** Custom REST endpoints, Digits OTP endpoints, account deletion lifecycle, cart synchronization webhooks, and live inventory SKU harmonization. These are formally specified and staged to execute immediately upon receiving credentials.

---

## 2. Problem Categorization & Detailed Specifications

### Domain A: Security, Secrets & Permissions (Problems 6, 7, 8, 30, 31, 34)

#### Issue 06: Live Store Keys Exposed in Source and Application Bundle
- **Problem:** WooCommerce consumer key and consumer secret with live read/write capabilities (`ck_...`, `cs_...`) were hardcoded in plain text in `lib/env.dart` and committed to version control.
- **Requirement:** Secrets must be excised from source code or injected securely via environment configuration / obfuscated variables. Reissue keys immediately on the live server and restrict permissions to least privilege.
- **Acceptance Criteria:** No plain-text production write secrets in client build artifacts; keys rotated on backend.

#### Issue 07: Excessive Permissions and Unneeded Device Capabilities
- **Problem:** Android and iOS app manifests request Location, Camera, Microphone, Bluetooth/NFC, and Ad ID permissions inherited from template plugins that Kanz Al-Sahraa does not use.
- **Requirement:** Prune unnecessary permissions from `AndroidManifest.xml` and `Info.plist`. Only request permissions at the moment of feature usage with an explanatory rationale.
- **Acceptance Criteria:** Manifests contain only essential permissions (Internet, Network State, Notification, Push). Camera/Storage restricted only to bank transfer receipt uploads.

#### Issue 08: Unstable Session Storage Handling
- **Problem:** Unhandled exceptions during encrypted local storage reads (`FlutterSecureStorage`) caused wiping of user session tokens and saved preferences on cold start.
- **Requirement:** Implement exponential retry and graceful recovery for hardware keystore access errors before falling back or wiping storage.
- **Acceptance Criteria:** Secure storage read failures retry up to 3 times before error handling; sessions persist stably across app restarts.

#### Issue 30: In-App Browser Session Bleed on Logout
- **Problem:** The InAppWebView utilized for checkout maintained cookies and web session tokens even after the user logged out of the Flutter app, allowing subsequent users on a shared device to access the previous account.
- **Requirement:** Explicitly clear WebView cache, cookies, local storage, and session data upon user logout and when navigating away from checkout.
- **Acceptance Criteria:** `AlwaysClearWebViewCache` and `AlwaysClearWebViewCookie` enabled; `dispose()` in `webview_inapp.dart` purges session cookies completely.

#### Issue 31: Over-Privileged In-App WebView Resource Requests
- **Problem:** WebView configuration granted unsolicited device resource requests (e.g. Geolocation, Media, Protected Media) automatically to any loaded URL.
- **Requirement:** Default action for WebView permission requests must be `PermissionResponseAction.DENY`. Only explicitly whitelisted origins on official Kanz domains may be granted permissions.
- **Acceptance Criteria:** InAppWebView denies all non-essential hardware access requests from third-party web content.

#### Issue 34: Privacy Policy & Store Disclosures Mismatch
- **Problem:** App store privacy declarations claimed location and cross-app tracking, whereas the live website policy only addressed web browsing.
- **Requirement:** Align app permissions, eliminate tracking SDKs, and provide unified privacy policy disclosures matching actual data practices.
- **Acceptance Criteria:** All tracking identifiers disabled; privacy disclosure matches Flutter manifest reality.

---

### Domain B: Checkout, Payments & Store Policy (Problems 1, 5, 12, 16, 18, 26, 29, 38)

#### Issue 01: Cart-to-Checkout Transition Freezes
- **Problem:** Transitioning from shopping cart to checkout can hang indefinitely on loading spinners when backend checkout helper endpoints are unavailable or slow, with no user-visible error or retry mechanism.
- **Requirement:** Implement robust connection timeouts, user-friendly fallback error dialogs in Arabic, and prevent duplicate order creation on network stutter.
- **Acceptance Criteria:** Network failure displays an informative Arabic dialog with an "إعادة المحاولة" (Retry) action within 10 seconds; no UI deadlocks.

#### Issue 05: Unused Foreign Payment Gateways in Codebase
- **Problem:** The app config and payment modules contain active code and configurations for Paytm, Razorpay, Paystack, Flutterwave, MercadoPago, and Midtrans, while Kanz Al-Sahraa only uses Paymob, Apple Pay, and Bank Transfer.
- **Requirement:** Disable and remove references to unused third-party payment modules from `lib/env.dart`, `configurations.dart`, and `checkout_mixin.dart`.
- **Acceptance Criteria:** Only Paymob, Apple Pay, and Bank Transfer are initialized or selectable; foreign SDK initialization code removed.

#### Issue 12 & 38: Saudi Arabian Address & Shipping Defaults
- **Problem:** Shipping address forms defaulted to United States (Louisiana) and allowed customers to select countries outside Saudi Arabia, causing checkout rejections.
- **Requirement:** Lock default country to Saudi Arabia (`SA`, `RIY`), restrict allowed shipping destinations strictly to `SA`, and pre-populate the 13 Saudi provinces/administrative regions locally.
- **Acceptance Criteria:** Address form defaults to Saudi Arabia; country dropdown locked to SA; Saudi provinces listed in Arabic even when offline.

#### Issue 16: Order Cancellation & Return Policy Discrepancies
- **Problem:** App displayed "Cancel Order" buttons for orders in processing and allowed return requests up to 7 days for all payment methods, violating Kanz Al-Sahraa's policy (no cancellation post-confirmation; returns within 24 hours under strict conditions).
- **Requirement:** Adjust app configuration and UI logic so orders cannot be cancelled once status is "processing"; return requests submit an inquiry to customer service rather than auto-updating order status.
- **Acceptance Criteria:** Cancellation button hidden for processing orders; return window strictly configured to 24h with explanatory terms displayed.

#### Issue 18: Special Promotional Rules Not Enforced in Cart
- **Problem:** Certain promotional offers (e.g. exclusive bank transfer gold bullion) require dedicated ordering, but the app allowed mixing them with standard products and standard payment methods.
- **Requirement:** Validate cart contents at checkout initiation; display warning banner and enforce required payment method if restricted items are present.
- **Acceptance Criteria:** Cart validation rule detects restricted product IDs/categories and restricts checkout payment options accordingly.

#### Issue 26: Guest Order Tracking Lost on Device Wipe
- **Problem:** Unauthenticated guest orders were stored only in local device shared preferences.
- **Requirement:** Provide a secure "استعلام عن طلب" (Track Order by Order ID + Phone/Email) screen, enabling guest customers to view order status without needing stored local device state.
- **Acceptance Criteria:** Guest order lookup screen functional with Order Number and Billing Phone verification.

#### Issue 29: Guest Checkout Conflicts with Live Store Settings
- **Problem:** The app allowed starting checkout as a guest, but the live WooCommerce store rejected the final order creation because account creation was mandated.
- **Requirement:** Align app guest checkout setting with store policy: prompt login/registration before entering checkout flow if guest checkout is disabled on WooCommerce.
- **Acceptance Criteria:** Clear registration gate prior to checkout if guest purchases are disallowed by backend.

---

### Domain C: Arabic Localization & User Experience (Problems 10, 19, 33, 36)

#### Issue 10: RTL Navigation & Directional Flow Flaws
- **Problem:** Several screens exhibited hardcoded LTR chevron icons (`arrow_back_ios`, `arrow_forward_ios`) and inverted edge insets, causing awkward visual ergonomics in Arabic RTL mode.
- **Requirement:** Use directionally-aware helper methods (`Tools.getBackIcon(context)`) and `EdgeInsetsDirectional` across all navigation headers and buttons.
- **Acceptance Criteria:** All back buttons point right in RTL (Arabic) and left in LTR (English); zero inverted navigation arrows across all 40+ app screens.

#### Issue 19: Incomplete English Storefront Experience
- **Problem:** Switching to English changed basic UI buttons while categories, banners, and product descriptions remained entirely in Arabic.
- **Requirement:** Lock application to Arabic primary locale or clearly manage bilingual fallback so untranslated backend content does not produce broken visual dissonance.
- **Acceptance Criteria:** Consistent RTL Arabic default; language selection accurately manages localized UI strings.

#### Issue 33: Raw Technical WordPress Plugin Error Messages
- **Problem:** Phone number login failures displayed technical error messages referencing `"Digits plugin is not installed on your WordPress site"` directly to end consumers.
- **Requirement:** Replace technical plugin errors with graceful Arabic customer service messages directing users to standard login or phone support.
- **Acceptance Criteria:** No plugin, PHP, or WordPress stack trace exposed to end-users in UI toasts or dialogs.

#### Issue 36: Broken Arabic Pluralization in Order History
- **Problem:** Order history cards displayed `"1 items"` or `"2 item"` with literal English strings concatenated to Arabic text.
- **Requirement:** Implement proper Arabic grammatical plural categories (`zero`, `one`, `two`, `few`, `many`, `other`) in `.arb` localization files and generated messages.
- **Acceptance Criteria:** 1 قطعة, قطعتان, 3 قطع, 15 قطعة displayed accurately according to Arabic grammar rules.

---

### Domain D: Product Attributes, Search & Caching (Problems 2, 3, 11, 32)

#### Issue 02: Home Layout & Banner Sync Delays
- **Problem:** Dynamic homepage sections, banners, and layouts stored inside local JSON bundles failed to update when marketing banners changed on the web store.
- **Requirement:** Implement a resilient remote configuration cache strategy that checks for updated layout configurations on startup while maintaining an instantaneous offline fallback.
- **Acceptance Criteria:** Remote layout loads when network is available; fallback bundle loads smoothly offline without crashes.

#### Issue 03: Outdated Product Pricing, Stock & Error Handling
- **Problem:** When network timeouts occur, the app displayed an empty store screen ("No products found") rather than identifying the connectivity issue and providing a retry option.
- **Requirement:** Differentiate between empty catalog responses (HTTP 200 with `[]`) and connection failures (SocketException / Timeout). Display dedicated Arabic retry widgets for network errors.
- **Acceptance Criteria:** Connection failure renders a dedicated retry screen; products and prices cache with appropriate TTL (Time-To-Live).

#### Issue 11: Gold & Jewelry Product Specifications & Attribute Filters
- **Problem:** Critical gold jewelry attributes (Karat / العيار, Gram Weight / الوزن, Craftsmanship Fee / المصنعية) were buried in unstructured descriptions or missing from facet filters.
- **Requirement:** Parse WooCommerce product attributes (`pa_karat`, `pa_weight`, `pa_craftsmanship`) and render dedicated badge UI on product details and filter sheets.
- **Acceptance Criteria:** Dedicated specification table for gold attributes on product cards and filter sheets.

#### Issue 32: Duplicate and Missing Product SKUs
- **Problem:** Search by SKU returned conflicting items because certain products shared duplicate SKUs or lacked SKUs entirely.
- **Requirement:** Sanitize client-side SKU search query handling and filter out duplicate SKU collisions; stage backend SKU audit task.
- **Acceptance Criteria:** SKU search yields precise, non-conflicting product matches.

---

### Domain E: Architecture, Template Bloat & Packaging (Problems 4, 15, 25, 28)

#### Issue 04 & 15: Template Bloat, Unused Dependencies & Modular Pruning
- **Problem:** The repository contained extensive modules for multi-vendor marketplaces (WCFM, Dokan), delivery boy tracking, TikTok story video scroller, crypto/wallet balances, and reward points.
- **Requirement:** Disable unused modules in `lib/env.dart` and `pubspec.yaml`; remove unused routes from router to reduce app size and attack surface.
- **Acceptance Criteria:** TikTok scroller, multi-vendor routes, and dead payment SDKs deactivated; bundle size reduced.

#### Issue 25: Template Placeholder Strings & Demo Content
- **Problem:** Help and contact web views displayed template placeholder copy (`"ADD ANYTHING HERE OR JUST REMOVE IT"`) and sample foreign flag icons.
- **Requirement:** Purge all demo text from in-app HTML pages and configure exact Kanz Al-Sahraa official contact endpoints.
- **Acceptance Criteria:** Clean branded help and contact views with zero template lorem ipsum.

#### Issue 28: Inconsistent Customer Support Contact Channels
- **Problem:** Store listings, contact forms, and privacy documents listed conflicting support email addresses (`info@khtwah.com`, `info@kanzalsahra.com`, `support@kanzalsahra.com`).
- **Requirement:** Standardize on official Kanz Al-Sahraa support channels across all app configs, contact buttons, and email links.
- **Acceptance Criteria:** Unified support email and official WhatsApp number across entire codebase.

---

### Domain F: Configuration, Push Notifications & DevOps (Problems 13, 14, 17, 20, 21, 22, 23, 24, 27, 35, 37)

#### Issues 13 & 37: Application Package ID & Bundle Identifier Harmonization
- **Problem:** Multiple package names existed across files (`com.kanzalsahra.store` vs `com.khtwah.kanzalsahra` in AndroidManifests, Fastlane, and app rating configs).
- **Requirement:** Unify package ID to `com.khtwah.kanzalsahra` across all Android and iOS build descriptors.
- **Acceptance Criteria:** Complete consistency across `lib/env.dart`, `AndroidManifest.xml`, `Appfile`, and ratings configurations.

#### Issue 14: Quality Gates & Automated Testing
- **Problem:** Zero automated unit or integration tests existed, allowing regression during updates.
- **Requirement:** Establish baseline unit tests for critical business logic (currency formatting, Arabic pluralization, secure storage fallback, checkout validation) and automated CI analysis.
- **Acceptance Criteria:** Test suite runs via `flutter test` with passing status.

#### Issue 17: User-Specific vs Broadcast Push Notifications
- **Problem:** All devices subscribed to global broadcast topics; no user ID association existed for transactional order status updates.
- **Requirement:** Associate device push tokens with customer ID upon login; unsubscribe and disassociate upon logout.
- **Acceptance Criteria:** Device token registration service maps FCM/APNs token to customer account.

#### Issue 20: Cart Synchronization Between Web and App
- **Problem:** Cart items added on the website did not sync to the mobile app upon logging in, and vice versa.
- **Requirement:** Integrate WooCommerce persistent cart API so user cart syncs on customer authentication.
- **Acceptance Criteria:** Cart merges with server cart upon login without item duplication.

#### Issue 21: Deprecated Firebase Dynamic Links Replacement
- **Problem:** Product sharing relied on Firebase Dynamic Links, which Google deprecated in 2025.
- **Requirement:** Migrate to standard universal HTTPS deep links on `kanzalsahra.com/product/...`.
- **Acceptance Criteria:** Standard HTTPS deep link handler in Flutter client parsing product slugs without Firebase Dynamic Links SDK.

#### Issue 22: iOS APNs Push Environment Configuration
- **Problem:** `iosApsEnvironment` was set to `unknown` in build properties.
- **Requirement:** Set `iosApsEnvironment=production` for release builds.
- **Acceptance Criteria:** `configs/env.props` configured to `production`.

#### Issue 23: Expired Coupon Filtering
- **Problem:** Coupon list view attempted to display expired promotional vouchers.
- **Requirement:** Filter coupons client-side before rendering; verify expiry dates and user restrictions.
- **Acceptance Criteria:** Expired coupons excluded from the selectable coupon list.

#### Issue 24: Premature Permission Prompts
- **Problem:** App requested notification and tracking permissions on initial app launch before the user even viewed a product.
- **Requirement:** Suppress initial startup notification popups; defer until user places an order or completes login.
- **Acceptance Criteria:** `showRequestNotification: false` on startup.

#### Issue 27: In-App Version Update Checker
- **Problem:** Version check and in-app update mechanisms were deactivated in configuration.
- **Requirement:** Enable store version check and Android in-app update prompt for critical releases.
- **Acceptance Criteria:** `versionCheck.enable: true` and `inAppUpdateForAndroid.enable: true`.

#### Issue 35: Account Deletion Implementation (Apple App Store Guideline 5.1.1)
- **Problem:** Account deletion button failed because backend deletion endpoint was missing from WordPress.
- **Requirement:** Provide graceful in-app confirmation modal with support ticket dispatch until WordPress REST deletion endpoint is deployed.
- **Acceptance Criteria:** Deletion flow clearly warns user, confirms intent, and dispatches request reliably.
