# Implementation Plan: Kanz Al-Sahraa Mobile Remediation

**Specification Reference:** [`specs/kanz-remedy/spec.md`](file:///c:/Users/omar2/OneDrive/Desktop/kanz/specs/kanz-remedy/spec.md)  
**Methodology:** Spec-Driven Development (Spec Kit)  
**Execution Strategy:** Two-Tier Execution (Client-Side First, Backend Staging Second)  

---

## 1. Architectural Blueprint & Operational Boundary

The remediation strategy strictly respects the operational constraint:
**Current State: Client Flutter App Full Code Access | WordPress / WooCommerce Server Access Pending**

```
+-----------------------------------------------------------------------------------+
|                            PHASED EXECUTION ROADMAP                               |
+-----------------------------------------------------------------------------------+
|                                                                                   |
|  [TIER 1: FLUTTER APP CLIENT - IMMEDIATE EXECUTION]                               |
|  +-----------------------------------------------------------------------------+ |
|  | Phase 1: Security Hardening & RTL Localization       (Problems 8,10,12,13,  | |
|  |                                                       22,24,27,30,31,33,36, | |
|  |                                                       37,38) - [COMPLETE]   | |
|  +-----------------------------------------------------------------------------+ |
|  | Phase 2: Template Bloat Pruning & Dead Gateways      (Problems 4,5,15,25)   | |
|  +-----------------------------------------------------------------------------+ |
|  | Phase 3: Network Resilience & Error State UX         (Problems 1,3,8,23)    | |
|  +-----------------------------------------------------------------------------+ |
|  | Phase 4: Store Policy, Cart Rules & Guest Flow       (Problems 16,18,26,29) | |
|  +-----------------------------------------------------------------------------+ |
|  | Phase 5: Deep Linking, Push Notifications & DevOps   (Problems 14,17,21,28) | |
|  +-----------------------------------------------------------------------------+ |
|                                                                                   |
|  [TIER 2: WORDPRESS BACKEND INTEGRATION - STAGED PENDING CREDENTIALS]            |
|  +-----------------------------------------------------------------------------+ |
|  | Phase 6: WooCommerce REST Services, Digits & Sync     (Problems 2,6,9,11,    | |
|  |                                                       20,32,35)             | |
|  +-----------------------------------------------------------------------------+ |
+-----------------------------------------------------------------------------------+
```

---

## 2. Phased Execution Details

### Phase 1: Security Hardening, Defaults & Localization (Completed)
- **Status:** Done & Verified (0 Analyzer Errors)
- **Completed Components:**
  - Pluralization in `intl_ar.arb` and `messages_ar.dart` (Problem 36)
  - User-friendly Arabic messaging for Digits mobile login (Problem 33)
  - RTL-safe back and forward navigation icons across 15+ screens (Problem 10)
  - Package ID alignment to `com.khtwah.kanzalsahra` across configs & manifests (Problems 13 & 37)
  - APNs environment set to `production` in `configs/env.props` (Problem 22)
  - Saudi Arabia country & 13 administrative regions locked in `lib/env.dart` (Problems 12 & 38)
  - Keystore retry backoff for session storage in `secure_storage.dart` (Problem 8)
  - InAppWebView cache/cookie purge on logout & DENY default permissions (Problems 30 & 31)
  - Defer permission prompts & activate in-app update checks (Problems 24 & 27)

---

### Phase 2: Template Bloat Pruning & Dead Payment Gateways (Immediate)
- **Target Issues:** Problems 4, 5, 15, 25
- **Actions:**
  1. **Disable Unused Foreign Gateways:**
     - In `lib/env.dart`: Deactivate `razorpayConfig`, `tapConfig`, `mercadoPagoConfig`, `payTmConfig`, `payStackConfig`, `flutterwaveConfig`, `myFatoorahConfig`, `midtransConfig`.
     - In `lib/screens/checkout/mixins/checkout_mixin.dart`: Guard native payment checks so only `paymob`, `apple_pay`, and `bacs` (Bank Transfer) execute.
  2. **Deactivate Template Modules:**
     - Deactivate TikTok story scroller (`TikTokVideosView`) from dynamic homepage rendering.
     - Disable Multi-vendor marketplace views (Vendor dashboard, WCFM, Dokan) and delivery tracking routes.
     - Disable unused wallet, reward points, and wholesale modules.
  3. **Purge Demo/Placeholder Content:**
     - Clean template placeholder strings from help, privacy, and static web views.

---

### Phase 3: Offline Resilience, Error State UX & Catalog Robustness (Immediate)
- **Target Issues:** Problems 1, 3, 23
- **Actions:**
  1. **Network Error Distinction:**
     - Modify product and category fetchers to distinguish between an empty list (`[]`) and a network failure (`SocketException`, `TimeoutException`).
     - Display a localized Arabic retry widget ("تعذر الاتصال بالمتجر - اضغط لإعادة المحاولة") instead of a misleading "لا توجد منتجات".
  2. **Cart Checkout Timeout & Idempotency:**
     - Add a 10-second timeout on checkout preparation (matching spec.md), not on the active payment session; display a clear Arabic error and permit a deliberate retry.
     - Guard checkout submission with an idempotency lock to prevent duplicate order generation.
  3. **Client-Side Coupon Filtering:**
     - Filter out coupons where `dateExpires` is before `DateTime.now()` in coupon list UI.

---

### Phase 4: Cart & Store Policy Alignment (Immediate)
- **Target Issues:** Problems 16, 18, 26, 29
- **Actions:**
  1. **Order Cancellation & Returns:**
     - Hide cancellation button when order status is `processing`, `on-hold`, or `completed`.
     - Set return policy inquiry banner: Inform customers that returns are reviewed within 24 hours per gold trade regulations, replacing the automatic 7-day template return.
  2. **Special Product Cart Restrictions:**
     - Implement cart validation rule checking for restricted bullion/promotional items and restricting payment methods accordingly.
  3. **Guest Checkout & Order Lookup:**
     - If guest checkout is disallowed on the store, prompt account registration prior to entering the address step.
     - Add an "استعلام عن حالة الطلب" (Track Order by Number & Phone) screen for guest orders.

---

### Phase 5: Deep Linking, Push Notifications & DevOps (Immediate)
- **Target Issues:** Problems 14, 17, 21, 28
- **Actions:**
  1. **HTTPS Universal Links (Firebase Dynamic Links Replacement):**
     - Configure Android `assetlinks.json` and iOS `apple-app-site-association` universal link handling for `kanzalsahra.com/product/*`.
     - Remove obsolete Firebase Dynamic Links dependencies and initialize standard URL handler.
  2. **Push Token Account Association:**
     - Wire FCM token registration to dispatch on customer authentication state change.
  3. **Unified Support Channels:**
     - Update all in-app contact references to official Kanz Al-Sahraa WhatsApp and `support@kanzalsahra.com`.
  4. **Quality Gates:**
     - Create unit tests for cart calculations, Arabic pluralization, and checkout validation. Run `flutter test`.

---

### Phase 6: WordPress / WooCommerce Backend Staging (Deferred)
- **Target Issues:** Problems 2, 6, 9, 11, 20, 32, 35
- **Status:** Documented, Spec Ready, Staged for deployment once WP Admin / SSH / SFTP credentials are provided.
- **Components Staged:**
  - Reissuing WooCommerce REST API keys with least privilege & rotating old keys (Problem 6).
  - Deploying Kanz mobile helper endpoints (`wp-json/kanz/v1/...`) for account profile, account deletion, and custom order metadata (Problems 9 & 35).
  - WooCommerce persistent cart synchronization plugin/hook (Problem 20).
  - Gold attributes configuration (`pa_karat`, `pa_weight`) on WooCommerce products (Problem 11).
  - Catalog SKU audit to eliminate duplicate or blank SKUs on live database (Problem 32).
  - Digital OTP (Digits) API gateway setup and SMS provider credentials check (Problem 33).
  - Dynamic homepage layout JSON endpoint hosting (Problem 2).

---

## 3. Verification & Quality Assurance Gates

Every implementation phase must pass two strict gates before progressing:
1. **Static Analysis Gate:** `dart analyze` or `flutter analyze` must return **0 errors and 0 warnings** on all touched files.
2. **Runtime / Build Gate:** Flutter compilation and unit test suite must execute cleanly.
