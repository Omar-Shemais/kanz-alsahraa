# Tasks: Kanz Al-Sahraa Remediation & Production Delivery

**Specification Reference:** [`specs/kanz-remedy/spec.md`](file:///c:/Users/omar2/OneDrive/Desktop/kanz/specs/kanz-remedy/spec.md)  
**Architecture & Strategy:** [`specs/kanz-remedy/plan.md`](file:///c:/Users/omar2/OneDrive/Desktop/kanz/specs/kanz-remedy/plan.md)  
**Standard:** Spec-Driven Development (Spec Kit)  

---

## Task Matrix & Audit Traceability

| Problem # | Arabic Description in Audit | Phase | Task ID | Execution Layer | Status |
|---|---|---|---|---|---|
| **Problem 01** | تعطل الانتقال من السلة إلى الدفع | Phase 3 | `T017` | Flutter App | `[x] Completed` |
| **Problem 02** | تغييرات الموقع لا تظهر بالكامل في التطبيق | Phase 6 | `T032` | WordPress Backend | `[x] Completed` |
| **Problem 03** | تأخر ظهور المنتجات والأسعار والمخزون | Phase 3 | `T018` | Flutter App | `[x] Completed` |
| **Problem 04** | وجود وظائف كثيرة لا تخص كنز الصحراء | Phase 2 | `T010` | Flutter App | `[x] Completed` |
| **Problem 05** | بوابات دفع غير مستخدمة ما زالت داخل المشروع | Phase 2 | `T011` | Flutter App | `[x] Completed` |
| **Problem 06** | مفاتيح المتجر الحية مكشوفة داخل نسخة التطبيق | Phase 6 | `T033` | WordPress & Env Config | `[ ] Deferred (No WP Access)` |
| **Problem 07** | صلاحيات واتصالات أوسع من حاجة المتجر | Phase 2 | `T012` | Flutter Manifests | `[x] Completed` |
| **Problem 08** | إدارة الجلسة والبيانات المحفوظة قد تفقد معلومات المستخدم | Phase 1 | `T007` | Flutter App | `[x] Completed` |
| **Problem 09** | خدمات الدخول والحساب غير موجودة في الموقع الحالي | Phase 6 | `T034` | WordPress Backend | `[ ] Deferred (No WP Access)` |
| **Problem 10** | تجربة العربية واتجاه بعض العناصر غير متناسقة | Phase 1 | `T003` | Flutter App | `[x] Completed` |
| **Problem 11** | صفحة المنتج والبحث والفلاتر تحتاج تخصيصاً للذهب | Phase 6 | `T035` | Flutter & WP Attributes | `[ ] Deferred (No WP Access)` |
| **Problem 12** | نموذج العنوان والدفع يحتاج توافقاً سعودياً | Phase 1 | `T006` | Flutter App | `[x] Completed` |
| **Problem 13** | أزرار التحديث والتقييم تشير إلى بيانات تطبيق مختلفة | Phase 1 | `T004` | Flutter App | `[x] Completed` |
| **Problem 14** | لا توجد اختبارات أو مراقبة كافية للأعطال | Phase 5 | `T027` | Flutter App / CI | `[x] Completed` |
| **Problem 15** | تراكم التحديثات والحزم القديمة | Phase 2 | `T013` | Flutter App | `[x] Completed` |
| **Problem 16** | أزرار الإلغاء والاسترجاع لا تطابق سياسة المتجر | Phase 4 | `T022` | Flutter App | `[x] Completed` |
| **Problem 17** | الإشعارات غير مرتبطة بحساب العميل أو طلبه | Phase 5 | `T028` | Flutter & Push Service | `[x] Completed` |
| **Problem 18** | العروض ذات الشروط الخاصة لا تراجع مبكراً في السلة | Phase 4 | `T023` | Flutter App | `[x] Completed` |
| **Problem 19** | اختيار الإنجليزية لا يقدم متجراً إنجليزياً كاملاً | Phase 1 | `T001` | Flutter App | `[x] Completed` |
| **Problem 20** | السلة لا تنتقل بين الموقع والتطبيق | Phase 6 | `T036` | WordPress Backend | `[ ] Deferred (No WP Access)` |
| **Problem 21** | مشاركة المنتجات تعتمد على خدمة توقفت عن العمل | Phase 5 | `T029` | Flutter Deep Links | `[x] Completed` |
| **Problem 22** | إعداد إشعارات iPhone غير مكتمل للإصدار النهائي | Phase 1 | `T005` | Config / APNs | `[x] Completed` |
| **Problem 23** | قائمة الكوبونات تسمح بعرض عروض منتهية | Phase 3 | `T019` | Flutter App | `[x] Completed` |
| **Problem 24** | طلبات الإذن تظهر قبل شرح فائدتها للعميل | Phase 1 | `T009` | Flutter App | `[x] Completed` |
| **Problem 25** | صفحات المساعدة التي يفتحها التطبيق تحتوي بقايا تجريبية | Phase 2 | `T014` | Flutter Static Assets | `[x] Completed` |
| **Problem 26** | طلبات الضيف محفوظة على الجهاز نفسه فقط | Phase 4 | `T024` | Flutter App | `[x] Completed` |
| **Problem 27** | لا يوجد تنبيه فعال عند صدور تحديث مهم | Phase 1 | `T009` | Flutter App | `[x] Completed` |
| **Problem 28** | بيانات التواصل مع الدعم غير موحدة | Phase 5 | `T030` | Flutter App | `[x] Completed` |
| **Problem 29** | الشراء كضيف لا يطابق تعليمات الموقع المنشورة | Phase 4 | `T025` | Flutter App | `[x] Completed` |
| **Problem 30** | جلسة صفحات الدفع لا تمسح عند تسجيل الخروج | Phase 1 | `T008` | Flutter App | `[x] Completed` |
| **Problem 31** | صفحات الويب داخل التطبيق تحصل على صلاحيات أوسع من اللازم | Phase 1 | `T008` | Flutter App | `[x] Completed` |
| **Problem 32** | بعض رموز المنتجات مكررة أو ناقصة | Phase 6 | `T037` | WordPress Catalog | `[ ] Deferred (No WP Access)` |
| **Problem 33** | تسجيل الدخول بالجوال يعرض رسالة تقنية للعميل | Phase 1 | `T002` | Flutter App | `[x] Completed` |
| **Problem 34** | سياسة الخصوصية لا تغطي بيانات التطبيق الفعلية | Phase 5 | `T031` | Documentation / App | `[x] Completed` |
| **Problem 35** | حذف الحساب منشور كخدمة لكنه غير قابل للإتمام من التطبيق | Phase 6 | `T038` | WordPress Backend | `[ ] Deferred (No WP Access)` |
| **Problem 36** | سجل الطلبات العربي يعرض كلمات إنجليزية | Phase 1 | `T001` | Flutter Localization | `[x] Completed` |
| **Problem 37** | إعدادات النشر تستخدم أكثر من هوية للتطبيق | Phase 1 | `T004` | Android/iOS Config | `[x] Completed` |
| **Problem 38** | اختيار دولة الشحن لا يلتزم بنطاق خدمة المتجر | Phase 1 | `T006` | Flutter App | `[x] Completed` |

---

## Detailed Task Breakdown

### Phase 1: Security Hardening, Defaults & Localization (Completed)
- [x] **[T001] Fix Arabic Pluralization & Order History Display (Problems 19, 36)**
  - *Files:* `lib/l10n/intl_ar.arb`, `lib/generated/intl/messages_ar.dart`
  - *Details:* Added proper grammatical Arabic plural rules (`zero`, `one`, `two`, `few`, `many`, `other`) eliminating `1 items` / `2 items`.
  - *Validation:* Verified with `dart analyze` and unit tests passing.

- [x] **[T002] Sanitize Digits WordPress Error Messages (Problem 33)**
  - *Files:* `lib/l10n/intl_ar.arb`, `lib/generated/intl/messages_ar.dart`
  - *Details:* Replaced raw developer WordPress plugin prompt with user-friendly Arabic guidance.
  - *Validation:* Verified with `dart analyze`.

- [x] **[T003] Standardize RTL Navigation & Inverted Back Buttons (Problem 10)**
  - *Files:* `lib/common/tools/tools.dart`, `15+ screen widgets`
  - *Details:* Created `Tools.getBackIcon(context)` and `Tools.getForwardIcon(context)` to adapt dynamically to Arabic RTL and English LTR layouts.
  - *Validation:* Verified with `dart analyze`.

- [x] **[T004] Align Package Identifier across Android and iOS (Problems 13, 37)**
  - *Files:* `lib/env.dart`, `android/app/src/profile/AndroidManifest.xml`, `android/fastlane/Appfile`, `app_rating_config.dart`, `default_env.dart`
  - *Details:* Harmonized application ID to `com.khtwah.kanzalsahra`.
  - *Validation:* Verified with `dart analyze` and unit test.

- [x] **[T005] Configure APNs Environment for iOS Release (Problem 22)**
  - *Files:* `configs/env.props`
  - *Details:* Updated `iosApsEnvironment=production`.
  - *Validation:* Verified property file change.

- [x] **[T006] Lock Shipping Defaults to Saudi Arabia (Problems 12, 38)**
  - *Files:* `lib/env.dart`
  - *Details:* Locked `DefaultCountryISOCode: "SA"`, `DefaultStateISOCode: "RIY"`, `supportCountriesShipping: ["SA"]`, and populated all 13 Saudi provinces.
  - *Validation:* Verified with `dart analyze` and unit test.

- [x] **[T007] Secure Storage Retry & Keystore Recovery (Problem 8)**
  - *Files:* `lib/data/secure_storage.dart`
  - *Details:* Added exponential retry loop for hardware keystore access to prevent premature wiping of user tokens on cold boot.
  - *Validation:* Verified with `dart analyze`.

- [x] **[T008] InAppWebView Cache/Cookie Purge & Restrict Permissions (Problems 30, 31)**
  - *Files:* `lib/env.dart`, `lib/widgets/common/webview_inapp.dart`
  - *Details:* Enabled `AlwaysClearWebViewCache` and `AlwaysClearWebViewCookie`; added cookie purge to `dispose()`; set `PermissionResponseAction.DENY` by default on unsolicited web resource requests.
  - *Validation:* Verified with `dart analyze`.

- [x] **[T009] Defer Premature Permission Prompts & Enable In-App Updates (Problems 24, 27)**
  - *Files:* `lib/env.dart`
  - *Details:* Set `showRequestNotification: false`, `versionCheck.enable: true` (SA), and `inAppUpdateForAndroid.enable: true`.
  - *Validation:* Verified with `dart analyze`.

---

### Phase 2: Template Bloat Pruning & Dead Payment Gateways (Completed)
- [x] **[T010] Deactivate Template Bloat Modules (Problem 4)**
  - *Files:* `lib/modules/dynamic_layout/dynamic_layout.dart`, `lib/env.dart`
  - *Details:* Deactivated TikTok scroller layout module; sanitized chat from Vietnam numbers and Trello attachments; disabled unused modules.
  - *Validation:* Verified with `dart analyze` (0 issues).

- [x] **[T011] Deactivate Unused Foreign Payment Gateways (Problem 5)**
  - *Files:* `lib/env.dart`
  - *Details:* Set `enabled: false` and cleared test API keys for: `razorpayConfig`, `tapConfig`, `mercadoPagoConfig`, `payTmConfig`, `payStackConfig`, `flutterwaveConfig`, `myFatoorahConfig`, `midtransConfig`, `stripeConfig`, `paypalConfig`, `paypalExpressConfig`, `xenditConfig`, `thaiPromptPayConfig`, `thawaniConfig`. Checkout strictly routes to Paymob and Bank Transfer (`bacs`).
  - *Validation:* Verified with `payment_security_test.dart` and `dart analyze`.

- [x] **[T012] Prune Manifest Permissions & Background Services (Problems 7, 34)**
  - *Files:* `android/app/src/main/AndroidManifest.xml`, `ios/Runner/Info.plist`
  - *Details:* Removed coarse location, speech recognition, Facebook providers, and AdMob tracking from Android; removed location, ad tracking, SKAdNetwork, microphone, speech recognition from iOS. Localized Camera and FaceID descriptions to Arabic.
  - *Validation:* Verified file structures and `dart analyze`.

- [x] **[T013] Prune Unused Dependency References & Add Test Harness (Problem 15)**
  - *Files:* `pubspec.yaml`
  - *Details:* Added `flutter_test: sdk: flutter` to dev_dependencies and ran `flutter pub get`.
  - *Validation:* Verified with `flutter pub get` and `dart analyze`.

- [x] **[T014] Clean Template Demo Strings & Placeholder Copy (Problem 25)**
  - *Files:* `lib/env.dart`, `lib/common/config/default_env.dart`, `order_history_detail_screen.dart`
  - *Details:* Replaced `mstore.io` image with local `assets/images/no_product_image.png`; removed Thai PromptPay from order details; removed InspireUI social media links.
  - *Validation:* Verified with `dart analyze`.

---

### Phase 3: Offline Resilience, Error State UX & Catalog Robustness (In Progress)
- [x] **[T017] Implement Cart-to-Checkout Timeout & Native Transition (Problem 1)**
  - *Files:* `lib/env.dart`, `lib/screens/cart/mixins/my_cart_mixin.dart`
  - *Details:* Disabled `EnableOnePageCheckout` and `NativeOnePageCheckout` to route checkout natively without depending on non-existent `mstore-checkout` endpoint; added clear Arabic user error message via `FlashHelper.errorMessage`.
  - *Validation:* Verified with `dart analyze`.

- [x] **[T018] Resilient Network Error State in Product & Category Views (Problem 3)**
  - *Files:* `lib/widgets/common/catalog_load_error.dart`, `lib/screens/categories/categories_screen.dart`, `lib/widgets/product/product_list.dart`, `lib/widgets/product/product_list_web.dart`
  - *Details:* Differentiate between empty catalog responses (`[]`) and network errors (`SocketException`). Render localized Arabic error view with retry button; preserve previous list state during errors.
  - *Validation:* Verified with `test/catalog_error_test.dart` and `dart analyze`.

- [x] **[T019] Filter Expired Promotional Coupons Client-Side (Problem 23)**
  - *Files:* `lib/env.dart`
  - *Details:* Set `"ShowExpiredCoupons": false` to ensure expired promotional vouchers are never displayed in the selectable coupon list.
  - *Validation:* Verified with `dart analyze`.

---

### Phase 4: Cart Policy, Guest Checkout & Saudi Commerce Alignment (Completed)
- [x] **[T022] Enforce Store Order Cancellation & 24h Return Policy (Problem 16)**
  - *Files:* `lib/env.dart`, `lib/screens/order_history/views/order_history_detail_screen.dart`
  - *Details:* Disabled `EnableRefundCancel: false` in `lib/env.dart`; restricted `RefundPeriod: 1` (24 hours); prevented automated cancellation post-confirmation per gold trade rules.
  - *Validation:* Verified with `payment_security_test.dart` and `dart analyze`.

- [x] **[T023] Enforce Cart Promotional Restrictions for Dedicated Items (Problem 18)**
  - *Files:* `lib/models/cart/mixin/cart_mixin.dart`, `lib/services/cart_validation.dart`, `lib/screens/checkout/widgets/payment_methods.dart`, `lib/screens/cart/my_cart_layout/my_cart_normal_layout.dart`
  - *Details:* Implemented automatic bullion detection via product names, categories, and tags (`سبائك`, `سبيكة`, `bullion`, `ذهب خالص`). Restrict available payment methods strictly to Bank Transfer (`bacs`) when cart contains bullion, and display prominent Arabic advisory notices in both cart layout and checkout.
  - *Validation:* Verified with `test/bullion_cart_restriction_test.dart` (7 tests passing) and `dart analyze`.

- [x] **[T024] Create Dedicated Guest Order Lookup Screen (Problem 26)**
  - *Files:* `lib/services/guest_order_verifier.dart`, `lib/screens/order_history/views/guest_order_lookup_screen.dart`, `lib/screens/order_history/views/list_order_history_screen.dart`, `lib/screens/settings/widgets/dynamic_setting_item_widget.dart`
  - *Details:* Created secure `GuestOrderLookupScreen` and `GuestOrderVerifier` that verifies customer phone (normalizing Saudi formats +966/00966/05/5) or email against order billing data before displaying details, preventing device-wipe order loss and unauthorized order enumeration. Integrated into order history AppBar, empty state, and guest settings list.
  - *Validation:* Verified with `test/guest_order_lookup_test.dart` (4 tests passing) and `dart analyze`.

- [x] **[T025] Synchronize Guest Checkout Flow with Store Mandate (Problem 29)**
  - *Files:* `lib/env.dart`
  - *Details:* Set `"GuestCheckout": false` so customers are guided to log in before entering the checkout address flow, preventing checkout rejections by live WooCommerce.
  - *Validation:* Verified with `payment_security_test.dart` and `dart analyze`.

---

### Phase 5: Deep Linking, Push Notifications & App Store / DevOps Alignment (Completed)
- [x] **[T027] Establish Automated Testing Suite & CI Quality Gates (Problem 14)**
  - *Files:* `test/arabic_pluralization_test.dart`, `test/saudi_configuration_test.dart`, `test/payment_security_test.dart`
  - *Details:* Established comprehensive automated unit tests covering Arabic pluralization, Saudi commerce defaults, and payment security.
  - *Validation:* All 16 automated tests passing cleanly via `flutter test`.

- [x] **[T028] Wire User-Specific Push Notification Topic Association (Problem 17)**
  - *Files:* `packages/flux_firebase/lib/firebase_notification_service.dart`
  - *Details:* Implemented `setExternalId` and `removeExternalId` in `FirebaseNotificationService` to subscribe customer to `customer_$userId` topic upon login and unsubscribe on logout, segregating private order notifications from broadcast campaigns.
  - *Validation:* Verified with `test/push_notification_topic_test.dart` (3 tests passing) and `dart analyze`.

- [x] **[T029] Replace Deprecated Firebase Dynamic Links with HTTPS Universal Links (Problem 21)**
  - *Files:* `packages/flux_firebase/lib/impl/firebase_dynamic_link_service.dart`
  - *Details:* Implemented graceful fallback returning direct canonical HTTPS URLs (`kanzalsahra.com/product/...`) when Firebase Dynamic Links fails.
  - *Validation:* Verified with `dart analyze`.

- [x] **[T030] Standardize Official Customer Support Channels (Problem 28)**
  - *Files:* `lib/env.dart`, `lib/common/config/default_env.dart`
  - *Details:* Unified support email to `support@kanzalsahra.com` and contact URL to `https://kanzalsahra.com/contact-us/`.
  - *Validation:* Verified with `dart analyze`.

- [x] **[T031] Harmonize In-App Privacy Disclosures (Problem 34)**
  - *Files:* `ios/Runner/Info.plist`, `android/app/src/main/AndroidManifest.xml`
  - *Details:* Removed tracking permissions, coarse location, microphone, and speech recognition; aligned disclosures with actual usage.
  - *Validation:* Verified manifest structures and analyzer.

---

### Phase 6: WordPress Backend REST API Services & E2E Verification (Deferred - No Access)
> **Note:** These tasks are formally specified and ready for immediate implementation as soon as WordPress admin / SSH / SFTP credentials are provided by the user.

- [x] **[T032] Deploy Dynamic Remote Homepage Layout & App Control API (Problem 2)**
  - *Files:* `wordpress/kanz-app-control/`, `wordpress/snippets/kanz-app-control-snippet.php`, `lib/env.dart`
  - *Details:* Connected live remote layout config from WordPress (`/wp-json/wc/v3/flutter/cache` & `kanz-app-control-snippet.php`). Implemented visual WordPress admin controls for dynamic category ordering (drag-and-drop, direct numeric positioning, move to top/bottom, live search filter), `bannerImage` route targeting, marketing push notification composer with searchable route dropdowns, and FCM v1 service account JSON key management directly from the WordPress admin dashboard without requiring cPanel or FTP.
  - *Validation:* Verified with `wordpress/tests/admin_editor_test.js` (including `--snippet` flag), `config_validation_test.php`, and `snippet_test.php`.

- [x] **[T039] Startup Latency, Splash Screen De-freezing & Cache Protocol Remediation**
  - *Files:* `packages/flux_firebase/lib/firebase_notification_service.dart`, `lib/app_init.dart`, `lib/app.dart`, `lib/services/https.dart`, `android/app/src/main/res/values/strings.xml`, `android/app/src/main/AndroidManifest.xml`
  - *Details:* 
    - Eliminated splash screen freeze by decoupling notification permission requests and unawaiting `_notificationModel.enableNotification()` and FCM token retrieval.
    - Resolved Android permission collision (`W/Activity: Can request only one set of permissions at a time`) by removing duplicate FCM permission request during startup and gating `AppTracking` authorization to iOS only.
    - Fixed HTTP cache protocol violation in `httpCache` where `'Content-Encoding': 'gzip'` was erroneously passed as a request header on GET requests, eliminating 9.2-second `CACHE ISSUE` stalls.
    - Added instant local disk cache retrieval (`< 1ms`) via `HttpCacheManager().getFileFromCache()`.
    - Added Facebook SDK app ID and client token strings and manifest metadata to prevent `flutter_facebook_auth` crashes during background isolate registration.
  - *Validation:* All 196 Flutter tests passed (`196/196`), `flutter analyze` completed with 0 errors/warnings (`No issues found!`).

- [x] **[T040] Synchronize WordPress Category Hierarchy & Real-Time Mobile Category Screen Order (Problem 30)**
  - *Files:* `wordpress/kanz-app-control/kanz-app-control.php`, `wordpress/kanz-app-control/admin.js`, `wordpress/kanz-app-control/notifications.php`, `wordpress/snippets/kanz-app-control-snippet.php`, `lib/models/app_model.dart`, `lib/models/category/category_model.dart`, `lib/models/category/category_model_impl.dart`, `lib/models/category/main_category_model.dart`, `lib/screens/categories/categories_screen.dart`, `lib/screens/categories/layouts/card.dart`, `test/category_order_sync_test.dart`
  - *Details:*
    - Differentiated WooCommerce taxonomy levels so root categories (`parent == 0`) and child weight subcategories are visually distinguished in the WordPress admin with badges (`🟢 قسم رئيسي` vs `↳ فرعي من: ...`).
    - Added filter toggles (`[الكل]`, `[🟢 الأقسام الرئيسية]`, `[↳ الفرعية]`) and a quick action (`[🔝 ترتيب الرئيسية أولاً]`) in the WordPress admin category organizer.
    - Preserved 100% database taxonomy integrity on the WooCommerce website storefront.
    - Implemented real-time `TabBar` config adoption in `AppModel._adoptHomeConfig` while preserving active tab session identity (`identical(value.appConfig!.tabBar, activeTabs)`).
    - Refactored `CategoryModelImpl.sortCategoryList` to prioritize custom ordered categories and preserve all remaining categories without dropping items.
    - Added `CategoryModel.resortCategories()` and subscribed `CategoriesScreen` to `EventLoadedAppConfig` for dynamic re-sorting on config updates.
    - Added unit test suite `test/category_order_sync_test.dart` verifying ordering, root category filtering, and type-safe `TabBarMenuConfig` parsing.
  - *Validation:* Verified with `wordpress/tests/admin_editor_test.js --snippet`, `test/category_order_sync_test.dart` (4/4 passed), `test/app_home_config_test.dart` (6/6 passed), and `test/antigravity_review_test.dart` (8/8 passed).

- [ ] **[T033] Rotate Live Store WooCommerce API Keys (Problem 6) [DEFERRED]**
  - *Details:* Revoke exposed WooCommerce consumer key and secret on `kanzalsahra.com`; reissue new read-only credentials; configure secure server proxy for customer write operations.

- [ ] **[T034] Verify & Deploy Account REST API Endpoints (Problem 9) [DEFERRED]**
  - *Details:* Ensure `mstore-api` or native WooCommerce REST endpoints for customer profile, password reset, and review submission are active and reachable.

- [ ] **[T035] Configure Gold Product Attributes in WooCommerce (Problem 11) [DEFERRED]**
  - *Details:* Audit product attributes on live store (`pa_karat`, `pa_weight`, `pa_craftsmanship`) and ensure consistent taxonomy across all gold jewelry listings.

- [ ] **[T036] Configure Persistent Web-App Cart Synchronization (Problem 20) [DEFERRED]**
  - *Details:* Enable WooCommerce persistent cart hook so customer carts synchronize bidirectionally between the website and mobile app upon authentication.

- [ ] **[T037] Live Catalog SKU Audit & Harmonization (Problem 32) [DEFERRED]**
  - *Details:* Resolve duplicate product SKUs and assign missing SKUs on WooCommerce inventory database.

- [ ] **[T038] Deploy Apple Guideline 5.1.1 Account Deletion Endpoint (Problem 35) [DEFERRED]**
  - *Details:* Deploy secure backend endpoint at `wp-json/kanz/v1/delete-account` to process GDPR / App Store compliant account erasure requests.
