import 'dart:async';

import 'package:app_links/app_links.dart';

import 'dynamic_link_service.dart';
import 'kanz_link_policy.dart';

/// Android App Links / Apple Universal Links, not Firebase Dynamic Links.
/// Domain association files must also be published on the store website.
class NativeProductLinkService extends DynamicLinkService {
  NativeProductLinkService({required super.linkService});
  StreamSubscription<Uri>? _subscription;
  Future<void> _pending = Future.value();
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    // uriLinkStream includes the initial link. Do not separately fetch it,
    // which would navigate twice at a cold start.
    _subscription = AppLinks().uriLinkStream.listen((uri) {
      final destination = kanzAppLink(uri);
      if (destination == null) return;
      _pending = _pending
          .then((_) => linkService.handleDynamicLink(destination))
          .catchError((Object _) {});
    }, onError: (Object _) {});
  }

  @override
  Future<String?> createDynamicLink({required String productUrl}) async {
    final uri = Uri.tryParse(productUrl);
    return uri == null ? null : kanzAppLink(uri)?.toString();
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    _initialized = false;
  }
}
