# Shorebird عبر Codemagic Workflow Editor

## الحالة

الربط في المصدر موجود الآن: shorebird.yaml يحتوي app_id صالحاً، وpubspec.yaml يضيف الملف إلى assets، والتحديث التلقائي الافتراضي غير معطل. لا تحتاج حزمة Dart إضافية لهذه الاستراتيجية.

تصحيح للإرشاد السابق: Workflow Editor يدعم Shorebird رسمياً وفق وثائق Codemagic. مثال YAML محفوظ في specs/codemagic.shorebird.yaml.example وليس في جذر المشروع؛ لن يفرض التحويل إلى YAML.

جاهزية المصدر لا تعني أن النسخة المنشورة تدعم code push. يلزم بناء baseline باستخدام Shorebird، تسجيله، وتوزيع artifact نفسه عبر TestFlight/المتجر ثم اختبار patch على جهاز حقيقي. هذه الخطوات لم تنفذ بعد.

## إنشاء token بنفسك

افتح console.shorebird.dev ثم Account → API Keys → Create API Key. سمّه Kanz Codemagic وحدد مدة انتهاء. اختر Release & Patch only إن كانت متاحة في خطتك؛ إذا لم تتوفر، Full access أوسع ويجب التعامل معه بحذر. انسخ القيمة مباشرة إلى حقل Shorebird token في Codemagic؛ لا ترسلها في المحادثة ولا تضفها في الكود أو Git. القيمة تظهر مرة واحدة. لا تستخدم login:ci القديم.

## إعداد Workflow Editor

1. اختر التطبيق والـworkflow الحالي، وحدد iOS.
2. داخل Publish updates to user devices using Shorebird اختر Release، وليس Patch، للبناء الأول.
3. داخل قسم Shorebird اختر Flutter 3.38.4 وXcode المناسب لإعداداتك، ثم أدخل token.
4. في App settings → Environment variables ضع KANZ_WOO_CONSUMER_KEY وKANZ_WOO_CONSUMER_SECRET كقيم Secret، وKANZ_BUILD_NUMBER أعلى من آخر build في App Store Connect.
5. في Pre-build script استخدم:

```sh
#!/bin/sh
set -eu
/bin/sh tools/ios_prebuild.sh
```

6. داخل additional build arguments في قسم Shorebird أضف:

```sh
--build-number="$KANZ_BUILD_NUMBER" --dart-define=KANZ_WOO_CONSUMER_KEY="$KANZ_WOO_CONSUMER_KEY" --dart-define=KANZ_WOO_CONSUMER_SECRET="$KANZ_WOO_CONSUMER_SECRET"
```

تحقق من توسيع المتغيرات في واجهة البناء قبل release؛ لا تستخدم قيماً سرية مكتوبة مباشرة داخل arguments. ابدأ بأرقام غير سرية للتحقق إن احتاج الأمر. لا تفعل زيادة buildNumber تلقائية أثناء export؛ رقم artifact يجب أن يطابق release لدى Shorebird.

7. أبق توقيع App Store الصحيح للتطبيق com.khtwah.kanzalsahra وامتداده com.khtwah.kanzalsahra.NotificationServiceExtension، والفريق T5T28K7SSZ. لا تستخدم profile بحالة Invalid.
8. ارفع تغييرات المصدر والملفات الجديدة إلى فرع البناء، ثم راجع الإعدادات قبل الضغط على Build.

## النشر والاختبار

تفعيل Release وبدء البناء يسجل artifacts المترجمة لدى Shorebird عند النجاح. التطبيق الحالي يتضمن Woo credentials وقت البناء؛ يجب تدوير المفتاح المكشوف وتقليل صلاحياته، والأفضل وسيط خادم. رفع artifacts إلى طرف ثالث يحتاج اعتماد المالك لهذه البيانات والوجهة. لم ننفذ هذا الرفع.

يمكن إضافة --dry-run في additional arguments لبناء تحقق لا يسجل baseline، مع تعطيل توزيع المتاجر لهذا التشغيل. بما أن تكامل المحرر قد يتوقع تسجيل release بعد البناء، فإن قبول هذا التشغيل في CI نفسه يحتاج تجربة؛ لا نعد نجاح المحرر مثبتاً محلياً.

بعد release حقيقي، وزع artifact نفسه إلى TestFlight واختبر على iPhone. النسخة القديمة المبنية بـflutter build لا تتحول إلى Shorebird عبر token فقط. اختبر patch على مسار اختبار مخصص وبـrelease-version محدد وبنفس dart-defines؛ لا تختَر latest عشوائياً ولا تنشر patch للعملاء أثناء الاختبار.

التغييرات في Swift/Kotlin وpermissions والاستحقاقات والحزم ذات الأجزاء native وassets تحتاج إصدار متجر جديد. لا تستخدم code push لتجاوز مراجعة المتجر أو تغيير وظيفة التطبيق. التحديث التلقائي الافتراضي لا يجبر إعادة تشغيل التطبيق أثناء الدفع.

## المراجع

- [Workflow Editor يدعم Shorebird](https://docs.codemagic.io/flutter-publishing/shorebird/)
- [API Keys وصلاحياتها](https://docs.shorebird.dev/account/api-keys/)
- [تهيئة التطبيق](https://docs.shorebird.dev/code-push/initialize/)
- [قيود code push](https://docs.shorebird.dev/code-push/faq/)
