# تجهيز بناء iOS عبر Codemagic

## الحالة

تحديث Shorebird: Workflow Editor يدعم Shorebird رسمياً. الملف shorebird.yaml موجود ومضاف للأصول؛ اتبع SHOREBIRD_SETUP.md لتفعيل Release داخل المحرر. نقل مثال YAML إلى specs كي لا يغيّر اختيار مسار البناء. تعليمات عدم دعم المحرر السابقة كانت غير صحيحة.

آخر تحقق محلي: 214/214 اختبار Flutter ناجحاً، فحص أسرار المصدر ناجح، تحليل اختبار إعدادات iOS بلا ملاحظات، وفحص syntax لسكربتات shell الثلاثة ناجح. لم ينفذ pod install أو archive على Windows.

المشروع مجهز لفحص المصدر قبل archive، وليس معتمداً للنشر النهائي. البناء والتوقيع الفعليان ينفذان على macOS داخل Codemagic، ثم القبول على iPhone عبر TestFlight. لا تنشر مباشرة إلى الإنتاج.

## إصلاحات هذه الدفعة

- ملاحظة قابلية إعادة البناء: كاش Flare المحلي كان يحمل إصلاح Object.hash غير الموجود في commit الخارجي المثبت. يطبقه الآن tools/prepare_build_dependencies.dart بعد pub get على الحزمة النشطة المحددة في package_config، وليس أول مجلد عشوائي في الكاش. لا تستخدم سكربت Firebase القديم أو stub signInWithAuthProvider؛ إصدارات Firebase المثبتة تغيرت. يبقى إصلاح الكاش حلاً انتقالياً حتى استبدال اعتماد Flare القديم بنسخة مصححة ومثبتة.

- توحيد الحد الأدنى لإصدار iOS إلى 14.0 في Runner والمشروع والامتداد وPods وFlutter framework؛ هذا يطابق الحد الموجود أصلاً في Podfile.
- استبدال مسار جهاز المطور السابق في Config.xcconfig بمسار نسبي ثابت.
- إزالة تحميل إعداد Profile داخل Release.xcconfig.
- جعل معلومات لغة التطبيق في iOS عربية فقط.
- ربط scheme بسكربت pre-actions.sh واحد، مع إيقاف نسخ كود lib المخصص فوق التعديلات المراجعة، واقتصار النسخ على الأصول وFirebase.
- فحوص تلقائية لمطابقة Firebase والاستحقاقات واللغة والحد الأدنى وملفات Xcode.

## إعدادات Codemagic قبل الضغط على Build

1. ارفع آخر التعديلات إلى الفرع الذي سيبنيه Codemagic، بما فيها الملفات الجديدة داخل test وtools. لا ترفع مجلدات backup أو مفاتيح التوقيع أو kanz_project.zip. راجع git diff قبل commit؛ المشروع يحتوي تغييرات كثيرة للمستخدم وAntigravity.
2. استخدم Flutter 3.38.4، وهو الإصدار الذي نجحت عليه الاختبارات المحلية، وبيئة Xcode تدعم متطلبات الرفع الحالية إلى App Store Connect. لا تغير Flutter إلى latest تلقائياً في هذا البناء.
3. أضف متغيرين مشفرين: KANZ_WOO_CONSUMER_KEY وKANZ_WOO_CONSUMER_SECRET. لا تبنِ بدونهما؛ الكتالوج يحتاجهما حالياً. تدوير المفتاح المكشوف سابقاً وتقليل صلاحياته مطلوب قبل الإنتاج. المتغيرات المشفرة تحمي التخزين والسجل، لكنها لا تجعل مفتاحاً مضمنًا في التطبيق غير قابل للاستخراج.
4. أضف KANZ_BUILD_NUMBER بقيمة أكبر من آخر build في App Store Connect. البناء 23 استُخدم بالفعل، لذلك استخدم 24 أو رقماً أعلى.
5. في pre-build script نفذ من جذر المشروع: `/bin/sh tools/ios_prebuild.sh`.
6. في Flutter build arguments أضف:

