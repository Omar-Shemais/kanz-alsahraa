import 'dart:io';

class ReleaseSecurityFinding {
  const ReleaseSecurityFinding(this.path, this.reason);
  final String path;
  final String reason;
  @override
  String toString() => '$path: $reason';
}

/// No values or matching lines are returned: diagnostics must not leak secrets.
List<ReleaseSecurityFinding> inspectReleaseText(String path, String content) {
  final findings = <ReleaseSecurityFinding>[];
  if (RegExp(r'sb_api_[A-Za-z0-9_-]{16,}').hasMatch(content)) {
    findings
        .add(ReleaseSecurityFinding(path, 'Embedded Shorebird API credential'));
  }
  if (RegExp(r'(?:ck|cs)_[a-fA-F0-9]{40}').hasMatch(content)) {
    findings
        .add(ReleaseSecurityFinding(path, 'Embedded WooCommerce credential'));
  }
  final passwords = RegExp(
    r'^[ \t]*(?:storePassword|keyPassword|store_password|key_password)[ \t]*=[ \t]*([^\r\n]*)\r?$',
    multiLine: true,
    caseSensitive: false,
  );
  for (final match in passwords.allMatches(content)) {
    final value = match.group(1)!.trim();
    if (value.isNotEmpty &&
        !value.startsWith('#') &&
        !RegExp(r'^\$\{[A-Z_][A-Z0-9_]*\}$').hasMatch(value)) {
      findings.add(
          ReleaseSecurityFinding(path, 'Signing password stored in project'));
      break;
    }
  }
  if (content.contains('-----BEGIN PRIVATE KEY-----') ||
      content.contains('-----BEGIN RSA PRIVATE KEY-----') ||
      content.contains('-----BEGIN EC PRIVATE KEY-----') ||
      content.contains('-----BEGIN ENCRYPTED PRIVATE KEY-----')) {
    findings
        .add(ReleaseSecurityFinding(path, 'Private key material in project'));
  }
  return findings;
}

List<ReleaseSecurityFinding> scanReleaseSecurity(Directory root) {
  final findings = <ReleaseSecurityFinding>[];
  const excluded = {
    'build',
    '.gradle',
    '.dart_tool',
    'Pods',
    '.symlinks',
    '.git',
    'node_modules'
  };
  const textExtensions = {
    '.dart',
    '.json',
    '.yaml',
    '.yml',
    '.props',
    '.properties',
    '.gradle',
    '.plist',
    '.xcconfig',
    '.pem'
  };
  void visit(Directory directory) {
    for (final entity in directory.listSync(followLinks: false)) {
      final name =
          entity.uri.pathSegments.where((part) => part.isNotEmpty).last;
      if (entity is Directory) {
        if (!excluded.contains(name)) visit(entity);
      } else if (entity is File) {
        final path = entity.absolute.path
            .substring(root.absolute.path.length)
            .replaceFirst(RegExp(r'^[\\/]'), '')
            .replaceAll('\\', '/');
        final extension = name.contains('.')
            ? name.substring(name.lastIndexOf('.')).toLowerCase()
            : '';
        if ({'.jks', '.jsk', '.keystore', '.p12', '.pfx'}.contains(extension)) {
          findings.add(ReleaseSecurityFinding(
              path, 'Signing/private-key container in project'));
        } else if (textExtensions.contains(extension)) {
          try {
            findings
                .addAll(inspectReleaseText(path, entity.readAsStringSync()));
          } catch (_) {
            findings.add(ReleaseSecurityFinding(
                path, 'Unable to inspect release input'));
          }
        }
      }
    }
  }

  for (final name in ['lib', 'configs', 'android', 'ios', 'assets']) {
    final directory = Directory.fromUri(root.uri.resolve('$name/'));
    if (directory.existsSync()) visit(directory);
  }
  for (final name in ['shorebird.yaml', 'pubspec.yaml', 'codemagic.yaml']) {
    final file = File.fromUri(root.uri.resolve(name));
    if (file.existsSync()) {
      findings.addAll(inspectReleaseText(name, file.readAsStringSync()));
    }
  }
  return findings;
}

void main(List<String> args) {
  final root =
      args.isEmpty ? Directory.current : Directory(args.single).absolute;
  if (!File.fromUri(root.uri.resolve('pubspec.yaml')).existsSync()) {
    stderr.writeln('Release security check requires a Flutter project root.');
    exitCode = 2;
    return;
  }
  final findings = scanReleaseSecurity(root);
  if (findings.isEmpty) {
    stdout.writeln(
        'Release credential scan passed; this is NOT approval of deployment, payment or privacy gates.');
  } else {
    stderr.writeln(
        'RELEASE BLOCKED: ${findings.length} security findings. Values are never printed.');
    for (final finding in findings) {
      stderr.writeln(finding);
    }
    exitCode = 1;
  }
}
