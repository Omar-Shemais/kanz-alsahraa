/// Validate the required home-layout contract before replacing usable settings.
/// Errors intentionally contain neither the configuration nor source URLs.
void validateHomeConfig(dynamic data) {
  if (data is! Map || data['Setting'] is! Map) {
    throw const FormatException('Home configuration settings are missing.');
  }
  final tabs = data['TabBar'];
  if (tabs is! List || tabs.isEmpty) {
    throw const FormatException('Home configuration navigation is missing.');
  }
  for (final tab in tabs) {
    if (tab is! Map ||
        tab['layout'] is! String ||
        (tab['layout'] as String).trim().isEmpty ||
        tab['icon'] is! String ||
        (tab['icon'] as String).trim().isEmpty) {
      throw const FormatException('Home configuration navigation is invalid.');
    }
  }
  final sections = data['HorizonLayout'];
  if (tabs.any((tab) => tab['layout'] == 'home') && sections is! List) {
    throw const FormatException('Home configuration sections are missing.');
  }
  if (sections != null) {
    if (sections is! List ||
        sections.any((item) =>
            item is! Map ||
            item['layout'] is! String ||
            (item['layout'] as String).trim().isEmpty)) {
      throw const FormatException('Home configuration sections are invalid.');
    }
  }
  for (final name in [
    'AppBar',
    'Drawer',
    'Background',
    'onBoardingConfig',
    'MetaSeo',
    'overrideTranslation'
  ]) {
    if (data[name] != null && data[name] is! Map) {
      throw const FormatException('Home configuration component is invalid.');
    }
  }
}
