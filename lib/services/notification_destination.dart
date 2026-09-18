/// Typed public marketing destinations. Never an authentication boundary.
Map<String, String>? notificationDestination(dynamic data) {
  if (data is! Map) return null;
  final type = data['kanz_target'];
  if (type == 'category' || type == 'product') {
    final id = data['kanz_id'];
    if (id is! String || !RegExp(r'^[1-9][0-9]{0,9}$').hasMatch(id)) {
      return null;
    }
    return {type as String: id};
  }
  const tabs = {
    'home': '1',
    'category_page': '2',
    'cart': '3',
    'profile': '4',
  };
  if (tabs.containsKey(type)) return {'tab_number': tabs[type]!};
  if (type == 'url') {
    final url = data['kanz_url'];
    if (url is! String || url.length > 2048) return null;
    final uri = Uri.tryParse(url);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      return null;
    }
    return {'urlLaunch': url};
  }
  return null;
}
