import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';
import '../tools/shorebird_config_guard.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('production Shorebird configuration is included in the Flutter bundle',
      () async {
    final bundled = await rootBundle.loadString('shorebird.yaml');
    expect(bundled, File('shorebird.yaml').readAsStringSync());
  });
  const valid = 'app_id: 12345678-1234-1234-1234-123456789abc';
  const assets = 'flutter:\n  assets:\n    - shorebird.yaml\n';
  test('real application ID and asset are required', () {
    expect(
        () => validateShorebirdConfiguration(valid, assets), returnsNormally);
    expect(() => validateShorebirdConfiguration('app_id: REPLACE_ME', assets),
        throwsStateError);
    expect(
        () => validateShorebirdConfiguration(valid, 'flutter:\n  assets: []'),
        throwsStateError);
    expect(
        () => validateShorebirdConfiguration(
            '$valid\nauto_update: false', assets),
        throwsStateError);
  });
  test('CI workflow parses and does not auto-publish', () {
    final yaml = loadYaml(
            File('specs/codemagic.shorebird.yaml.example').readAsStringSync())
        as YamlMap;
    final workflow = (yaml['workflows']
        as YamlMap)['kanz-ios-shorebird-validation'] as YamlMap;
    expect(workflow.containsKey('publishing'), isFalse);
    expect(
        (workflow['environment'] as YamlMap)['flutter'].toString(), '3.38.4');
    final shell = File('tools/shorebird_ios_dry_run.sh').readAsStringSync();
    expect(shell, contains('shorebird release ios --dry-run'));
    expect(shell, isNot(contains('shorebird patch')));
    expect(shell, contains('KANZ_WOO_CONSUMER_SECRET'));
  });
  test('application configuration is bundled and editor is not overridden', () {
    expect(File('codemagic.yaml').existsSync(), isFalse);
    expect(
        () => validateShorebirdConfiguration(
            File('shorebird.yaml').readAsStringSync(),
            File('pubspec.yaml').readAsStringSync()),
        returnsNormally);
  });
}
