# التحقق من مراقبة تطبيق كنز

## ما أُضيف محلياً

Analytics يحتفظ بمراقبة التنقل والأحداث الموجودة، ويضيف kanz_app_ready مع kanz_source=mobile_app وkanz_platform. تستخدم تقارير التطبيق stream الخاص بـAndroid أو iOS؛ لا يُحسب page_view الخاص بالموقع دليلاً على نشاط التطبيق.

صُحح مسار purchase محلياً لتسجيل قيم السلة قبل مسحها، مع استخدام معرف الطلب أو رقمه الذي يعيده WebView. الحدث بلا مرجع صالح يُترك دون اختراع عملية شراء. بقي اختبار طلب مؤكد ومراجعة الازدواج وتطابق قيم الخادم ضرورياً قبل اعتماد تقارير المبيعات.

Crashlytics يستقبل أخطاء Flutter والأخطاء غير المعالجة بعد تهيئة Firebase. التقرير المخصص يرسل نوع الاستثناء وstack فقط بدلاً من نص الخطأ الذي قد يحتوي بيانات خاصة. تسجيل SDK التلقائي وbreadcrumbs يحتاجان مراجعة سياسة الخصوصية؛ هذا ليس ضماناً أن كل مسارات التسجيل القديمة خالية من البيانات الخاصة.

Performance يسجل trace بدء التشغيل بعد Firebase ومدة مسار httpCache باسم kanz_catalog_request. هذه المدة تشمل التعامل مع التخزين المؤقت، وليست قياساً لكل طلب شبكة أو وصول كل صور الصفحة. بدء SDK وقياسات Android/iOS التلقائية لا يثبتان تحسن السرعة دون قياس profile/release قبل وبعد.

استُبدلت Firebase Dynamic Links بروابط المتجر الأصلية باستخدام app_links. فتح التطبيق من الرابط يحتاج ملفات association على الموقع وتوقيع البناء الصحيح. الروابط القديمة page.link لن تعمل بعد إيقاف الخدمة، ولا يُعاد تفعيل الخدمة من Firebase.

## اختبار Android الآمن

1. بناء debug باستخدام `flutter build apk --debug --no-pub --dart-define=KANZ_TELEMETRY_SMOKE=true`.
2. تحديث المحاكي باستخدام `adb install -r build/app/outputs/flutter-apk/app-debug.apk` دون حذف التطبيق أو بياناته. عند نقص المساحة لا تستخدم uninstall أو clear data تلقائياً.
3. تفعيل DebugView لهذا المحاكي فقط: `adb shell setprop debug.firebase.analytics.app com.khtwah.kanzalsahra` ثم افتح التطبيق.
4. راجع Analytics > DebugView داخل kanz-alsahra. تحقق من kanz_monitoring_check وkanz_app_ready وkanz_source=mobile_app، ثم عرض منتج وإضافة للسلة دون شراء فعلي.
5. أعد فتح التطبيق لإتاحة رفع الخطأ غير القاتل. تحقق من Kanz monitoring smoke check في Crashlytics ومن trace باسم kanz_monitoring_check في Performance. رسالة التسجيل المحلية ليست وحدها إثبات استقبال لوحة Firebase.
6. اختبر Home ثم العودة للتطبيق من الخلفية. الاختبار لا يستدعي crash متعمداً ولا يسجل purchase وهمياً. أعد قيمة debug.firebase.analytics.app السابقة بعد الانتهاء، أو `.none.` إذا لم تكن مضبوطة.
7. لا توزع نسخة smoke على العملاء. شرط kDebugMode يمنع الاختبار في release حتى لو مرر التعريف بالخطأ.

## اختبار iOS

يلزم Mac لبناء CocoaPods وXcode ونسخة اختبار موقعة، مع GoogleService-Info.plist الصحيح للمشروع. أُضيف script رفع dSYM للإصدارات غير debug؛ يلزم التأكد من تنفيذ script دون أخطاء ومن ظهور الرموز في Crashlytics. اختبر Analytics باستخدام launch argument `-FIRDebugEnabled`، ثم نفس الأحداث وtrace والخطأ غير القاتل على iPhone. لا تعتبر APNs key أو ملف plist دليلاً على وصول القياسات أو الإشعار.

## ملفات ربط الموقع عبر Code Snippets

الملف `wordpress/snippets/kanz-native-links.code-snippets.json` تصدير مستقل غير مفعل افتراضياً. استورده كـCode Snippet منفصل يعمل في جميع الصفحات، ولا تستبدل به لوحة إدارة التطبيق.

قبل التفعيل تحقق من team ID الخاص بـApple، وSHA-256 لشهادة **App Signing** من Google Play Console. بعد التفعيل توجد صفحة أدوات > روابط تطبيق كنز لإدخال الشهادة العامة. لا تضع private keys أو شهادات سرية في الحقل. شهادة Upload key وحدها لا تكفي لنسخة Play Store.

يجب أن يرجع الرابطان HTTP 200 وJSON الصحيح دون redirect أو تسجيل دخول:

- https://kanzalsahra.com/.well-known/assetlinks.json
- https://kanzalsahra.com/.well-known/apple-app-site-association

الفحص الحي قبل النشر أعاد 404 لكليهما. إذا حجب الخادم مسار .well-known قبل وصوله إلى WordPress فلن يكفي snippet، ويلزم مسؤول الاستضافة. لا تنشر شهادة غير متحقق منها لمجرد نجاح نموذج الحفظ.

## شروط الإغلاق

آخر تحقق في 18 سبتمبر: 206 اختبارات ناجحة، وتحليل ملفات التغيير العشرة بلا ملاحظات، وبناء APK debug للمحاكي android-x64 ناجح. قائمة adb devices فارغة عند محاولة التثبيت؛ لم يثبت هذا الـAPK ولم يرسل smoke منه بعد. إضافة Chrome تعذر استخدامها للتحقق من لوحة Firebase في نهاية الجلسة. أعد توصيل المحاكي وربط الإضافة لإتمام اختبار الاستقبال. ملفات ربط الموقع ما زالت غير منشورة واختبار iOS ما زال يحتاج Mac/iPhone.

- الاختبارات المحلية وبناء حديث ينجحان.
- تُرى أحداث التطبيق والخطأ الاختباري وtrace داخل مشروع Firebase الصحيح لكل نظام.
- فتح روابط منتج وتصنيف وإشعار من التطبيق المغلق والمفتوح، مع رفض النطاقات غير المسموحة.
- قياس profile/release على أجهزة ممثلة قبل أي ادعاء أن التطبيق أسرع.
- لا يغلق هذا التحقق بقية أخطاء التقرير أو مشكلات الدفع وتسجيل الدخول والأسرار الموجودة داخل القالب.
