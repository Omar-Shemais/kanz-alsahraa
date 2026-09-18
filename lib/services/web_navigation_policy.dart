import 'dart:convert';

enum WebUrlAction { embed, external, block }

String originBoundWebScript(String source, String initialUrl) {
  if (source.isEmpty ||
      webUrlAction(initialUrl) != WebUrlAction.embed ||
      initialUrl == 'about:blank') {
    return '';
  }
  final origin = Uri.parse(initialUrl).origin;
  return 'if (window.location.origin === ${jsonEncode(origin)}) {\n$source\n}';
}

/// HTTPS redirects remain available for payment/3DS. Host allowlisting is a
/// separate integration gate once the actual gateway domains are approved.
WebUrlAction webUrlAction(String value) {
  if (value == 'about:blank') return WebUrlAction.embed;
  if (value.trim() != value || value.contains(RegExp(r'[\x00-\x20\\]'))) {
    return WebUrlAction.block;
  }
  final uri = Uri.tryParse(value);
  if (uri == null || uri.userInfo.isNotEmpty) return WebUrlAction.block;
  if (uri.scheme == 'https' && uri.host.isNotEmpty) {
    return WebUrlAction.embed;
  }
  if (['tel', 'mailto'].contains(uri.scheme) &&
      uri.path.isNotEmpty &&
      !uri.hasAuthority) {
    return WebUrlAction.external;
  }
  if (uri.scheme == 'whatsapp' &&
      uri.host == 'send' &&
      uri.queryParameters.isNotEmpty) {
    return WebUrlAction.external;
  }
  return WebUrlAction.block;
}

bool sameWebOrigin(String first, String second) {
  final a = Uri.tryParse(first);
  final b = Uri.tryParse(second);
  return a != null &&
      b != null &&
      a.scheme == 'https' &&
      b.scheme == 'https' &&
      a.host.isNotEmpty &&
      a.host == b.host &&
      a.port == b.port &&
      a.userInfo.isEmpty &&
      b.userInfo.isEmpty;
}

/// A return page is only a candidate order ID, never proof of a paid order.
String? wooReturnOrderId(String value, String storeUrl) {
  if (!sameWebOrigin(value, storeUrl)) return null;
  final uri = Uri.tryParse(value)!;
  final segments = uri.pathSegments.where((item) => item.isNotEmpty).toList();
  final marker = segments.indexOf('order-received');
  if (marker < 0 || marker + 2 != segments.length) return null;
  final id = segments[marker + 1] == 'thank-you'
      ? uri.queryParameters['order_id']
      : segments[marker + 1];
  return id != null && RegExp(r'^[1-9][0-9]*$').hasMatch(id) ? id : null;
}