```sh
--release --build-number="$KANZ_BUILD_NUMBER" --dart-define=KANZ_WOO_CONSUMER_KEY="$KANZ_WOO_CONSUMER_KEY" --dart-define=KANZ_WOO_CONSUMER_SECRET="$KANZ_WOO_CONSUMER_SECRET"
```

إذا كانت واجهة البناء لا توسع متغيرات shell داخل خانة arguments، استخدم خطوة shell مخصصة بدلاً من تمرير أسماء المتغيرات كنص:

```sh
flutter build ipa --release --build-number="$KANZ_BUILD_NUMBER" --dart-define=KANZ_WOO_CONSUMER_KEY="$KANZ_WOO_CONSUMER_KEY" --dart-define=KANZ_WOO_CONSUMER_SECRET="$KANZ_WOO_CONSUMER_SECRET" --export-options-plist=/Users/builder/export_options.plist
```

المسار أعلاه هو المسار المعتاد الذي تولده أدوات توقيع Codemagic؛ تحقق من وجوده في workflow قبل استخدام الأمر. لا تشغل خطوة build إضافية إن كانت الواجهة تنفذها بالفعل، ولا تستخدم set -x مع الأسرار.

## التوقيع

- Team: T5T28K7SSZ.
- Runner: com.khtwah.kanzalsahra.
- الامتداد الحالي: com.khtwah.kanzalsahra.NotificationServiceExtension.
- اختر App Store distribution certificate وملفي provisioning صالحين؛ لا تستخدم profile الذي يظهر Invalid.
- App ID الرئيسي يجب أن يطابق Push Notifications وSign in with Apple وAssociated Domains وApp Groups الموجودة في entitlement.
- App Group المشترك: group.com.khtwah.kanzalsahra.notifications. إذا تغيرت capabilities، أعد توليد profile قبل البناء.
- امتداد OneSignal القديم ما زال مضمنًا؛ أبق profile الخاص به في هذا البناء. لا تحتاج مفتاح APNs .p8 داخل التطبيق؛ الربط موجود في Firebase.
- مصادر التوقيع وملفات GoogleService موجودة، لكن صلاحية شهادة/profile والبناء الفعلي لا يمكن إثباتها على Windows.

## بعد نجاح archive وقبل الإنتاج

- أضف في post-build وقبل نشر TestFlight: `/bin/sh tools/ios_archive_verify.sh`. يفحص الهوية ورقم البناء وFirebase والاستحقاقات الفعلية للتوقيع وملف dSYM وعدم بقاء متغيرات غير مفسرة؛ لا يثبت وصول الإشعار أو عمل الدفع. يمكن تمرير مسار xcarchive كوسيط إذا اختلف المسار.

- احتفظ بـIPA وxcarchive وdSYM وسجل البناء. راجع نجاح خطوة Crashlytics symbols وعدم وجود missing dSYM.
- ثبّت على iPhone فعلي عبر TestFlight، ثم اختبر العربية والتمرير والمنتجات والبحث والدخول وApple login وOTP والخروج والسلة.
- إشعار لحساب اختبار واحد فقط: وصوله في المقدمة والخلفية وبعد إغلاق التطبيق، وفتح الوجهة الصحيحة من التصنيف والمنتج والرابط.
- اختبر Universal Link من Notes أو رسالة وليس فقط كتابة الرابط داخل Safari.
- تحقق من جلسة Analytics وبيانات Performance وتقرير Crashlytics على نسخة الاختبار. لا تستخدم crash متعمدًا على تطبيق العميل الحي.
- اختبر حذف حساب اختبار مخصص فقط والدفع في وضع اختبار معتمد؛ لا تنفذ شراءً حقيقياً تلقائياً.
- ترتيب التصنيفات لم ينشر حياً بعد، والتحديث الإجباري يبقى معطلاً.

## المراجع

- [متغيرات workflow editor](https://docs.codemagic.io/flutter-configuration/env-variables/)
- [توقيع iOS والامتدادات](https://docs.codemagic.io/yaml-code-signing/signing-ios/)
- [رموز Crashlytics في Flutter](https://firebase.google.com/docs/crashlytics/flutter/get-deobfuscated-reports)
