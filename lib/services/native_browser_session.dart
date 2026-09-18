import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'browser_session.dart';

final browserSession = BrowserSession(() async {
  if (kIsWeb ||
      (defaultTargetPlatform != TargetPlatform.android &&
          defaultTargetPlatform != TargetPlatform.iOS)) {
    return;
  }
  // Both browser plugins may be used by checkout and account screens.
  await Future.wait<void>([
    CookieManager.instance().deleteAllCookies().then((_) {}),
    WebViewCookieManager().clearCookies().then((_) {}),
    InAppWebViewController.clearAllCache(),
    if (defaultTargetPlatform == TargetPlatform.android)
      WebStorageManager.instance().deleteAllData(),
    if (defaultTargetPlatform == TargetPlatform.iOS)
      WebStorageManager.instance().removeDataModifiedSince(
        dataTypes: WebsiteDataType.ALL,
        date: DateTime.fromMillisecondsSinceEpoch(0),
      ),
  ]);
});
