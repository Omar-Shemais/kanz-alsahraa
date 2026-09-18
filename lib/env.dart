// ignore_for_file: prefer_single_quotes, lines_longer_than_80_chars final
Map<String, dynamic> environment = {
  "appConfig": "https://kanzalsahra.com/wp-content/uploads/flutter_config_files/config_ar.json",


  "serverConfig": {
    "url": "https://kanzalsahra.com",
    "type": "woo",
    // Supply these at build time from Codemagic encrypted environment
    // variables. Never commit WooCommerce credentials to the app source.
    "consumerKey": const String.fromEnvironment('KANZ_WOO_CONSUMER_KEY'),
    "consumerSecret": const String.fromEnvironment('KANZ_WOO_CONSUMER_SECRET')

    /// Wordpress blog, it could be removed if using the same above url
    //'blog': 'https://mstore.io',
  },

  /// ➡️ lib/common/config/general.dart
  "defaultDarkTheme": false,
  "enableRemoteConfigFirebase": false,
  "enableFirebaseAnalytics": true,
  "enableFacebookAppEvents": false,

  /// Web Proxy: use only for web FluxStore
  "webProxy": "",

  /// If maxTextScale is null or maxTextScale <= 0,
  /// the application will automatically get the system's textscaleFactor.
  /// Otherwise, the maxTextScale value will be taken as
  /// the maximum value for textScale.
  "maxTextScale": null,

"loginSMSConstants": {
    "countryCodeDefault": "SA",
    "dialCodeDefault": "+966",
    "nameDefault": "Saudi Arabia"
},
"phoneNumberConfig": {
    "enable": true,
    "countryCodeDefault": "SA",
    "dialCodeDefault": "+966",
    "useInternationalFormat": true,
    "selectorFlagAsPrefixIcons": true,
    "showCountryFlag": true,
    "customCountryList": ["SA"],  // Only Saudi Arabia
    "selectorType": "NONE"        // Disable country selector
},

  "appRatingConfig": {
    'showOnOpen': false,
    'android': 'com.khtwah.kanzalsahra',
    'ios': '1469772800',
    'minDays': 7,
    'minLaunches': 10,
    'remindDays': 7,
    'remindLaunches': 10,
  },
  "advanceConfig": {
    "DefaultLanguage": "ar",
    "DetailedBlogLayout": "halfSizeImageType",
    "EnablePointReward": false,
    "hideOutOfStock": false,
    "HideEmptyTags": true,
    "HideEmptyCategories": true,
    "EnableRating": true,

    /// If rating is 0, it will be hidden. Apply for whole app (include product
    /// detail, store, listing, review, testimonial; exclude product card).
    "hideEmptyRating": true,

    "EnableCart": true,
    "ShowBottomCornerCart": true,

    /// Enable search by SKU in search screen
    "EnableSkuSearch": true,

    /// Show stock Status on product List & Product Detail
    "showStockStatus": true,

    /// Gird count setting on Category screen
    "GridCount": 3,

    /// set isCaching to true if you have upload the config file to mstore-api
    /// set kIsResizeImage to true if you have finished running Re-generate image plugin
    /// ref: https://support.inspireui.com/help-center/articles/3/8/19/app-performance
    "isCaching": true,
    "kIsResizeImage": false,
    "httpCache": true,

    "DefaultCurrency": {
      "symbol": "ر.س",
      "decimalDigits": 2,
      "symbolBeforeTheNumber": true,
      "currency": "SAR",
      "currencyCode": "SAR",
    },
    "Currencies": [
      {
        "symbol": "ر.س",
        "decimalDigits": 2,
        "symbolBeforeTheNumber": true,
        "currency": "SAR",
        "currencyCode": "SAR",
      },

    ],

    /// Below config is used for Magento store
    "DefaultStoreViewCode": "",
    "EnableAttributesConfigurableProduct": ["color", "size"],

    /// if the woo commerce website supports multi languages
    /// set false if the website only have one language
    "isMultiLanguages": false,

    /// Review gets approved automatically on woocommerce admin without
    /// requiring administrator to approve.
    "EnableApprovedReview": false,

    /// Sync Cart from website and mobile
    "EnableSyncCartFromWebsite": false,
    "EnableSyncCartToWebsite": false,

    /// Enable firebase to support FCM, realtime chat for Fluxstore MV
    "EnableFirebase": true,

    /// ratio Product Image, default value is 1.2 = height / width
    "RatioProductImage": 1.2,

    /// Enable Coupon Code When checkout
    "EnableCouponCode": true,

    /// Enable to Show Coupon list.
    "ShowCouponList": true,

    /// Enable this will show all coupons in Coupon list.
    /// Disable will show only coupons which is restricted to the current user"s email.
    "ShowAllCoupons": true,

    /// Show expired coupons in Coupon list.
    "ShowExpiredCoupons": false,
    "AlwaysShowTabBar": true,

    /// Privacy Policies page ID. If page ID is null, use the URL instead.
    /// Accessible in the app via Settings > Privacy menu.
    "PrivacyPoliciesPageUrlOrId": "https://kanzalsahra.com/privacy-policy/",

    "SupportPageUrl": "https://kanzalsahra.com/contact-us/",

    "DownloadPageUrl": 'https://kanzalsahra.com/عن-كنز-الصحراء/',

    "AboutUSPageUrl": "https://kanzalsahra.com/عن-كنز-الصحراء/",

    "NewsPageUrl": "https://kanzalsahra.com/faq/",

    "FAQPageUrl": "https://kanzalsahra.com/faq/",

    "SocialConnectUrl": [
      {
        "name": "الموقع الرسمي",
        "icon": "assets/icons/tabs/icon-home.png",
        "url": "https://kanzalsahra.com"
      },
    ],

    "AutoDetectLanguage": false,
    "QueryRadiusDistance": 10,
    "MinQueryRadiusDistance": 1,

    /// Distance in kilometers
    "MaxQueryRadiusDistance": 10,

    /// Time to display toast message (milliseconds)
    "TimeShowToastMessage": 1500,

    /// Enable Membership Pro Ultimate WP
    "EnableMembershipUltimate": false,

    /// Enable Paid Membership Pro
    "EnablePaidMembershipPro": false,

    /// Enable Delivery Date when doing checkout
    "EnableDeliveryDateOnCheckout": false,

    /// Enable new SMS Login
    "EnableNewSMSLogin": false,

    /// Enable bottom add to cart from product card view
    "EnableBottomAddToCart": true,

    /// Disable inAppWebView to use webview_flutter
    /// so webview can navigate to external app.
    /// Useful for webview checkout which need to handle payment in another app.
    "inAppWebView": true,
    'AlwaysClearWebViewCache': true,
    'AlwaysClearWebViewCookie': true,
    "WebViewScript": "",

    'AlwaysRefreshBlog': false,

    ///support multi currency via WOOCS – Currency Switcher for WooCommerce plugin (https://wordpress.org/plugins/woocommerce-currency-switcher/)
    "EnableWOOCSCurrencySwitcher": false,

    /// Enable product backdrop layout - https://tppr.me/L5Pnf
    "enableProductBackdrop": false,

    /// false: show category menu as Text https://tppr.me/v3bLI
    /// true: show as Category Image
    "categoryImageMenu": true,

    /// Support Digits : WordPress Mobile Number Signup and Login.
    /// Plugin (https://codecanyon.net/item/digits-wordpress-mobile-number-signup-and-login/19801105)
    "EnableDigitsMobileLogin": true,
    "EnableDigitsMobileFirebase": false,
    "EnableDigitsMobileWhatsApp": false,

    /// Enable Ajax Search Pro, https://your-domain/wp-json/ajax-search-pro/v0/woo_search?s=
    "AjaxSearchURL": "",

    "gdpr": {
      "showPrivacyPolicyFirstTime": false,
      "showDeleteAccount": true,
      "confirmCaptcha": "PERMANENTLY DELETE",
    },

    /// show order notes in order detail with private notes
    "OrderNotesWithPrivateNote": true,

    "OrderNotesLinkSupport": false,

    /// Just accept select the country on this list
    /// example: {"vn", "ae"}
    "supportCountriesShipping": ["SA"],

    // Enable the request Notify permission from onboarding
    "showRequestNotification": false,

    "versionCheck": {
      "enable": true,
      "iOSAppStoreCountry": "SA",
    },
    "inAppUpdateForAndroid": {
      "enable": true,
      // "flexible, immediate"
      "typeUpdate": "flexible",
    },
    "categoryConfig": {
      // Enable this option when the store has more than 100 category items
      "enableLargeCategories": false,
      "deepLevel": 3,
    },

    /// Example: "pinnedProductTags": ["feature", "new"],
    /// will show the tag before product title in the product list.
    "pinnedProductTags": [],

    /// Enable WooCommerce Wholesale Prices
    "EnableWooCommerceWholesalePrices": false,

    //Require to select site when open app for multi sites
    "IsRequiredSiteSelection": true,

    /// Only for Fluxstore Listing
    "showOpeningStatus": true,

    "b2bKingConfig": {
      "enabled": false,
      "guestAccessRestriction": "none",
    },

    /// PW WooCommerce Gift Cards (https://wordpress.org/plugins/pw-woocommerce-gift-cards/)
    "enablePWGiftCard": true,

    /// TeraWallet Withdrawal (https://standalonetech.com/product/wallet-withdrawal/)
    "EnableTeraWalletWithdrawal": false,

    //set param is_all_data=true to get full product data for WooCommerce
    "EnableIsAllData": false,
  },
  "defaultDrawer": {
    "logo": "assets/images/logo.png",
    "background": null,
    "items": [
      {"type": "home", "show": true},
      {"type": "blog", "show": false},
      {"type": "categories", "show": true},
      {"type": "cart", "show": true},
      {"type": "profile", "show": true},
      {"type": "login", "show": true},
      /* {"type": "category", "show": true}*/
    ]
  },
  "defaultSettings": [
    "biometrics",
    "products",
    "chat",
    "wishlist",
    "notifications",
    //"language",
    //"currencies",
    "darkTheme",
    "order",
    //"point",
    //"rating",
    "privacy",
    "about",
  ],
  "loginSetting": {
    /// Set to false to disable both login and registration options
    "enable": true,

    /// Set to false to disable only registration option
    "enableRegister": true,
    "IsRequiredLogin": false,
    "showAppleLogin": true,
    "showFacebook": false,
    "showSMSLogin": true,
    "showGoogleLogin": false,
    "showPhoneNumberWhenRegister": false,
    "requirePhoneNumberWhenRegister": false,

    /// Lets users freely input a Username instead of the default from email
    "requireUsernameWhenRegister": false,
    "isResetPasswordSupported": true,

    /// Set true value to show only the SMS Login screen, and set the false
    /// value to show default login screen with other login buttons.
    "smsLoginAsDefault": false,

    /// For Facebook login.
    /// These configs are only used for FluxBuilder's Auto build feature.
    /// To update manually, follow this below doc:
    /// https://support.inspireui.com/help-center/articles/42/44/32/social-login#login
    "facebookAppId": "430258564493822",
    "facebookLoginProtocolScheme": "fb430258564493822",

    // This config is used to apple for Wordpress site
    "appleLoginSetting": {
      "iOSBundleId": "com.inspireui.mstore.flutter",
      "appleAccountTeamID": "S9RPAM8224"
    }
  },
  "oneSignalKey": {"enable": false, "appID": ""},

  "onBoardingConfig": {
    'enableOnBoarding': false,
    'version': 1,
    'autoCropImageByDesign': true,
    'isOnlyShowOnFirstTime': true,
    "showLanguage": false,
    'data': [
      {
        'title': 'Welcome to FluxStore',
        'image': 'assets/images/fogg-delivery-1.png',
        'desc': 'Fluxstore is on the way to serve you. '
      },
      {
        'title': 'Connect Surrounding World',
        'image': 'assets/images/fogg-uploading-1.png',
        'desc':
        'See all things happening around you just by a click in your phone. Fast, convenient and clean.'
      },
      {
        'title': "Let's Get Started",
        'image': 'assets/images/fogg-order-completed.png',
        'desc': "Waiting no more, let's see what we get!"
      }
    ],
  },

  "vendorOnBoardingData": [
    {
      'title': 'Welcome aboard',
      'image': 'assets/images/searching.png',
      'desc': 'Just a few more steps to become our vendor'
    },
    {
      'title': 'Let\'s Get Started',
      'image': 'assets/images/manage.png',
      'desc': 'Good Luck for great beginnings.'
    }
  ],

  /// ➡️ lib/common/advertise.dart
  "adConfig": {
    "enable": false,
    "facebookTestingId": "",
    "googleTestingId": [],
    "ads": [
      {
        "type": "banner",
        "provider": "google",
        "iosId": "ca-app-pub-3940256099942544/2934735716",
        "androidId": "ca-app-pub-3940256099942544/6300978111",
        "showOnScreens": ["home", "search"],
        "waitingTimeToDisplay": 2,
      },
      {
        "type": "banner",
        "provider": "google",
        "iosId": "ca-app-pub-2101182411274198/5418791562",
        "androidId": "ca-app-pub-2101182411274198/4052745095",

        /// "showOnScreens": ["home", "category", "product-detail"],
      },
      {
        "type": "interstitial",
        "provider": "google",
        "iosId": "ca-app-pub-3940256099942544/4411468910",
        "androidId": "ca-app-pub-3940256099942544/4411468910",
        "showOnScreens": ["profile"],
        "waitingTimeToDisplay": 5,
      },
      {
        "type": "reward",
        "provider": "google",
        "iosId": "ca-app-pub-3940256099942544/1712485313",
        "androidId": "ca-app-pub-3940256099942544/4411468910",
        "showOnScreens": ["cart"],

        /// "waitingTimeToDisplay": 8,
      },
      {
        "type": "banner",
        "provider": "facebook",
        "iosId": "IMG_16_9_APP_INSTALL#430258564493822_876131259906548",
        "androidId": "IMG_16_9_APP_INSTALL#430258564493822_489007588618919",
        "showOnScreens": ["home"],

        /// "waitingTimeToDisplay": 8,
      },
      {
        "type": "interstitial",
        "provider": "facebook",
        "iosId": "430258564493822_489092398610438",
        "androidId": "IMG_16_9_APP_INSTALL#430258564493822_489092398610438",

        /// "showOnScreens": ["profile"],
        /// "waitingTimeToDisplay": 8,
      },
    ],

    /// "adMobAppId" is only used for FluxBuilder's Auto build feature.
    /// To update manually, follow this below doc:
    /// https://support.inspireui.com/help-center/articles/42/44/17/admob-and-facebook-ads#2-setup-google-admob-for-flutter
    "adMobAppIdIos": "ca-app-pub-7432665165146018~2664444130",
    "adMobAppIdAndroid": "ca-app-pub-7432665165146018~2664444130",
  },

  /// ➡️ lib/common/dynamic_link.dart
  "firebaseDynamicLinkConfig": {
    "isEnabled": false,
    "shortDynamicLinkEnable": false,

    /// Domain is the domain name for your product.
    /// Let’s assume here that your product domain is “example.com”.
    /// Then you have to mention the domain name as : https://example.page.link.
    "uriPrefix": "https://kanzalsahra.page.link",
    //The link your app will open
    "link": "https://kanzalsahra.com/",
    //----------* Android Setting *----------//
    "androidPackageName": "com.khtwah.kanzalsahra",
    "androidAppMinimumVersion": 1,
    //----------* iOS Setting *----------//
    "iOSBundleId": "com.khtwah.kanzalsahra",
    "iOSAppMinimumVersion": "1.0.1",
    "iOSAppStoreId": "1564098406"
  },

  "dynamicLinkConfig": {
    "enable": true,
    "type": "native",
    "branchIO": {
      "liveMode": false,
    }
  },

  /// ➡️ lib/common/languages.dart
  "languagesInfo": [
    // 1 English - intl_en.arb
    {
      "name": "English",
      "icon": "assets/images/country/gb.png",
      "code": "en",
      "text": "English",
      "storeViewCode": ""
    },
    // 5 Arabic - intl_ar.arb
    {
      "name": "Arabic",
      "icon": "assets/images/country/ar.png",
      "code": "ar",
      "text": "العربية",
      "storeViewCode": "ar"
    }
  ],

  /// ➡️  lib/common/config/payments.dart
  "paymentConfig": {
    "DefaultCountryISOCode": "SA",

    "DefaultStateISOCode": "RIY",

    /// Enable the Shipping option from Checkout, support for the Digital Download
    "EnableShipping": true,

    /// Enable the address shipping.
    /// Set false if use for the app like Download Digial Asset which is not required the shipping feature.
    "EnableAddress": true,

    /// Allow customers to add note when order
    "EnableCustomerNote": true,

    /// Allow customers to add address location link to order note
    "EnableAddressLocationNote": false,

    /// Allow both alphabetical and numerical characters in ZIP code
    "EnableAlphanumericZipCode": false,

    /// Enable the product review option
    "EnableReview": true,

    /// Enable the Google Maps picker from Billing Address.
    "allowSearchingAddress": true,

    "GuestCheckout": false,

    /// Enable Payment option (Disable OnePageCheckout to use stable native checkout flow)
    "EnableOnePageCheckout": false,
    "NativeOnePageCheckout": false,

    "ShowWebviewCheckoutSuccessScreen": true,

    /// This config is same with checkout page slug in the website
    "CheckoutPageSlug": {"en": "checkout", "ar": "checkout"},

    /// Enable Credit card payment (only available for Fluxstore Shopipfy)
    "EnableCreditCard": false,

    /// Enable update order status to processing after checkout by COD on woo commerce
    "UpdateOrderStatus": false,

    /// Show order notes in order history detail.
    "ShowOrderNotes": true,

    /// Show Refund and Cancel button on Order Detail (Policy: No automatic cancellations post-confirmation)
    "EnableRefundCancel": false,

    /// If the order completed date is after this period (days), the refund button will be hidden.
    "RefundPeriod": 1,

    /// Allowed payment methods for cancellation inquiry
    "PaymentListAllowsCancelAndRefund": ["bacs"],

    /// Apply the extra fee for the COD method
    /// amountStop: Amount to stop charge the extra fee
    "SmartCOD": {"enabled": false, "extraFee": 10, "amountStop": 200},

    /// List ids to hide some unnecessary payment methods
    "excludedPaymentIds": ["wallet"],

    /// Show Transaction Details in Order History Screen
    "ShowTransactionDetails": true,

    /// List of payment method ids used for web
    "webPaymentIds": ["cod", "bacs"],
  },
  "payments": {
    "stripe_v2_apple_pay": "assets/icons/payment/apple-pay-mark.svg",
    "stripe_v2_google_pay": "assets/icons/payment/google-pay-mark.png",
    "paypal": "assets/icons/payment/paypal.svg",
    "stripe": "assets/icons/payment/stripe.svg",
    "razorpay": "assets/icons/payment/razorpay.svg",
    "tap": "assets/icons/payment/tap.png",
    "paystack": "assets/icons/payment/paystack.png",
    "myfatoorah_v2": "assets/icons/payment/myfatoorah.png",
    "midtrans": "assets/icons/payment/midtrans.png",
    "xendit_cc": "assets/icons/payment/xendit.png",
    "expresspay_apple_pay": "assets/icons/payment/apple-pay-mark.svg",
    "thai-promptpay-easy": "assets/icons/payment/prompt-pay.png",
    "ppcp-gateway": "assets/icons/payment/paypal.svg",
    "thawani_gw": "assets/icons/payment/thawani.png",
  },
  "shopifyPaymentConfig": {
    "shopName": "Kanz Al-Sahra",
    "countryCode": "SA",
    "productionMode": false,
    "paymentCardConfig": {
      "enable": false,
      "serverEndpoint": "",
    },
    "applePayConfig": {
      "enable": false,
      "merchantId": "merchant.com.khtwah.kanzalsahra.flutter",
    },
    "googlePayConfig": {
      "enable": false,
      "stripePublishableKey": "",
      "merchantId": "merchant.com.khtwah.kanzalsahra.flutter"
    },
  },
  "stripeConfig": {
    "serverEndpoint": "",
    "publishableKey": "",
    "paymentMethodIds": ["stripe"],
    "enabled": false,
    "enableApplePay": false,
    "enableGooglePay": false,
    "merchantDisplayName": "Kanz Al-Sahra",
    "merchantIdentifier": "merchant.com.khtwah.kanzalsahra.flutter",
    "merchantCountryCode": "SA",
    "returnUrl": "com.khtwah.kanzalsahra://stripe",
    "enableManualCapture": false,
    "saveCardAfterCheckout": false,
    "stripeApiVersion": 3,
  },
  "paypalConfig": {
    "clientId": "",
    "secret": "",
    "returnUrl": "com.khtwah.kanzalsahra://paypalpay",
    "production": false,
    "paymentMethodId": "paypal",
    "enabled": false,
    "nativeMode": false,
  },
  "paypalExpressConfig": {
    "username": "",
    "password": "",
    "signature": "",
    "paymentAction": "Sale",
    "production": false,
    "paymentMethodId": "paypal_express",
    "enabled": false,
  },
  "razorpayConfig": {
    "keyId": "",
    "keySecret": "",
    "paymentMethodId": "razorpay",
    "enabled": false
  },
  "tapConfig": {
    "SecretKey": "",
    "paymentMethodId": "tap",
    "enabled": false
  },
  "mercadoPagoConfig": {
    "accessToken": "",
    "production": false,
    "paymentMethodId": "woo-mercado-pago-basic",
    "enabled": false
  },
  "payTmConfig": {
    "paymentMethodId": "paytm",
    "merchantId": "",
    "production": false,
    "enabled": false
  },
  "payStackConfig": {
    'paymentMethodId': 'paystack',
    'publicKey': '',
    'secretKey': '',
    'supportedCurrencies': ['SAR'],
    'enableMobileMoney': false,
    'production': false,
    'enabled': false
  },
  "flutterwaveConfig": {
    'paymentMethodId': 'rave',
    'publicKey': '',
    'production': false,
    'enabled': false
  },
  "myFatoorahConfig": {
    "paymentMethodId": "myfatoorah_v2",
    "apiToken": "",
    'accountCountry': 'SA',
    "production": false,
    "enabled": false
  },
  "midtransConfig": {
    'paymentMethodId': 'midtrans',
    'clientKey': '',
    'enabled': false
  },
  "inAppPurchaseConfig": {
    'consumableProductIDs': [],
    'nonConsumableProductIDs': [],
    'subscriptionProductIDs': [],
    "enabled": false
  },
  "xenditConfig": {
    'paymentMethodId': 'xendit',
    'secretApiKey': '',
    'enabled': false
  },
  "expressPayConfig": {
    'paymentMethodId': 'shahbandrpay',
    'merchantKey': '',
    'merchantPassword': '',
    "merchantId": "merchant.com.khtwah.kanzalsahra.flutter",
    "production": false,
    'enabled': false
  },
  "thaiPromptPayConfig": {
    'paymentMethodId': 'thai-promptpay-easy',
    'enabled': false
  },
  "fibConfig": {
    'paymentMethodId': 'fib',
    'clientId': '',
    'clientSecret': '',
    'enabled': false
  },
  "thawaniConfig": {
    'paymentMethodId': 'thawani_gw',
    'secretKey': '',
    'publishableKey': '',
    'production': false,
    'enabled': false
  },

  /// Ref: https://support.inspireui.com/help-center/articles/35/37/120/multi-shipping-countries-and-states
  "defaultCountryShipping": [
    {
      "code": "SA",
      "name": "المملكة العربية السعودية",
      "states": [
        {"code": "RIY", "name": "الرياض"},
        {"code": "MAK", "name": "مكة المكرمة"},
        {"code": "MED", "name": "المدينة المنورة"},
        {"code": "EAS", "name": "المنطقة الشرقية"},
        {"code": "QAS", "name": "القصيم"},
        {"code": "ASI", "name": "عسير"},
        {"code": "TAB", "name": "تبوك"},
        {"code": "HAI", "name": "حائل"},
        {"code": "NOR", "name": "الحدود الشمالية"},
        {"code": "JAZ", "name": "جازان"},
        {"code": "NAJ", "name": "نجران"},
        {"code": "BAH", "name": "الباحة"},
        {"code": "JOW", "name": "الجوف"}
      ]
    }
  ],

  "afterShip": {
    "api": "",
    "tracking_url": "https://kanzalsahra.com"
  },

  /// Ref: https://support.inspireui.com/help-center/articles/3/25/16/google-map-address
  "googleApiKey": {
    'android': '',
    'ios': '',
    'web': ''
  },

  "productCard": {"defaultImage": 'assets/images/no_product_image.png'},

  /// ➡️ lib/common/products.dart
  "productDetail": {
    "height": 0.6,
    "marginTop": 0,
    "safeArea": false,
    "showVideo": true,
    "showBrand": true,
    "showThumbnailAtLeast": 1,
    "borderRadius": 3.0,

    /// current support "simpleType", "fullSizeImageType", "halfSizeImageType" &  "flatStyle"
    /// Note:
    /// - With "flatStyle", the only buyButtonStyle supported is autoHideShow.
    /// In contrast, buyButtonStyle's autoHideShow only supports "flatStyle"
    /// - flatStyle is only support product is variant and simple
    "layout": "flatStyle",

    /// Support "fixedBottom", "autoHideShow", "normal";
    /// Note: With "layout" is "flatStyle", the only "buyButtonStyle" supported is "autoHideShow".
    /// In contrast, buyButtonStyle's autoHideShow only supports "flatStyle"
    "buyButtonStyle": "normal",

    /// Support "normal" and "inline"
    "attributeLayout": "inline",

    /// Enable this to show selected image variant in the top banner.
    "ShowSelectedImageVariant": true,

    "autoPlayGallery": false,
    "SliderShowGoBackButton": true,
    "ShowImageGallery": true,

    /// "SliderIndicatorType" can be "number", "dot". Default: "number".
    "SliderIndicatorType": 'number',

    /// Enable this to add a white background to top banner for transparent product image.
    "ForceWhiteBackground": false,

    /// Auto select first attribute of variable product if there is no default attribute.
    "AutoSelectFirstAttribute": true,

    /// Enable this to show review in product description.
    "enableReview": true,
    "attributeImagesSize": 50.0,
    "showSku": true,
    "showStockQuantity": true,
    "showRating": true,
    "showProductCategories": true,
    "showProductTags": true,
    "hideInvalidAttributes": false,

    /// Enable this to show a quantity selector in product list.
    "showQuantityInList": false,

    /// Enable this to show Add to cart icon in search result list.
    "showAddToCartInSearchResult": true,

    /// Increase this number if you have yellow layout overflow error in product list.
    /// Should check "RatioProductImage" before changing this number.
    "productListItemHeight": 125,

    /// Limit the time a user can make an appointment. Units are in days.
    "limitDayBooking": 0,

    // Hide or show related products in product detail screen.
    "showRelatedProductFromSameStore": true,
    "showRelatedProduct": true,
    "showRecentProduct": true,

    // Product image layout
    "productImageLayout": "page",

    "expandBrands": true,
    "expandSizeGuide": true,
    "expandDescription": true,
    "expandInfors": true,
    "expandCategories": true,
    "expandTags": true,
    "expandReviews": true,
    "expandTaxonomies": true,
    "expandListingMenu": true,
    "expandMap": true,

    /// Buy now button will be fixed at the bottom of the screen if true
    "fixedBuyButtonToBottom": false,

    /// Set true by default, the new UX always displays the `Buy now` and `Add
    /// to cart` button on the product detail page. In case the product is out
    /// of stock or not available, it will still be displayed but will be
    /// disabled. If set false, there is only a `Unavailable` or `Out of stock`
    /// button on the product detail page as old UX does.
    "alwaysShowBuyButton": true,

    /// Only for Fluxstore Listing
    "showListCategoriesInTitle": true,
    "showSocialLinks": true,
    "expandOpeningHours": true,
  },
  "blogDetail": {
    'showComment': true,
    'showHeart': true,
    'showSharing': true,
    'showTextAdjustment': true,
    'enableAudioSupport': false,
    'showRelatedBlog': true,
    'showAuthorInfo': true
  },
  "productVariantLayout": {
    "color": "color",
    "size": "box",
    "height": "option",
    "color-image": "image"
  },
  "productAddons": {
    /// Set the allowed file type for file upload.
    /// On iOS will open Photos app.
    "allowImageType": true,
    "allowVideoType": true,

    /// Enable to allow upload files other than image/video.
    /// On iOS will open Files app.
    "allowCustomType": true,

    /// Set allowed file extensions for custom type.
    /// Leave empty ("allowedCustomType": []) to support all extensions.
    "allowedCustomType": ["png", "pdf", "docx"],

    /// NOTE: WordPress might restrict some file types for security purpose.
    /// To allow it, you can add this line to wp-config.php:
    /// define('ALLOW_UNFILTERED_UPLOADS', true);
    /// - which is NOT recommended.
    /// Instead, try to use a plugin like https://wordpress.org/plugins/wp-extra-file-types
    /// to allow custom file types.
    /// Allow selecting multiple files for upload. Default: false.
    "allowMultiple": false,

    /// Set the file size limit (in MB) for upload. Recommended: <15MB.
    "fileUploadSizeLimit": 5.0
  },
  "cartDetail": {
    "minAllowTotalCartValue": 0,
    "maxAllowQuantity": 10,

    /// Cart Style: normal, style01
    "style": "style01"
  },

  /// Translate the product variant by languages
  /// As it could be limited with the REST API when request variant
  "productVariantLanguage": {
    "en": {
      "color": "Color",
      "size": "Size",
      "height": "Height",
      "color-image": "Color"
    },
    "ar": {
      "color": "اللون",
      "size": "بحجم",
      "height": "ارتفاع",
      "color-image": "اللون"
    }
  },

  /// Exclude these category IDs from the list (e.g., "311,23,208").
  /// Note: Products in these categories will still appear. To hide specific products, use "excludedProductIDs".
  "excludedCategoryIDs": "",

  /// Exclude these product IDs from the list, e.g., "36920,35508,31893"
  "excludedProductIDs": "",

  "saleOffProduct": {
    /// Show Count Down for product type SaleOff
    "ShowCountDown": true,
    "HideEmptySaleOffLayout": false,
    "Color": "#C7222B"
  },

  /// This is strict mode option to check the `visible` option from product variant
  /// https://tppr.me/4DJJs - default value is false
  "notStrictVisibleVariant": true,

  /// ➡️ lib/common/smartchat.dart
  "configChat": {
    "EnableSmartChat": false,
    "enableVendorChat": false,
    "showOnScreens": ["profile"],
    "hideOnScreens": [],
    "version": "2",
    "realtimeChatConfig": {
      "enable": false,
      "adminEmail": "support@kanzalsahra.com",
      "adminName": "كنز الصحراء",
      "userCanDeleteChat": false,
      "userCanBlockAnotherUser": false,
      "adminCanAccessAllChatRooms": false,
    },
  },
  "openAIConfig": {
    'enableChat': false,
    'supabaseUrl': '',
    'supabaseAnonKey': '',
    'revenueAppleApiKey': '',
    'revenueGoogleApiKey': '',
    'revenueProductsIos': [],
    'revenueProductsAndroid': [],
    'enableSubscription': false,
    'enableInputKey': false,
  },

  /// Official support channels for Kanz Al-Sahra
  "smartChat": [
    {
      "app": "mailto:support@kanzalsahra.com",
      "iconData": "email",
      "description": "الدعم الفني",
    },
    {
      "app": "https://kanzalsahra.com/contact-us/",
      "iconData": "contactUs",
      "description": "اتصل بنا",
    }
  ],

  /// ➡️ lib/common/vendor.dart
  "vendorConfig": {
    /// Show Register by Vendor
    "VendorRegister": false,

    /// Disable show shipping methods by vendor
    "DisableVendorShipping": true,

    /// Enable/Disable showing all vendor markers on Map screen
    "ShowAllVendorMarkers": false,

    /// Enable/Disable native store management
    "DisableNativeStoreManagement": true,

    /// Dokan Vendor Dashboard
    "dokan": "my-account?vendor_admin=true",
    "wcfm": "store-manager?vendor_admin=true",

    /// Disable multivendor checkout
    "DisableMultiVendorCheckout": true,

    /// If this is false, then when creating/modifying products in FluxStore Manager
    /// The publish status will be removed.
    "DisablePendingProduct": false,

    /// Default status when Add New Product from MV app.
    /// Support 'draft', 'pending', 'publish'.
    "NewProductStatus": "draft",

    /// Default Vendor image.
    "DefaultStoreImage": "assets/images/default-store-banner.png",

    /// Set this to true to automatically approve the vendor application.
    /// When it is set to false, these are the cases:
    /// - For WCFM - It will set the registered role to subscribe with the meta "wcfm_membership_application_status": "pending".
    /// - For Dokan - It still keeps the registered role as "seller" but the selling capability will be set to false. The meta for it is "dokan_enable_selling": "no"
    "EnableAutoApplicationApproval": false,

    "BannerFit": "cover",
    "ExpandStoreLocationByDefault": true,

    /// Enable/Disable native delivery boy management
    "DisableDeliveryManagement": true,

    /// Show/Hide store contact info in Vendor detail screen
    "HideStoreContactInfo": false
  },

  /// Enable Delivery Boy Management in FluxStore Manager(WCFM)
  "deliveryConfig": {
    'appLogo': 'assets/images/app_icon_transparent.png',
    'appName': 'FluxStore Delivery',
    'dashboardName1': 'FluxStore',
    'dashboardName2': 'Delivery',
    'enableSystemNotes': false,
  },

  /// Enable Vendor Admin in FluxStore manager
  "managerConfig": {
    'appLogo': 'assets/images/app_icon_transparent.png',
    'appName': 'FluxStore Admin',
    'enableDeliveryFeature': false,
  },

  /// ➡️ lib/common/loading.dart
  "loadingIcon": {"size": 30.0, "type": "fadingCube"},
  "splashScreen": {
    "enable": true,

    /// duration in milliseconds, used for all types except "rive" and "flare"
    "duration": 2000,

    ///  Type should be: 'fade-in', 'zoom-in', 'zoom-out', 'top-down', 'rive', 'flare', ''static'
    "type": "static",
    "image": "assets/images/splashscreen.png",

    /// AnimationName's is used for 'rive' and 'flare' type
    "animationName": "fluxstore",

    "boxFit": "contain",
    "backgroundColor": "#ffffff",
    "paddingTop": 0,
    "paddingBottom": 0,
    "paddingLeft": 0,
    "paddingRight": 0,
  },
  "reviewConfig": {
    "service": "native",
    "enableReview": true,
    "enableReviewImage": true,
    "maxImage": 5,
    "judgeConfig": {
      "domain": "https://inspireui-mstore.myshopify.com",
      "apiKey":
      "8b0d5f99732ec01d6f6b64891166e4fe4ba9634a83fe57e14edda11489da0f7e",
    }
  },
  "orderConfig": {
    "version": 1,
  }
};
