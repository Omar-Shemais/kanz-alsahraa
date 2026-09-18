import 'dart:convert';

import '../modules/dynamic_layout/config/app_config.dart';

bool isRemoteHomeSource(String source) =>
    ['http', 'https'].contains(Uri.tryParse(source)?.scheme);

List<String> homeBundlePaths(
    {required String source,
    required String language,
    String? folder,
    String? fallbackLanguage}) {
  final directory =
      folder?.isNotEmpty == true ? 'lib/config/$folder' : 'lib/config';
  return <String>{
    '$directory/config_$language.json',
    if (folder?.isNotEmpty == true)
      '$directory/config_${fallbackLanguage ?? 'en'}.json',
    if (!isRemoteHomeSource(source)) source,
    if (isRemoteHomeSource(source) && folder?.isNotEmpty != true)
      'lib/config/config_ar.json',
  }.toList();
}

List<String> homeRemoteUrls(
    {required String source, required String language, String? folder}) {
  final uri = Uri.tryParse(source);
  if (uri == null ||
      uri.scheme != 'https' ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty) {
    return [];
  }
  if (!uri.path.endsWith('.json')) return [uri.toString()];
  final segments = [...uri.pathSegments]..removeLast();
  if (folder?.isNotEmpty == true) segments.addAll(folder!.split('/'));
  segments.add('config_$language.json');
  final localized = uri.replace(pathSegments: segments).toString();
  return <String>{localized, uri.toString()}.toList();
}

Future<AppConfig> loadBundledHomeConfig(
    List<String> paths, Future<String> Function(String path) loadAsset) async {
  for (final path in paths) {
    try {
      return AppConfig.fromJson(jsonDecode(await loadAsset(path)));
    } catch (_) {
      // A missing/invalid locale asset can fall back to the packaged default.
    }
  }
  throw const FormatException('No usable bundled home configuration.');
}
