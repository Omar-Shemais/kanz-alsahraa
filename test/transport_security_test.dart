import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';

void main() {
  const namespace = 'http://schemas.android.com/apk/res/android';
  test('Android main policy disables cleartext without a permissive override',
      () {
    final document = XmlDocument.parse(
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync());
    final application = document.findAllElements('application').single;
    expect(
        application.getAttribute('usesCleartextTraffic', namespace: namespace),
        'false');
    expect(
        application.getAttribute('networkSecurityConfig', namespace: namespace),
        null);
    for (final variant in ['debug', 'profile']) {
      final overlay = XmlDocument.parse(
          File('android/app/src/$variant/AndroidManifest.xml')
              .readAsStringSync());
      for (final app in overlay.findAllElements('application')) {
        expect(app.getAttribute('usesCleartextTraffic', namespace: namespace),
            isNot('true'));
        expect(app.getAttribute('networkSecurityConfig', namespace: namespace),
            null);
      }
    }
  });
  test('iOS native and WebView arbitrary loads are disabled with no exceptions',
      () {
    final document =
        XmlDocument.parse(File('ios/Runner/Info.plist').readAsStringSync());
    final root = document.rootElement.findElements('dict').single;
    final elements = root.childElements.toList();
    final index = elements.indexWhere((item) =>
        item.name.local == 'key' && item.innerText == 'NSAppTransportSecurity');
    expect(index, greaterThanOrEqualTo(0));
    final policy = elements[index + 1].childElements.toList();
    for (final name in [
      'NSAllowsArbitraryLoads',
      'NSAllowsArbitraryLoadsInWebContent'
    ]) {
      final position = policy.indexWhere(
          (item) => item.name.local == 'key' && item.innerText == name);
      expect(position, greaterThanOrEqualTo(0));
      expect(policy[position + 1].name.local, 'false');
    }
    expect(
        policy.where((item) =>
            item.name.local == 'key' && item.innerText == 'NSExceptionDomains'),
        isEmpty);
  });
}
