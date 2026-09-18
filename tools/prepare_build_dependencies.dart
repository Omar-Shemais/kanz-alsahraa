import 'dart:convert';
import 'dart:io';

/// Narrow, repeatable compatibility fix for the pinned legacy Flare revision.
/// No authentication implementations or Firebase package APIs are rewritten.
String compatibleFlareSource(String source) {
  const oldLine = 'int get hashCode => hashValues(bundle, name);';
  const newLine = 'int get hashCode => Object.hash(bundle, name);';
  if (source.contains(newLine) && !source.contains(oldLine)) return source;
  if (oldLine.allMatches(source).length != 1) {
    throw StateError(
        'Unexpected Flare source. Review the pinned dependency before building.');
  }
  return source.replaceFirst(oldLine, newLine);
}

void main() {
  final packageConfig = File('.dart_tool/package_config.json').absolute;
  if (!packageConfig.existsSync()) {
    throw StateError(
        'Run flutter pub get before preparing build dependencies.');
  }
  final packages =
      (jsonDecode(packageConfig.readAsStringSync()) as Map)['packages'] as List;
  final package = packages
      .cast<Map>()
      .singleWhere((entry) => entry['name'] == 'flare_flutter');
  final root = packageConfig.uri.resolve(package['rootUri'] as String);
  if (!root.path.contains('fd4bcba22aae4c028286e453deeb78f3311e689a')) {
    throw StateError(
        'Flare revision changed. Review this compatibility fix first.');
  }
  final directoryRoot =
      root.path.endsWith('/') ? root : root.replace(path: '${root.path}/');
  final sourceFile =
      File.fromUri(directoryRoot.resolve('lib/provider/asset_flare.dart'));
  final source = sourceFile.readAsStringSync();
  final compatible = compatibleFlareSource(source);
  if (source != compatible) sourceFile.writeAsStringSync(compatible);
  stdout.writeln(
      'Pinned Flare dependency compatibility verified. Firebase APIs were not modified.');
}
