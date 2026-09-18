import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tools/release_security.dart';

void main() {
  test('Shorebird API credentials are rejected without exposing the token', () {
    final token = 'sb_api_${List.filled(32, 'x').join()}';
    final findings = inspectReleaseText('shorebird.yaml', token);
    expect(findings, hasLength(1));
    expect(findings.single.toString(), isNot(contains(token)));
  });
  test('Woo configuration uses external build inputs, not committed secrets',
      () {
    final config = File('lib/env.dart').readAsStringSync();
    expect(config, contains("String.fromEnvironment('KANZ_WOO_CONSUMER_KEY')"));
    expect(
        config, contains("String.fromEnvironment('KANZ_WOO_CONSUMER_SECRET')"));
    expect(inspectReleaseText('lib/env.dart', config), isEmpty);
  });
  test('Woo credentials are detected without returning secret values', () {
    final secret = 'cs_${List.filled(40, 'a').join()}';
    final key = 'ck_${List.filled(40, 'b').join()}';
    final findings = inspectReleaseText('lib/config.dart', '$key\n$secret');
    expect(findings, hasLength(1));
    expect(findings.single.toString(), isNot(contains(secret)));
    expect(findings.single.toString(), isNot(contains(key)));
  });
  test('signing passwords are reported by file, not by value', () {
    const value = 'DO_NOT_PRINT_SIGNING_PASS';
    final findings = inspectReleaseText(
        'configs/env.props', 'storePassword=$value\nkeyPassword=$value');
    expect(findings, hasLength(1));
    expect(findings.single.toString(), isNot(contains(value)));
  });
  test('empty values and environment placeholders do not contain passwords',
      () {
    expect(
        inspectReleaseText('config', r'storePassword=${KANZ_STORE_PASSWORD}'),
        isEmpty);
    expect(
        inspectReleaseText('config', 'keyPassword=\nstorePassword='), isEmpty);
  });
  test('private key types are all blocked without exposing their bodies', () {
    for (final type in [
      'PRIVATE KEY',
      'RSA PRIVATE KEY',
      'EC PRIVATE KEY',
      'ENCRYPTED PRIVATE KEY'
    ]) {
      final findings =
          inspectReleaseText('key.pem', '-----BEGIN $type-----\nPRIVATE_BODY');
      expect(findings, hasLength(1));
      expect(findings.single.toString(), isNot(contains('PRIVATE_BODY')));
    }
  });
  test('ordinary public project settings do not become security findings', () {
    expect(
        inspectReleaseText(
            'config', 'appName=Kanz\nwebsiteUrl=https://kanzalsahra.com'),
        isEmpty);
  });
  test('debug signing is separate and release is gated with external inputs',
      () {
    final gradle = File('android/app/build.gradle').readAsStringSync();
    expect(gradle, contains('signingConfig signingConfigs.debug'));
    expect(
        gradle, contains("tasks.register('verifyKanzReleaseSecurity', Exec)"));
    for (final name in [
      'KANZ_KEY_ALIAS',
      'KANZ_KEY_PASSWORD',
      'KANZ_KEYSTORE_PATH',
      'KANZ_STORE_PASSWORD'
    ]) {
      expect(gradle, contains("System.getenv('$name')"));
    }
    expect(
        gradle, isNot(contains("envProperties.getProperty('storePassword'")));
    expect(gradle, isNot(contains("envProperties.getProperty('keyPassword'")));
  });
}
