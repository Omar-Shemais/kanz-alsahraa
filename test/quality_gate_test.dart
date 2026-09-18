import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

import '../tools/quality_gate.dart';

void main() {
  test('quality runs formatting, full analysis and all tests', () async {
    final commands = <GateCommand>[];
    final results = await runQualityGate((command) async {
      commands.add(command);
      return 0;
    });
    expect(results.values, everyElement(0));
    expect(commands.length, 3);
    expect(commands[1].arguments, ['analyze', '--no-pub']);
    expect(commands[2].arguments, ['test', '--no-pub']);
    expect(commands.any((command) => command.arguments.contains('--release')),
        false);
  });

  test('analysis failure cannot hide itself or prevent independent tests',
      () async {
    final commands = <String>[];
    final results = await runQualityGate((command) async {
      commands.add(command.name);
      return command.name == 'Full project analysis' ? 1 : 0;
    });
    expect(results['Full project analysis'], 1);
    expect(results['All local tests'], 0);
    expect(commands.length, 3);
    expect(results.values.every((code) => code == 0), false);
  });

  test('executor exception is a failed check rather than a silent pass',
      () async {
    final results = await runQualityGate((command) async {
      if (command.name == 'Full project analysis') {
        throw StateError('Private details');
      }
      return 0;
    });
    expect(results['Full project analysis'], 2);
    expect(results['All local tests'], 0);
  });

  test('security-only gate does not run Flutter or generate an artifact',
      () async {
    final commands = <GateCommand>[];
    final results = await runQualityGate((command) async {
      commands.add(command);
      return 1;
    }, securityOnly: true);
    expect(results, {'Credential scan': 1});
    expect(commands.single.program, 'dart');
    expect(commands.single.arguments, ['tools/release_security.dart']);
  });

  for (final failed in [
    'Credential scan',
    'Full project analysis',
    'All local tests'
  ]) {
    test('$failed failure blocks APK generation', () async {
      final commands = <GateCommand>[];
      final results = await runQualityGate((command) async {
        commands.add(command);
        return command.name == failed ? 1 : 0;
      }, buildDebug: true);
      expect(results['Android debug build (blocked)'], 1);
      expect(commands.any((command) => command.arguments.contains('build')),
          false);
    });
  }

  test('debug build requires every preceding check and credential scan to pass',
      () async {
    final commands = <GateCommand>[];
    final results = await runQualityGate((command) async {
      commands.add(command);
      return 0;
    }, buildDebug: true);
    expect(commands[3].name, 'Credential scan');
    expect(commands.last.arguments, ['build', 'apk', '--debug', '--no-pub']);
    expect(results['Android debug build'], 0);
  });

  test('formatter scope names actual remediation files, never modifies them',
      () {
    final formatter = qualityCommands().first;
    expect(formatter.arguments, contains('--output=none'));
    expect(formatter.arguments, contains('--set-exit-if-changed'));
    for (final path in remediationFormatPaths) {
      expect(File(path).existsSync() || Directory(path).existsSync(), true,
          reason: path);
    }
  });

  test(
      'workflow uses locked versions, read-only permissions and pinned actions',
      () {
    final yaml =
        loadYaml(File('.github/workflows/kanz-quality.yml').readAsStringSync())
            as YamlMap;
    expect(yaml['permissions'], {'contents': 'read'});
    final events = yaml['on'] as YamlMap;
    expect(events.keys,
        containsAll(['push', 'pull_request', 'workflow_dispatch']));
    expect(events.containsKey('pull_request_target'), false);
    final jobs = yaml['jobs'] as YamlMap;
    for (final job in jobs.values.cast<YamlMap>()) {
      expect(job['timeout-minutes'], greaterThan(0));
      for (final step in (job['steps'] as YamlList).cast<YamlMap>()) {
        final action = step['uses'];
        if (action is String) {
          expect(RegExp(r'^[\w/-]+@[a-f0-9]{40}$').hasMatch(action), true,
              reason: action);
          if (action.startsWith('actions/checkout@')) {
            expect(step['with']['persist-credentials'], false);
          }
          if (action.startsWith('subosito/flutter-action@')) {
            expect(step['with']['flutter-version'], '3.38.4');
          }
        }
      }
    }
  });

  test('workflow blocks native build on credential failure and never publishes',
      () {
    final source =
        File('.github/workflows/kanz-quality.yml').readAsStringSync();
    final yaml = loadYaml(source) as YamlMap;
    final native = yaml['jobs']['android-debug'] as YamlMap;
    expect(native['needs'], containsAll(['quality', 'credential-scan']));
    final runs = (native['steps'] as YamlList)
        .cast<YamlMap>()
        .where((step) => step['run'] is String)
        .map((step) => step['run'])
        .toList();
    expect(runs, [
      'flutter pub get --enforce-lockfile',
      'dart tools/release_security.dart',
      'flutter build apk --debug --no-pub'
    ]);
    expect(source, isNot(contains('--release')));
    expect(source, isNot(contains('upload-artifact')));
    expect(source, isNot(contains('secrets.')));
  });
}
