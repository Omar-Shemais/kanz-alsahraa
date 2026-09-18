/// Only public store links can enter the native navigation handler.
/// Product URL queries cannot select arbitrary template screens/actions.
Uri? kanzAppLink(Uri uri) {
  if (uri.scheme != 'https' ||
      uri.host != 'kanzalsahra.com' ||
      uri.userInfo.isNotEmpty ||
      (uri.hasPort && uri.port != 443)) {
    return null;
  }
  if (uri.path == '/app-notification') {
    return uri;
  }
  if (!['/product/', '/product-category/', '/product-tag/']
      .any(uri.path.startsWith)) {
    return null;
  }
  if (uri.pathSegments.any((part) => part == '..' || part == '.')) {
    return null;
  }
  return Uri(
      scheme: uri.scheme, host: uri.host, pathSegments: uri.pathSegments);
}
