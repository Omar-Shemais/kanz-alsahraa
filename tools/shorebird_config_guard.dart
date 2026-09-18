import 'dart:io';
import 'package:yaml/yaml.dart';

void validateShorebirdConfiguration(String configText, String pubspecText) {
  final config = loadYaml(configText);
  if (config is! YamlMap ||
      config['app_id'] is! String ||
      !RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')
          .hasMatch(config['app_id'] as String)) {
    throw StateError(
        'Missing real Shorebird app_id. Sign in and run shorebird init.');
  }
  final pubspec = loadYaml(pubspecText) as YamlMap;
  final assets = (pubspec['flutter'] as YamlMap)['assets'] as YamlList;
  if (!assets.contains('shorebird.yaml')) {
    throw StateError(
        'shorebird.yaml must be bundled in Flutter assets. Run shorebird init.');
  }
  if (config['auto_update'] == false) {
    throw StateError(
        'Automatic updates are disabled but no manual update flow is configured.');
  }
}

void main() {
  final config = File('shorebird.yaml');
  if (!config.existsSync()) {
    stderr.writeln(
        'Shorebird is not initialized. Run shorebird login, then shorebird init --display-name "Kanz Alsahra".');
    exitCode = 1;
    return;
  }
  validateShorebirdConfiguration(
      config.readAsStringSync(), File('pubspec.yaml').readAsStringSync());
  stdout
      .writeln('Shorebird application ID and bundled configuration verified.');
}
