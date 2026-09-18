import 'dart:convert';
import 'dart:io';

class GateCommand {
  const GateCommand(this.name, this.program, this.arguments);
  final String name;
  final String program;
  final List<String> arguments;
}

const remediationFormatPaths = [
  'test',
  'tools',
  'lib/data/storage_recovery.dart',
  'lib/services/browser_session.dart',
  'lib/services/native_browser_session.dart',
  'lib/services/cart_validation.dart',
  'lib/services/checkout_preparation.dart',
  'lib/services/home_config_repository.dart',
  'lib/services/home_config_sources.dart',
  'lib/services/home_config_validation.dart',
  'lib/services/remote_home_config.dart',
  'lib/services/secure_http_client.dart',
  'lib/services/secure_requests.dart',
  'lib/services/web_navigation_policy.dart',
  'lib/widgets/common/catalog_load_error.dart',
  'lib/services/guest_order_verifier.dart',
  'lib/screens/order_history/views/guest_order_lookup_screen.dart',
];

List<GateCommand> qualityCommands({bool securityOnly = false}) => securityOnly
    ? const [
        GateCommand('Credential scan', 'dart', ['tools/release_security.dart'])
      ]
    : const [
        GateCommand('Remediation formatting', 'dart', [
          'format',
          '--output=none',
          '--set-exit-if-changed',
          ...remediationFormatPaths,
        ]),
        GateCommand(
            'Full project analysis', 'flutter', ['analyze', '--no-pub']),
        GateCommand('All local tests', 'flutter', ['test', '--no-pub']),
      ];

/// Independent checks continue after failure, but the overall gate never passes
/// if any required check failed. No live API tests or deployment are performed.
Future<Map<String, int>> runQualityGate(
    Future<int> Function(GateCommand command) execute,
    {bool securityOnly = false,
    bool buildDebug = false}) async {
  final results = <String, int>{};
  Future<int> checked(GateCommand command) async {
    try {
      return await execute(command);
    } catch (_) {
      return 2;
    }
  }

  for (final command in qualityCommands(securityOnly: securityOnly)) {
    results[command.name] = await checked(command);
  }
  if (buildDebug && !securityOnly) {
    const security =
        GateCommand('Credential scan', 'dart', ['tools/release_security.dart']);
    results[security.name] = await checked(security);
    if (results.values.every((code) => code == 0)) {
      const build = GateCommand('Android debug build', 'flutter',
          ['build', 'apk', '--debug', '--no-pub']);
      results[build.name] = await checked(build);
    } else {
      // Nonzero means blocked; it is not a successful or attempted build.
      results['Android debug build (blocked)'] = 1;
    }
  }
  return results;
}

Future<int> _execute(GateCommand command) async {
  stdout.writeln('\nCHECK: ${command.name}');
  try {
    final process = await Process.start(command.program, command.arguments,
        runInShell: Platform.isWindows, mode: ProcessStartMode.inheritStdio);
    return await process.exitCode;
  } catch (_) {
    stderr
        .writeln('Unable to start ${command.name}; check installed runtimes.');
    return 2;
  }
}

Future<void> main(List<String> args) async {
  const allowed = {'--security', '--build-debug'};
  if (args.any((arg) => !allowed.contains(arg)) ||
      args.toSet().length != args.length ||
      (args.contains('--security') && args.contains('--build-debug')) ||
      !File('pubspec.yaml').existsSync()) {
    stderr.writeln('From the project root: dart tools/quality_gate.dart '
        '[--security | --build-debug]');
    exitCode = 2;
    return;
  }
  final results = await runQualityGate(_execute,
      securityOnly: args.contains('--security'),
      buildDebug: args.contains('--build-debug'));
  stdout.writeln(
      '\nLOCAL GATE SUMMARY (not approval of live integration/deployment)');
  for (final result in results.entries) {
    stdout.writeln('${result.value == 0 ? 'PASS' : 'FAIL'}: ${result.key} '
        '(exit ${result.value})');
  }
  try {
    final directory = Directory('build/kanz-quality')
      ..createSync(recursive: true);
    final now = DateTime.now().toUtc();
    final report = const JsonEncoder.withIndent('  ').convert({
      'schema': 1,
      'finishedAtUtc': now.toIso8601String(),
      'mode': args.contains('--security') ? 'security' : 'quality',
      'debugRequested': args.contains('--build-debug'),
      'checks': results,
      'passed': results.values.every((code) => code == 0),
      'deploymentApproved': false,
      'liveIntegrationVerified': false,
    });
    // Status only, never raw command output or credential values.
    File('${directory.path}/run-${now.microsecondsSinceEpoch}.json')
        .writeAsStringSync(report);
    File('${directory.path}/latest.json').writeAsStringSync(report);
    stdout.writeln('Status report: build/kanz-quality/latest.json');
  } catch (_) {
    stderr.writeln('Unable to persist gate status report.');
    exitCode = 1;
  }
  if (results.values.any((code) => code != 0)) exitCode = 1;
}
