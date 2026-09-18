# فحص Firebase الحي — كنز الصحراء

التاريخ: 18 سبتمبر 2026. فحص للقراءة فقط عبر إضافة المتصفح في Chrome، بحساب يستطيع الوصول إلى مشروع kanz-alsahra. تمت مقارنة اللوحة بالكود المحلي؛ الكود المحلي ليس بالضرورة إصدار App Store/Google Play الموجود عند العملاء.

لم تُرسل إشعارات أو SMS، ولم تُنشأ مفاتيح أو قواعد أو قواعد بيانات، ولم تُغير صلاحيات أو خطة Spark أو إعدادات العملاء. لم يُفتح سجل حسابات العملاء أو محتويات مستنداتهم.

## نتائج مؤكدة من اللوحة

| الخدمة | ما ظهر | الحكم |
|---|---|---|
| المشروع | kanz-alsahra، رقم 132198990660، Spark | الحساب الصحيح متاح الآن؛ عائق حساب Brave السابق لا ينطبق على Chrome الحالي |
| تطبيقات المشروع | Android وApple، كلاهما com.khtwah.kanzalsahra | الهوية متطابقة مع الملفات المحلية المصححة |
| FCM | HTTP v1 Enabled، Legacy Disabled | لا حاجة لإعادة تفعيل Legacy |
| APNs | مفتاح للتطوير ومفتاح للإنتاج، Team ID مطابق لـDEVELOPMENT_TEAM في Xcode | وجود الإعداد مؤكد، لا إثبات أنه غير ملغى أو أن التوقيع/التسليم صحيح |
| حملات الإشعارات | Create your first campaign | لم تظهر حملات محفوظة؛ الاختبارات والإرسال البرمجي لا يشترطان حملة محفوظة |
| تقارير FCM | Notification، آخر 90 يوماً Jun 20–Sep 18: Sends 1، Received 0، Impressions 0، Open count 0 | ليست نتيجة اختبار تسليم حالي، ولا دليل فشل iOS؛ Received وImpressions يخصان Android، والبيانات قد تتأخر |
| Analytics | Enabled، property 453284636، stream Android 8628479109 وiOS 8629334656 | الربط موجود لكلا التطبيقين |
| لوحة Analytics | الفترة Aug 21–Sep 17، أحداث ظاهرة page_view وscroll وfirst_visit وصفحات الموقع؛ App version/Device model/App stability: No data available؛ الإيرادات $0 | أرقام النشاط الظاهرة تشمل الموقع وليست قياساً مثبتاً للتطبيق أو مبيعاته؛ صفر الإيرادات ليس دليلاً على عدم وجود طلبات |
| Crashlytics Android | Add SDK، لا لوحة أعطال فعلية | الكود وpubspec.lock أيضاً بلا firebase_crashlytics؛ لا مراقبة أعطال Flutter مثبتة لكلا النظامين |
| Performance Android | Add SDK، لا بيانات فعلية | الكود وpubspec.lock بلا firebase_performance؛ لا قياس سرعة Firebase مثبت |
| Firestore | Create database | قاعدة البيانات غير منشأة في الواجهة المفحوصة؛ لم تنشأ قاعدة أو تفحص قواعد بيانات أخرى |
| Remote Config | Create configuration / upload template | لا إعداد منشور ظاهر |
| Phone Auth | Phone Enabled فقط في قائمة مزودي الدخول؛ تحذير الحصة 10 SMS/day للمشروعات الجديدة | يلزم التحقق من السياسة الفعلية قبل الاعتماد عليه للإنتاج؛ لا تجربة SMS في هذا الفحص |
| سياسة مناطق SMS | Allow مختارة، قائمة المناطق فارغة، Save معطل | لا تظهر دول مسموحة؛ قد تمنع مسار Firebase Phone إن استُخدم، ولم نغيرها |
| Storage | Requires billing account (Blaze) | ليس متاحاً حالياً في الواجهة؛ ليس ضرورياً لصور المنتجات المأخوذة من WordPress |
| App Check | Get started | لا إعداد جاهز ظاهر؛ لا تفرض enforcement قبل دعم التطبيق واختبار الإصدارات الحالية |

## مقارنة مع التطبيق وأولويات المتابعة

1. **روابط المنتجات القديمة — أولوية مرتفعة.** lib/env.dart ما زال يفعّل dynamicLinkConfig.type=firebase وkanzalsahra.page.link. packages/flux_firebase/lib/impl/firebase_dynamic_link_service.dart يستدعي FirebaseDynamicLinks فعلياً لإنشاء/استقبال الروابط، مع fallback مباشر عند فشل الإنشاء فقط. الخدمة أُوقفت في 25 أغسطس 2025؛ الـfallback لا يعيد تشغيل استقبال روابط page.link القديمة. كذلك iOSAppStoreId داخل إعداد Firebase القديم 1469772800 مختلف عن رابط المتجر المعتمد 1564098406؛ تحقق من مرجع التطبيق الرسمي عند استبدال المسار. يلزم App Links/Universal Links على نطاق المتجر واختبار الدخول البارد والدافئ؛ وجهات الإشعارات الداخلية المكتوبة سابقاً منفصلة ولا تعتمد على تقصير Firebase.

2. **تسلسل إشعارات iOS — أولوية مرتفعة.** تم تصحيح GoogleService-Info.plist في configs وios سابقاً، وتفعيل FirebaseAppDelegateProxyEnabled محلياً. init في firebase_notification_service.dart يطلق getToken وsubscribeToTopic دون انتظار جاهزية APNs ودون onTokenRefresh. تسجيل mstore_device_token يحدث عند تسجيل الدخول ولا يتجدد تلقائياً عند دوران الرمز. يحتاج تسلسلاً لا يحجب بدء التطبيق، ومحاولة محدودة بعد جاهزية APNs، ومزامنة token refresh للحساب الصحيح، واختبار التعطيل/التفعيل وتسجيل الخروج. لم تُعدل هذه الشيفرة في جلسة الفحص.

3. **قياس التطبيق منفصل عن الموقع — أولوية مرتفعة.** enableFirebaseAnalytics=true وFirebaseAnalyticsServiceImpl يسجل app_open ويدعم أحداث المنتجات والسلة والشراء. الواجهات المفحوصة لا تثبت استقبال هذه الأحداث من النسخة المصححة. المطلوب DebugView لكل نظام مع أحداث فتح التطبيق/عرض منتج/السلة دون شراء حقيقي، ثم تقارير مفلترة بالـstream/platform/app_version. قياس purchase يتطلب التحقق من تأكيد الدفع ومعرف الطلب ومنع الازدواج، لا اختلاق أحداث مبيعات للاختبار على الإنتاج.

4. **الأعطال والأداء — أولوية مرتفعة للقياس، لا ادعاء تحسن مسبق.** إضافة Crashlytics وقياسات الأداء المناسبة تتطلب عملاً في التطبيق وبناء نسخة جديدة، وليس ضغط Add SDK فقط. ينبغي حجب الأسرار والبيانات الخاصة عن التقارير، وضبط الرموز وملفات dSYM لإصدار iOS، وقياس بدء التطبيق وطلبات الشبكة على نسخة profile/release. شاشة Successful لإصدار 1.10.2 في Analytics ليست إثبات خلوه من الأخطاء.

5. **الخدمات غير المطلوبة — لا تفعّلها تلقائياً.** enableRemoteConfigFirebase=false وEnableSmartChat=false، ومسار saveUserToFirestore محصور بشرط ServerConfig().isVendorType في user_model.dart. تخطيط الصفحة حالياً مصدره MStore/WordPress، لا Remote Config. لم يُعثر على FirebaseStorage أو Functions أو Crashlytics/Performance SDK في المسارات المحلية المفحوصة. غياب Firestore/Storage ليس بحد ذاته عطل متجر Kanz ولا سبباً للترقية إلى Blaze.

6. **الدخول ورمز التحقق.** EnableDigitsMobileLogin=true وEnableDigitsMobileFirebase=false في lib/env.dart. لذلك سياسة Phone Auth في هذا المشروع ليست إثبات سبب مشكلة Digits. لا تُفعّل Google/Apple/email لمجرد وجود شيفرة القالب؛ راجع فقط المسارات التي يعرضها التطبيق فعلياً وسياسات المتجر.

7. **صلاحيات الإرسال من WordPress.** هذا الفحص لا يثبت نجاح المفتاح المحفوظ في WordPress أو الإرسال بـUser ID. يلزم اختبار منفصل للحساب الذي يملكه المستخدم باستخدام النسخة الحديثة وتسجيل mstore_device_token، دون fallback لجمهور عام. لم تُقرأ مفاتيح خدمة خاصة أو تُنشأ credentials أثناء فحص Firebase.

## شروط إغلاق بند الإشعارات

- نسخة Android/نسخة iPhone مبنية على المشروع الصحيح ومثبتة على أجهزة الاختبار.
- إذن الإشعارات صحيح، APNs token جاهز على iPhone وFCM token من المشروع الصحيح.
- إرسال إلى الجهاز المحدد فقط، وظهور الإشعار بالخلفية وفتحه من حالتي التطبيق الدافئ والبارد.
- تجربة وجهات تصنيف/منتج/صفحة/رابط HTTPS والتحقق من رفض القيم غير الصالحة.
- مزامنة الرمز بعد دورانه وتغيير الحساب دون إرسال بيانات خاصة لجهاز سابق.
- لا يُغلق البند اعتماداً على وجود APNs key أو Sends فقط.

## مصادر رسمية

تحديث التنفيذ المحلي بعد الفحص: أضيف Crashlytics وPerformance وتمييز أحداث Analytics، واستُبدل SDK الخاص بـDynamic Links بروابط المتجر الأصلية. تفاصيل التنفيذ والتحقق في specs/FIREBASE_APP_VERIFICATION.md وspecs/ANTIGRAVITY_REVIEW_PROGRESS.md. نتائج الفحص أعلاه توثق الحالة السابقة، وليست حكماً على النسخة الجديدة. تبقى قياسات الأجهزة والنشر وملفات ربط الموقع بحاجة إلى تحقق مستقل.

- [متطلبات Flutter FCM وAPNs](https://firebase.google.com/docs/cloud-messaging/flutter/get-started)
- [تقارير التسليم وحدودها وتأخرها](https://firebase.google.com/docs/cloud-messaging/understand-delivery)
- [إيقاف Firebase Dynamic Links](https://firebase.google.com/support/dynamic-links-faq)

لم يشمل الفحص كل أدوار IAM أو صلاحية/إلغاء مفاتيح Apple في Apple Developer أو إعدادات المشروع القديم، ولا اختبار iPhone فعلياً. لا نتيجة هنا تعني إغلاق جميع أخطاء التقرير الـ38 أو جاهزية النشر النهائي.
